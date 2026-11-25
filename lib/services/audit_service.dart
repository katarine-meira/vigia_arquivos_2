import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log_model.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _auditCollection => _firestore.collection('audit_logs');

  /// Registra um evento de auditoria no Firestore
  Future<void> logEvent({
    required String fileId,
    required String fileName,
    required String actorId,
    required String actorEmail,
    required String ownerId,
    required String ownerEmail,
    required String action,
    required String details,
  }) async {
    try {
      await _auditCollection.add({
        'fileId': fileId,
        'fileName': fileName,
        'actorId': actorId,
        'actorEmail': actorEmail.toLowerCase().trim(),
        'ownerId': ownerId,
        'ownerEmail': ownerEmail.toLowerCase().trim(),
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Falha silenciosa para não quebrar a navegação principal
    }
  }

  /// Retorna stream dos registros de auditoria filtrados conforme a regra de custódia
  Stream<List<AuditLogModel>> getAuditLogsStream({String? userEmail, String? userId}) {
    final cleanEmail = userEmail?.toLowerCase().trim() ?? '';
    final uid = userId ?? '';

    return _auditCollection
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final all = snapshot.docs.map((doc) => AuditLogModel.fromFirestore(doc)).toList();
      if (uid.isEmpty && cleanEmail.isEmpty) return all;

      return all.where((log) {
        // Se a ação for VIEW ou DOWNLOAD, aparece APENAS para o proprietário do documento
        if (log.action == 'VIEW' || log.action == 'DOWNLOAD') {
          return log.ownerId == uid || (cleanEmail.isNotEmpty && log.ownerEmail == cleanEmail);
        }
        // Para ações de UPLOAD, SHARE, REVOKE, EDIT_PERMISSIONS: aparece para o proprietário/autor
        return log.ownerId == uid ||
            log.actorId == uid ||
            (cleanEmail.isNotEmpty && (log.ownerEmail == cleanEmail || log.actorEmail == cleanEmail));
      }).toList();
    });
  }
}
