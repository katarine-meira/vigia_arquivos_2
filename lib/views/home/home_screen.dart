import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/share_model.dart';
import '../../viewmodels/audit_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/file_viewmodel.dart';
import '../../viewmodels/share_viewmodel.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/file_card.dart';
import '../../widgets/user_avatar.dart';
import '../activities/activities_tab.dart';
import '../files/my_files_tab.dart';
import '../settings/settings_screen.dart';
import '../share/share_screen.dart';
import '../share/shares_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _initializedUserId;
  bool _dismissedReceivedBanner = false;
  final ValueNotifier<int> _sharesSubTabNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _sharesSubTabNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthViewModel>().user;
    if (user != null && _initializedUserId != user.uid) {
      _initializedUserId = user.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<FileViewModel>().init(user.uid);
        context.read<ShareViewModel>().init(userId: user.uid, userEmail: user.email);
        context.read<AuditViewModel>().init(userId: user.uid, userEmail: user.email);
      });
    }
  }

  void _onNavigateToTab(int index, {int? sharesSubTab}) {
    if (sharesSubTab != null) {
      _sharesSubTabNotifier.value = sharesSubTab;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bodies = [
      _HomeTab(
        isBannerDismissed: _dismissedReceivedBanner,
        onDismissBanner: () => setState(() => _dismissedReceivedBanner = true),
        onNavigateToTab: _onNavigateToTab,
      ),
      const MyFilesTab(),
      SharesTab(subTabNotifier: _sharesSubTabNotifier),
      const ActivitiesTab(),
    ];

    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            toolbarHeight: 74,
            backgroundColor: AppTheme.surface,
            automaticallyImplyLeading: false,
            titleSpacing: 20,
            title: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: AppLogo(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20, top: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  child: UserAvatar(initials: vm.user?.initials ?? '?'),
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: bodies,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.surface,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textSecondary,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            elevation: 1,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Início',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.insert_drive_file_outlined),
                activeIcon: Icon(Icons.insert_drive_file_rounded),
                label: 'Meus arquivos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.share_outlined),
                activeIcon: Icon(Icons.share_rounded),
                label: 'Compartilhados',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.timeline_outlined),
                activeIcon: Icon(Icons.timeline_rounded),
                label: 'Atividades',
              ),
            ],
          ),
        );
      },
    );
  }
}

// Tab: Início
class _HomeTab extends StatelessWidget {
  final bool isBannerDismissed;
  final VoidCallback onDismissBanner;
  final void Function(int index, {int? sharesSubTab}) onNavigateToTab;

  const _HomeTab({
    required this.isBannerDismissed,
    required this.onDismissBanner,
    required this.onNavigateToTab,
  });

  static String _formattedDate() {
    final now = DateTime.now();
    const weekdays = [
      'SEGUNDA-FEIRA', 'TERÇA-FEIRA', 'QUARTA-FEIRA',
      'QUINTA-FEIRA', 'SEXTA-FEIRA', 'SÁBADO', 'DOMINGO'
    ];
    const months = [
      'JANEIRO', 'FEVEREIRO', 'MARÇO', 'ABRIL', 'MAIO', 'JUNHO',
      'JULHO', 'AGOSTO', 'SETEMBRO', 'OUTUBRO', 'NOVEMBRO', 'DEZEMBRO'
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} DE ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final fileVm = context.watch<FileViewModel>();
    final shareVm = context.watch<ShareViewModel>();
    final auditVm = context.watch<AuditViewModel>();
    final firstName = authVm.user?.firstName ?? 'Usuário';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 28),
        Text(
          _formattedDate(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Olá, $firstName',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Seus documentos estão sob controle.',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),

        // Aviso em destaque que só aparece se houver documentos não visualizados
        if (shareVm.unviewedReceivedCount > 0 && !isBannerDismissed) ...[
          const SizedBox(height: 20),
          _ReceivedNotificationBanner(
            count: shareVm.unviewedReceivedCount,
            onTap: () {
              onDismissBanner();
              for (final s in shareVm.sharedWithMe) {
                if (!s.isViewed) shareVm.markShareAsViewed(s.id);
              }
              onNavigateToTab(2, sharesSubTab: 0);
            },
          ),
        ],

        const SizedBox(height: 24),
        _ActionCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShareScreen()),
          ),
        ),
        const SizedBox(height: 16),
        _StatsRow(
          fileCount: fileVm.fileCount,
          activeShares: shareVm.activeSharesCount,
          eventCount: auditVm.eventCount,
          onFilesTap: () => onNavigateToTab(1),
          onSharesTap: () => onNavigateToTab(2, sharesSubTab: 1),
          onEventsTap: () => onNavigateToTab(3),
        ),

        // Seção: Expira em breve (destaque de atenção)
        if (shareVm.expiringSoonShares.isNotEmpty) ...[
          const SizedBox(height: 28),
          const _SectionLabel('ATENÇÃO'),
          const SizedBox(height: 12),
          _ExpiringSoonCard(
            share: shareVm.expiringSoonShares.first,
            onTap: () => onNavigateToTab(2, sharesSubTab: 1),
          ),
        ],

        const SizedBox(height: 28),
        const _SectionLabel('ATIVIDADE RECENTE'),
        const SizedBox(height: 12),
        if (fileVm.files.isEmpty)
          const _EmptyState(
            icon: Icons.history_rounded,
            message: 'Nenhum arquivo enviado ainda.',
          )
        else
          ...fileVm.files.take(3).map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FileCard(
                    file: f,
                    onShare: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ShareScreen(initialFile: f)),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// Banner de Notificação de Arquivos Recebidos
class _ReceivedNotificationBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ReceivedNotificationBanner({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mark_email_unread_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 1 ? 'Novo arquivo recebido!' : '$count novos arquivos recebidos!',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Toque para visualizar com segurança',
                    style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

// Card "Expira em breve"
class _ExpiringSoonCard extends StatelessWidget {
  final ShareModel share;
  final VoidCallback? onTap;
  const _ExpiringSoonCard({required this.share, this.onTap});

  @override
  Widget build(BuildContext context) {
    final expStr = share.expiresAt != null
        ? DateFormat('dd/MM, HH:mm').format(share.expiresAt!)
        : 'Em breve';

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              share.extension,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF78350F)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 13, color: Color(0xFFB45309)),
                    const SizedBox(width: 4),
                    Text(
                      'Expira: $expStr',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFB45309), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFB45309)),
        ],
      ),
    ),
    );
  }
}

// Tab: Atividades
class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppTheme.border),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Em desenvolvimento',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ActionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compartilhar arquivo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Defina acesso, permissões e validade',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int fileCount;
  final int activeShares;
  final int eventCount;
  final VoidCallback onFilesTap;
  final VoidCallback onSharesTap;
  final VoidCallback onEventsTap;

  const _StatsRow({
    required this.fileCount,
    required this.activeShares,
    required this.eventCount,
    required this.onFilesTap,
    required this.onSharesTap,
    required this.onEventsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '$fileCount',
            label: 'Arquivos',
            icon: Icons.insert_drive_file_outlined,
            onTap: onFilesTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '$activeShares',
            label: 'Acessos ativos',
            icon: Icons.shield_outlined,
            onTap: onSharesTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '$eventCount',
            label: 'Eventos',
            icon: Icons.timeline_outlined,
            onTap: onEventsTap,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 1.5,
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppTheme.border),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
