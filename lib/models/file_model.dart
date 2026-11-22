import 'package:cloud_firestore/cloud_firestore.dart';

class FileModel {
  final String id;
  final String ownerId;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String localPath;
  final DateTime uploadedAt;

  const FileModel({
    required this.id,
    required this.ownerId,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.localPath,
    required this.uploadedAt,
  });

  factory FileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FileModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      fileName: data['fileName'] as String? ?? 'Arquivo sem nome',
      fileSize: (data['fileSize'] as num?)?.toInt() ?? 0,
      mimeType: data['mimeType'] as String? ?? '',
      localPath: data['localPath'] as String? ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'localPath': localPath,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
      };

  /// Retorna a extensão do arquivo em maiúsculas (ex: PDF, DOCX, PNG)
  String get extension {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < fileName.length - 1) {
      return fileName.substring(dotIndex + 1).toUpperCase();
    }
    return 'ARQ';
  }

  /// Formata o tamanho legível em B, KB ou MB
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
