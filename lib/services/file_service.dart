import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_model.dart';

class FileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Limite seguro para sincronização de conteúdo na nuvem via Firestore (Spark gratuito)
  static const int _maxCloudSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const int _chunkSizeChars = 500000; // ~500 KB por documento (< 1 MB limite)

  CollectionReference get _filesCollection => _firestore.collection('files');

  /// Abre o seletor nativo de arquivos do celular/dispositivo
  Future<PlatformFile?> pickFile() async {
    return await FilePicker.pickFile(
      type: FileType.any,
    );
  }

  /// Salva uma cópia no armazenamento local seguro do app e sincroniza o conteúdo em chunks no Firestore
  Future<FileModel> uploadFile({
    required PlatformFile file,
    required String ownerId,
  }) async {
    String savedLocalPath = '';
    Uint8List? fileBytes;

    // Salva o arquivo em diretório seguro do aplicativo
    if (!kIsWeb && file.path != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final userFilesDir = Directory('${appDir.path}/user_files/$ownerId');
      if (!await userFilesDir.exists()) {
        await userFilesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanFileName = file.name.replaceAll(' ', '_');
      final targetFile = File('${userFilesDir.path}/${timestamp}_$cleanFileName');

      await File(file.path!).copy(targetFile.path);
      savedLocalPath = targetFile.path;
      fileBytes = await targetFile.readAsBytes();
    }

    final int calculatedSize = fileBytes?.length ?? file.lengthSync() ?? (await file.length()) ?? 0;

    final fileData = {
      'ownerId': ownerId,
      'fileName': file.name,
      'fileSize': calculatedSize,
      'mimeType': file.extension ?? '',
      'localPath': savedLocalPath,
      'chunkCount': 0,
      'uploadedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _filesCollection.add(fileData);

    // Sincroniza bytes no Firestore (em chunks de 500 KB) para funcionar entre celulares diferentes
    if (fileBytes != null && fileBytes.length <= _maxCloudSizeBytes) {
      final b64 = base64Encode(fileBytes);
      final totalChunks = (b64.length / _chunkSizeChars).ceil();
      final chunksRef = docRef.collection('chunks');

      for (int i = 0; i < totalChunks; i++) {
        final start = i * _chunkSizeChars;
        final end = (start + _chunkSizeChars < b64.length) ? start + _chunkSizeChars : b64.length;
        await chunksRef.doc(i.toString().padLeft(4, '0')).set({
          'index': i,
          'data': b64.substring(start, end),
        });
      }

      await docRef.update({'chunkCount': totalChunks});
    }

    final docSnapshot = await docRef.get();
    return FileModel.fromFirestore(docSnapshot);
  }

  /// Resolve o caminho local do arquivo: usa o local se existir, senão baixa e decodifica do Firestore
  Future<String?> resolveFilePath({
    required String fileId,
    required String fileName,
    required String localPath,
  }) async {
    // 1. Verifica se já existe no caminho original (mesmo dispositivo)
    if (localPath.isNotEmpty) {
      final origFile = File(localPath);
      if (await origFile.exists()) return localPath;
    }

    if (kIsWeb) return null;

    // 2. Verifica cache local de arquivos recebidos de outros dispositivos
    final appDir = await getApplicationDocumentsDirectory();
    final receivedDir = Directory('${appDir.path}/received_files');
    if (!await receivedDir.exists()) {
      await receivedDir.create(recursive: true);
    }
    final cleanName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final cachedFile = File('${receivedDir.path}/${fileId}_$cleanName');
    if (await cachedFile.exists() && await cachedFile.length() > 0) {
      return cachedFile.path;
    }

    // 3. Baixa chunks do Firestore e reconstrói localmente
    try {
      final chunksSnap = await _filesCollection
          .doc(fileId)
          .collection('chunks')
          .orderBy('index')
          .get();

      if (chunksSnap.docs.isEmpty) return null;

      final buffer = StringBuffer();
      for (final doc in chunksSnap.docs) {
        final data = doc.data();
        buffer.write(data['data'] as String? ?? '');
      }

      final bytes = base64Decode(buffer.toString());
      await cachedFile.writeAsBytes(bytes, flush: true);
      return cachedFile.path;
    } catch (e) {
      debugPrint('DEBUG: Erro ao baixar chunks do Firestore: $e');
      return null;
    }
  }

  /// Retorna Stream contínuo dos arquivos do usuário em tempo real a partir do Firestore
  Stream<List<FileModel>> getUserFilesStream(String userId) {
    return _filesCollection
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => FileModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  /// Remove a cópia local do arquivo e o registro correspondente no Firestore (incluindo chunks)
  Future<void> deleteFile(FileModel file) async {
    if (file.localPath.isNotEmpty) {
      try {
        final localFile = File(file.localPath);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      } catch (_) {}
    }

    try {
      final chunks = await _filesCollection.doc(file.id).collection('chunks').get();
      for (final doc in chunks.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}

    await _filesCollection.doc(file.id).delete();
  }
}
