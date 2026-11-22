import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_model.dart';

class FileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _filesCollection => _firestore.collection('files');

  /// Abre o seletor nativo de arquivos do celular/dispositivo
  Future<PlatformFile?> pickFile() async {
    return await FilePicker.pickFile(
      type: FileType.any,
    );
  }

  /// Salva uma cópia no armazenamento local seguro do app e registra metadados no Firestore
  Future<FileModel> uploadFile({
    required PlatformFile file,
    required String ownerId,
  }) async {
    String savedLocalPath = '';

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
    }

    final int calculatedSize = file.lengthSync() ?? (await file.length()) ?? 0;

    final fileData = {
      'ownerId': ownerId,
      'fileName': file.name,
      'fileSize': calculatedSize,
      'mimeType': file.extension ?? '',
      'localPath': savedLocalPath,
      'uploadedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _filesCollection.add(fileData);
    final docSnapshot = await docRef.get();
    return FileModel.fromFirestore(docSnapshot);
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

  /// Remove a cópia local do arquivo e o registro correspondente no Firestore
  Future<void> deleteFile(FileModel file) async {
    if (file.localPath.isNotEmpty) {
      try {
        final localFile = File(file.localPath);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      } catch (_) {
        // Ignora caso o arquivo já tenha sido removido do disco
      }
    }
    await _filesCollection.doc(file.id).delete();
  }
}
