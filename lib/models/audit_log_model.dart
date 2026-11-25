import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AuditLogModel {
  final String id;
  final String fileId;
  final String fileName;
  final String actorId;
  final String actorEmail;
  final String ownerId;
  final String ownerEmail;
  final String action; // UPLOAD, SHARE, VIEW, REVOKE, EDIT_PERMISSIONS, DOWNLOAD
  final String details;
  final DateTime timestamp;

  const AuditLogModel({
    required this.id,
    required this.fileId,
    required this.fileName,
    required this.actorId,
    required this.actorEmail,
    required this.ownerId,
    required this.ownerEmail,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AuditLogModel(
      id: doc.id,
      fileId: data['fileId'] as String? ?? '',
      fileName: data['fileName'] as String? ?? 'Arquivo',
      actorId: data['actorId'] as String? ?? '',
      actorEmail: data['actorEmail'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      ownerEmail: data['ownerEmail'] as String? ?? '',
      action: data['action'] as String? ?? 'EVENT',
      details: data['details'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'fileId': fileId,
        'fileName': fileName,
        'actorId': actorId,
        'actorEmail': actorEmail,
        'ownerId': ownerId,
        'ownerEmail': ownerEmail,
        'action': action,
        'details': details,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  String get actionDescription {
    switch (action) {
      case 'UPLOAD':
        return 'Upload de arquivo';
      case 'SHARE':
        return 'Compartilhamento';
      case 'VIEW':
        return 'Visualização protegida';
      case 'DOWNLOAD':
        return 'Cópia baixada';
      case 'REVOKE':
        return 'Acesso revogado';
      case 'EDIT_PERMISSIONS':
        return 'Permissões alteradas';
      default:
        return 'Ação registrada';
    }
  }

  String get formattedDate => DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
}
