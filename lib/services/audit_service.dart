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
    }
  }

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
        if (log.action == 'VIEW' || log.action == 'DOWNLOAD') {
          return log.ownerId == uid || (cleanEmail.isNotEmpty && log.ownerEmail == cleanEmail);
        }
        return log.ownerId == uid ||
            log.actorId == uid ||
            (cleanEmail.isNotEmpty && (log.ownerEmail == cleanEmail || log.actorEmail == cleanEmail));
      }).toList();
    });
  }
}
