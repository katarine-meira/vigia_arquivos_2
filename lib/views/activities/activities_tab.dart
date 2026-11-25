import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/audit_log_model.dart';
import '../../viewmodels/audit_viewmodel.dart';

class ActivitiesTab extends StatefulWidget {
  const ActivitiesTab({super.key});

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<ActivitiesTab> {
  int _viewMode = 0; // 0 = Por documento enviado, 1 = Linha do tempo geral

  Color _actionColor(String action) {
    switch (action) {
      case 'UPLOAD':
        return AppTheme.primary;
      case 'SHARE':
        return const Color(0xFF2563EB);
      case 'VIEW':
        return const Color(0xFF16A34A);
      case 'DOWNLOAD':
        return const Color(0xFF0284C7);
      case 'REVOKE':
        return AppTheme.errorColor;
      case 'EDIT_PERMISSIONS':
        return const Color(0xFFD97706);
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'UPLOAD':
        return Icons.cloud_upload_outlined;
      case 'SHARE':
        return Icons.share_rounded;
      case 'VIEW':
        return Icons.visibility_outlined;
      case 'DOWNLOAD':
        return Icons.download_done_rounded;
      case 'REVOKE':
        return Icons.block_outlined;
      case 'EDIT_PERMISSIONS':
        return Icons.tune_rounded;
      default:
        return Icons.timeline_outlined;
    }
  }

  String _getExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < fileName.length - 1) {
      return fileName.substring(dotIndex + 1).toUpperCase();
    }
    return 'ARQ';
  }

  @override
  Widget build(BuildContext context) {
    final auditVm = context.watch<AuditViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: auditVm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : auditVm.logs.isEmpty
              ? const _EmptyActivitiesState()
              : Column(
                  children: [
                    const SizedBox(height: 16),
                    // Seletor de visualização
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
                              child: _ViewModeButton(
                                label: 'Por documento',
                                isSelected: _viewMode == 0,
                                onTap: () => setState(() => _viewMode = 0),
                              ),
                            ),
                            Expanded(
                              child: _ViewModeButton(
                                label: 'Linha do tempo geral',
                                isSelected: _viewMode == 1,
                                onTap: () => setState(() => _viewMode = 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _viewMode == 0
                          ? _buildGroupedByDocumentView(auditVm.logs)
                          : _buildFlatTimelineView(auditVm.logs),
                    ),
                  ],
                ),
    );
  }

  /// Visualização 1: Atividades agrupadas por documento enviado
  Widget _buildGroupedByDocumentView(List<AuditLogModel> logs) {
    // Agrupa todos os logs por nome do arquivo
    final Map<String, List<AuditLogModel>> grouped = {};
    for (final log in logs) {
      final key = log.fileName.trim().isNotEmpty ? log.fileName.trim() : 'Documento';
      grouped.putIfAbsent(key, () => []).add(log);
    }

    final entries = grouped.entries.toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final fileName = entry.key;
        final docLogs = entry.value;
        final ext = _getExtension(fileName);

        final viewCount = docLogs.where((l) => l.action == 'VIEW').length;
        final downloadCount = docLogs.where((l) => l.action == 'DOWNLOAD').length;
        final isRevoked = docLogs.any((l) => l.action == 'REVOKE');

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: index == 0,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  ext,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MiniBadge(
                      label: viewCount == 1 ? '1 visualização' : '$viewCount visualizações',
                      color: const Color(0xFF16A34A),
                      bgColor: const Color(0xFFDCFCE7),
                      icon: Icons.visibility_outlined,
                    ),
                    if (downloadCount > 0)
                      _MiniBadge(
                        label: downloadCount == 1 ? '1 download' : '$downloadCount downloads',
                        color: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFE0F2FE),
                        icon: Icons.download_done_rounded,
                      ),
                    if (isRevoked)
                      const _MiniBadge(
                        label: 'Acesso revogado',
                        color: AppTheme.errorColor,
                        bgColor: Color(0xFFFEE2E2),
                        icon: Icons.block_outlined,
                      ),
                  ],
                ),
              ),
              children: [
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 12),
                ...docLogs.map((log) {
                  final color = _actionColor(log.action);
                  final icon = _actionIcon(log.action);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 15),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    log.actionDescription,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                  Text(
                                    log.formattedDate,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                log.details,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textDark,
                                  height: 1.3,
                                ),
                              ),
                              if (log.actorEmail.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Por: ${log.actorEmail}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Visualização 2: Linha do tempo contínua geral
  Widget _buildFlatTimelineView(List<AuditLogModel> logs) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final log = logs[index];
        final color = _actionColor(log.action);
        final icon = _actionIcon(log.action);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          log.actionDescription,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        Text(
                          log.formattedDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      log.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      log.details,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _MiniBadge({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EmptyActivitiesState extends StatelessWidget {
  const _EmptyActivitiesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_toggle_off_rounded, size: 32, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma atividade registrada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'As atividades de visualização, download e compartilhamento dos seus documentos aparecerão aqui organizadas por arquivo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
