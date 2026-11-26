import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/audit_log_model.dart';
import '../services/audit_service.dart';

class AuditViewModel extends ChangeNotifier {
  final AuditService _auditService = AuditService();
  StreamSubscription<List<AuditLogModel>>? _subscription;

  List<AuditLogModel> _logs = [];
  bool _isLoading = true;

  List<AuditLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  int get eventCount => _logs.length;

  String? _currentUserId;

  void init({String? userId, String? userEmail}) {
    if (userId != null && _currentUserId == userId && _subscription != null) return;
    _currentUserId = userId;

    _subscription?.cancel();
    _isLoading = _logs.isEmpty;

    _subscription = _auditService.getAuditLogsStream(
      userId: userId,
      userEmail: userEmail,
    ).listen(
      (logs) {
        _logs = logs;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  Future<void> log({
    required String fileId,
    required String fileName,
    required String actorId,
    required String actorEmail,
    required String ownerId,
    required String ownerEmail,
    required String action,
    required String details,
  }) async {
    await _auditService.logEvent(
      fileId: fileId,
      fileName: fileName,
      actorId: actorId,
      actorEmail: actorEmail,
      ownerId: ownerId,
      ownerEmail: ownerEmail,
      action: action,
      details: details,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
