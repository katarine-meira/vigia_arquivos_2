import 'package:cloud_firestore/cloud_firestore.dart';

class ShareModel {
  final String id;
  final String fileId;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String localPath;
  final String ownerId;
  final String ownerEmail;
  final String recipientEmail;
  final bool canView;
  final bool canDownload;
  final bool canReshare;
  final bool viewOnce;
  final DateTime? expiresAt;
  final bool isRevoked;
  final bool isViewed;
  final bool hasOpened;
  final DateTime createdAt;

  const ShareModel({
    required this.id,
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.localPath,
    required this.ownerId,
    required this.ownerEmail,
    required this.recipientEmail,
    required this.canView,
    required this.canDownload,
    required this.canReshare,
    this.viewOnce = false,
    this.expiresAt,
    required this.isRevoked,
    this.isViewed = false,
    this.hasOpened = false,
    required this.createdAt,
  });

  factory ShareModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final perms = data['permissions'] as Map<String, dynamic>? ?? {};

    return ShareModel(
      id: doc.id,
      fileId: data['fileId'] as String? ?? '',
      fileName: data['fileName'] as String? ?? 'Arquivo',
      fileSize: (data['fileSize'] as num?)?.toInt() ?? 0,
      mimeType: data['mimeType'] as String? ?? '',
      localPath: data['localPath'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      ownerEmail: data['ownerEmail'] as String? ?? '',
      recipientEmail: data['recipientEmail'] as String? ?? '',
      canView: perms['canView'] as bool? ?? true,
      canDownload: perms['canDownload'] as bool? ?? false,
      canReshare: perms['canReshare'] as bool? ?? false,
      viewOnce: perms['viewOnce'] as bool? ?? false,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      isRevoked: data['isRevoked'] as bool? ?? false,
      isViewed: data['isViewed'] as bool? ?? false,
      hasOpened: data['hasOpened'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'fileId': fileId,
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'localPath': localPath,
        'ownerId': ownerId,
        'ownerEmail': ownerEmail,
        'recipientEmail': recipientEmail,
        'permissions': {
          'canView': canView,
          'canDownload': canDownload,
          'canReshare': canReshare,
          'viewOnce': viewOnce,
        },
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'isRevoked': isRevoked,
        'isViewed': isViewed,
        'hasOpened': hasOpened,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Retorna se o prazo de validade já expirou
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Retorna se a visualização única já foi consumida
  bool get isViewOnceConsumed => viewOnce && hasOpened;

  /// Retorna se o acesso está atualmente válido e ativo
  bool get isActive => !isRevoked && !isExpired && !isViewOnceConsumed;

  /// Retorna o status do compartilhamento
  String get statusDescription {
    if (isRevoked) return 'Revogado';
    if (isExpired) return 'Expirado';
    if (isViewOnceConsumed) return 'Visualizado (1x)';
    return 'Ativo';
  }

  String get extension {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < fileName.length - 1) {
      return fileName.substring(dotIndex + 1).toUpperCase();
    }
    return 'ARQ';
  }
}
