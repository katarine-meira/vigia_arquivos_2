import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/share_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/share_viewmodel.dart';
import '../viewer/protected_viewer_screen.dart';
import 'share_screen.dart';

class SharesTab extends StatefulWidget {
  final ValueNotifier<int>? subTabNotifier;

  const SharesTab({super.key, this.subTabNotifier});

  @override
  State<SharesTab> createState() => _SharesTabState();
}

class _SharesTabState extends State<SharesTab> {
  int _tabIndex = 0; // 0 = Recebidos, 1 = Enviados

  @override
  void initState() {
    super.initState();
    widget.subTabNotifier?.addListener(_onSubTabChanged);
  }

  @override
  void dispose() {
    widget.subTabNotifier?.removeListener(_onSubTabChanged);
    super.dispose();
  }

  void _onSubTabChanged() {
    final next = widget.subTabNotifier?.value;
    if (next != null && next != _tabIndex && mounted) {
      setState(() => _tabIndex = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myEmail = context.watch<AuthViewModel>().user?.email ?? '';

    return Consumer<ShareViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              const SizedBox(height: 16),
              // Seletor de visualização (Recebidos / Enviados)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Recebidos (${vm.sharedWithMe.length})',
                          isSelected: _tabIndex == 0,
                          onTap: () => setState(() => _tabIndex = 0),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'Enviados (${vm.myShares.length})',
                          isSelected: _tabIndex == 1,
                          onTap: () => setState(() => _tabIndex = 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Conteúdo da aba selecionada
              Expanded(
                child: _tabIndex == 0
                    ? _ReceivedList(
                        shares: vm.sharedWithMe,
                        currentUserEmail: myEmail,
                      )
                    : _SentList(
                        shares: vm.myShares,
                        onRevoke: (share) => _confirmRevoke(context, share),
                        onEdit: (share) => _openEditDialog(context, share),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShareScreen()),
            ),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            tooltip: 'Novo compartilhamento',
            child: const Icon(Icons.share_rounded),
          ),
        );
      },
    );
  }

  Future<void> _openEditDialog(BuildContext context, ShareModel share) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditShareSheet(share: share),
    );
  }

  Future<void> _confirmRevoke(BuildContext context, ShareModel share) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Revogar acesso'),
            content: Text('Deseja realmente revogar o acesso de "${share.recipientEmail}" ao arquivo "${share.fileName}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  minimumSize: const Size(80, 40),
                ),
                child: const Text('Revogar'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && context.mounted) {
      final success = await context.read<ShareViewModel>().revokeShare(share.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acesso revogado com sucesso.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// Lista de Arquivos Recebidos

class _ReceivedList extends StatelessWidget {
  final List<ShareModel> shares;
  final String currentUserEmail;

  const _ReceivedList({
    required this.shares,
    required this.currentUserEmail,
  });

  void _handleOpenProtected(BuildContext context, ShareModel share) {
    if (share.isRevoked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acesso Revogado: O proprietário cancelou o acesso a este arquivo.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (share.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acesso Expirado: O prazo de validade deste arquivo encerrou.'),
          backgroundColor: Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (share.isViewOnceConsumed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visualização única: Este documento já foi aberto uma vez e não pode mais ser acessado.'),
          backgroundColor: Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!share.canView) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sem permissão de visualização para este documento.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final shareVm = context.read<ShareViewModel>();
    // Marca como visualizado para não mostrar mais o aviso de novos arquivos na Home
    shareVm.markShareAsViewed(share.id);
    if (share.viewOnce) {
      shareVm.markViewOnceConsumed(share.id);
    }

    // Abre visualizador protegido DENTRO DO APP com transição suave sem artefatos
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => ProtectedViewerScreen(
          share: share,
          currentUserEmail: currentUserEmail,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (shares.isEmpty) {
      return const _EmptyState(
        icon: Icons.mark_email_read_outlined,
        title: 'Nenhum arquivo recebido',
        subtitle: 'Arquivos que outros usuários compartilharem com seu e-mail aparecerão aqui.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: shares.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final share = shares[index];
        return _ShareCard(
          share: share,
          subtitle: 'De: ${share.ownerEmail}',
          onTap: () => _handleOpenProtected(context, share),
        );
      },
    );
  }
}

// Lista de Compartilhamentos Enviados (Gerenciamento do Dono)

class _SentList extends StatelessWidget {
  final List<ShareModel> shares;
  final ValueChanged<ShareModel> onRevoke;
  final ValueChanged<ShareModel> onEdit;

  const _SentList({
    required this.shares,
    required this.onRevoke,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (shares.isEmpty) {
      return const _EmptyState(
        icon: Icons.send_outlined,
        title: 'Nenhum compartilhamento ativo',
        subtitle: 'Você ainda não compartilhou documentos com outros usuários.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: shares.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final share = shares[index];
        return _ShareCard(
          share: share,
          subtitle: 'Para: ${share.recipientEmail}',
          onTap: () => onEdit(share),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                tooltip: 'Editar',
                onPressed: () => onEdit(share),
              ),
              if (share.isActive)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(50, 32),
                  ),
                  onPressed: () => onRevoke(share),
                  child: const Text('Revogar', style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Modal de Edição de Compartilhamento (Bottom Sheet)

class _EditShareSheet extends StatefulWidget {
  final ShareModel share;
  const _EditShareSheet({required this.share});

  @override
  State<_EditShareSheet> createState() => _EditShareSheetState();
}

class _EditShareSheetState extends State<_EditShareSheet> {
  late bool _canView;
  late bool _canDownload;
  late bool _canReshare;
  late bool _isRevoked;
  int _extraDays = 0;

  @override
  void initState() {
    super.initState();
    _canView = widget.share.canView;
    _canDownload = widget.share.canDownload;
    _canReshare = widget.share.canReshare;
    _isRevoked = widget.share.isRevoked;
  }

  DateTime? _newExpiration() {
    if (_extraDays == -1) return null; // Sem expiração
    if (_extraDays == 0) return widget.share.expiresAt;
    return DateTime.now().add(Duration(days: _extraDays));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Editar permissões do envio',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Destinatário: ${widget.share.recipientEmail}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // Permissões
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _canView,
            onChanged: (v) => setState(() => _canView = v),
            title: const Text('Visualizar documento', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            activeColor: AppTheme.primary,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _canDownload,
            onChanged: (v) => setState(() => _canDownload = v),
            title: const Text('Permitir download', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            activeColor: AppTheme.primary,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _canReshare,
            onChanged: (v) => setState(() => _canReshare = v),
            title: const Text('Permitir re-compartilhamento', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            activeColor: AppTheme.primary,
          ),

          if (_isRevoked)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: !_isRevoked,
              onChanged: (active) => setState(() => _isRevoked = !active),
              title: const Text('Reativar acesso', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
              activeColor: const Color(0xFF16A34A),
            ),

          const SizedBox(height: 12),
          const Text('Prorrogar validade', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Manter atual'),
                selected: _extraDays == 0,
                onSelected: (_) => setState(() => _extraDays = 0),
              ),
              ChoiceChip(
                label: const Text('+ 7 dias'),
                selected: _extraDays == 7,
                onSelected: (_) => setState(() => _extraDays = 7),
              ),
              ChoiceChip(
                label: const Text('+ 30 dias'),
                selected: _extraDays == 30,
                onSelected: (_) => setState(() => _extraDays = 30),
              ),
              ChoiceChip(
                label: const Text('Sem expiração'),
                selected: _extraDays == -1,
                onSelected: (_) => setState(() => _extraDays = -1),
              ),
            ],
          ),

          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () async {
              final shareVm = context.read<ShareViewModel>();
              final success = await shareVm.updateShare(
                shareId: widget.share.id,
                canView: _canView,
                canDownload: _canDownload,
                canReshare: _canReshare,
                expiresAt: _newExpiration(),
                isRevoked: _isRevoked,
              );
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permissões atualizadas com sucesso!'),
                    backgroundColor: Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Salvar alterações'),
          ),
        ],
      ),
    );
  }
}

// Card de Compartilhamento Reutilizável

class _ShareCard extends StatelessWidget {
  final ShareModel share;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ShareCard({
    required this.share,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  Color _statusColor() {
    if (share.isRevoked) return AppTheme.errorColor;
    if (share.isExpired || share.isViewOnceConsumed) return const Color(0xFFD97706);
    return const Color(0xFF16A34A);
  }

  Color _statusBgColor() {
    if (share.isRevoked) return const Color(0xFFFEE2E2);
    if (share.isExpired || share.isViewOnceConsumed) return const Color(0xFFFEF3C7);
    return const Color(0xFFDCFCE7);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = share.expiresAt != null
        ? 'Validade: ${DateFormat('dd/MM HH:mm').format(share.expiresAt!)}'
        : 'Sem expiração';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    share.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _statusBgColor(),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          share.statusDescription,
                          style: TextStyle(color: _statusColor(), fontSize: 9.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (share.viewOnce && !share.isViewOnceConsumed) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '1x',
                            style: TextStyle(color: AppTheme.primary, fontSize: 9.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dateStr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.border),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
