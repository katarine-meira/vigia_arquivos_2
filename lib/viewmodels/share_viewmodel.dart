import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/file_model.dart';
import '../models/share_model.dart';
import '../services/audit_service.dart';
import '../services/auth_service.dart';
import '../services/share_service.dart';

class ShareViewModel extends ChangeNotifier {
  final ShareService _shareService;
  final AuthService _authService;
  final AuditService _auditService = AuditService();
  StreamSubscription<List<ShareModel>>? _mySharesSub;
  StreamSubscription<List<ShareModel>>? _sharedWithMeSub;

  ShareViewModel(this._shareService, this._authService);

  List<ShareModel> _myShares = [];
  List<ShareModel> _sharedWithMe = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<ShareModel> get myShares => _myShares;
  List<ShareModel> get sharedWithMe => _sharedWithMe;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  /// Quantidade de acessos que estão atualmente ativos e válidos
  int get activeSharesCount => _myShares.where((s) => s.isActive).length;

  /// Quantidade de arquivos compartilhados comigo que ainda não foram visualizados
  int get unviewedReceivedCount =>
      _sharedWithMe.where((s) => !s.isViewed && s.isActive).length;

  /// Marca compartilhamento como visualizado
  Future<void> markShareAsViewed(String shareId) async {
    await _shareService.markShareAsViewed(shareId);
  }

  /// Compartilhamentos que expiram nas próximas 48 horas
  List<ShareModel> get expiringSoonShares => _myShares.where((s) {
        if (!s.isActive || s.expiresAt == null) return false;
        final diff = s.expiresAt!.difference(DateTime.now());
        return diff.isNegative == false && diff.inHours <= 48;
      }).toList();

  /// Inicializa a escuta dos dois fluxos em tempo real
  void init({required String userId, required String userEmail}) {
    if (userId.isEmpty) return;

    _mySharesSub?.cancel();
    _sharedWithMeSub?.cancel();

    _isLoading = true;
    _error = null;
    notifyListeners();

    _mySharesSub = _shareService.getMySharesStream(userId).listen(
      (list) {
        _myShares = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        debugPrint('DEBUG: Erro em mySharesStream: $err');
        _isLoading = false;
        notifyListeners();
      },
    );

    _sharedWithMeSub = _shareService.getSharesWithMeStream(userEmail).listen(
      (list) {
        _sharedWithMe = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        debugPrint('DEBUG: Erro em sharedWithMeStream: $err');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Cria compartilhamento para múltiplos destinatários, validando se existem no sistema
  Future<bool> createShares({
    required FileModel file,
    required String ownerId,
    required String ownerEmail,
    required List<String> recipientEmails,
    required bool canView,
    required bool canDownload,
    required bool canReshare,
    DateTime? expiresAt,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Validação de existência prévia no sistema
      final missing = await _authService.findMissingEmails(recipientEmails);
      if (missing.isNotEmpty) {
        _isSaving = false;
        _error = 'O(s) seguinte(s) e-mail(s) não estão cadastrados no sistema:\n${missing.join(', ')}';
        notifyListeners();
        return false;
      }

      // 2. Criação dos compartilhamentos
      final shares = await _shareService.createShares(
        file: file,
        ownerId: ownerId,
        ownerEmail: ownerEmail,
        recipientEmails: recipientEmails,
        canView: canView,
        canDownload: canDownload,
        canReshare: canReshare,
        expiresAt: expiresAt,
      );

      // 3. Auditoria e-ARQ Brasil / LGPD
      for (final s in shares) {
        _auditService.logEvent(
          fileId: file.id,
          fileName: file.fileName,
          actorId: ownerId,
          actorEmail: ownerEmail,
          ownerId: ownerId,
          ownerEmail: ownerEmail,
          action: 'SHARE',
          details: 'Compartilhado com ${s.recipientEmail} (validade: ${s.expiresAt != null ? "definida" : "sem prazo"})',
        );
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('DEBUG: Erro ao criar compartilhamento: $e');
      _isSaving = false;
      _error = 'Não foi possível compartilhar o arquivo.';
      notifyListeners();
      return false;
    }
  }

  /// Atualiza permissões e prazo de um compartilhamento existente
  Future<bool> updateShare({
    required String shareId,
    required bool canView,
    required bool canDownload,
    required bool canReshare,
    DateTime? expiresAt,
    bool? isRevoked,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _shareService.updateShare(
        shareId: shareId,
        canView: canView,
        canDownload: canDownload,
        canReshare: canReshare,
        expiresAt: expiresAt,
        isRevoked: isRevoked,
      );

      final share = _myShares.firstWhere((s) => s.id == shareId, orElse: () => _sharedWithMe.firstWhere((s) => s.id == shareId));
      _auditService.logEvent(
        fileId: share.fileId,
        fileName: share.fileName,
        actorId: share.ownerId,
        actorEmail: share.ownerEmail,
        ownerId: share.ownerId,
        ownerEmail: share.ownerEmail,
        action: 'EDIT_PERMISSIONS',
        details: 'Permissões atualizadas para ${share.recipientEmail}',
      );

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('DEBUG: Erro ao atualizar compartilhamento: $e');
      _isSaving = false;
      _error = 'Não foi possível atualizar o compartilhamento.';
      notifyListeners();
      return false;
    }
  }

  /// Revoga o acesso a qualquer momento
  Future<bool> revokeShare(String shareId) async {
    try {
      await _shareService.revokeShare(shareId);
      final share = _myShares.firstWhere((s) => s.id == shareId);
      _auditService.logEvent(
        fileId: share.fileId,
        fileName: share.fileName,
        actorId: share.ownerId,
        actorEmail: share.ownerEmail,
        ownerId: share.ownerId,
        ownerEmail: share.ownerEmail,
        action: 'REVOKE',
        details: 'Acesso revogado do destinatário ${share.recipientEmail}',
      );
      return true;
    } catch (e) {
      debugPrint('DEBUG: Erro ao revogar compartilhamento: $e');
      _error = 'Não foi possível revogar o acesso.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mySharesSub?.cancel();
    _sharedWithMeSub?.cancel();
    super.dispose();
  }
}
