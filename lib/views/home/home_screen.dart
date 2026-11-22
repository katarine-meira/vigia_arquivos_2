import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/user_avatar.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _bodies = [
    _HomeTab(),
    _PlaceholderTab(icon: Icons.insert_drive_file_outlined, label: 'Meus Arquivos'),
    _PlaceholderTab(icon: Icons.share_outlined, label: 'Compartilhados'),
    _PlaceholderTab(icon: Icons.timeline_outlined, label: 'Atividades'),
  ];

  @override
  Widget build(BuildContext context) {
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
            children: _bodies,
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

// ---------------------------------------------------------------------------
// Tab: Início
// ---------------------------------------------------------------------------

class _HomeTab extends StatelessWidget {
  const _HomeTab();

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
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        final firstName = vm.user?.firstName ?? 'Usuário';

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
            const SizedBox(height: 24),
            const _ActionCard(),
            const SizedBox(height: 16),
            const _StatsRow(),
            const SizedBox(height: 28),
            const _SectionLabel('ATIVIDADE RECENTE'),
            const SizedBox(height: 12),
            const _EmptyState(
              icon: Icons.history_rounded,
              message: 'Nenhuma atividade ainda.',
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: Placeholder (Meus Arquivos, Compartilhados, Atividades)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Sub-widgets do HomeTab
// ---------------------------------------------------------------------------

class _ActionCard extends StatelessWidget {
  const _ActionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _StatCard(value: '0', label: 'Arquivos', icon: Icons.insert_drive_file_outlined)),
        SizedBox(width: 10),
        Expanded(child: _StatCard(value: '0', label: 'Acessos ativos', icon: Icons.shield_outlined)),
        SizedBox(width: 10),
        Expanded(child: _StatCard(value: '0', label: 'Eventos', icon: Icons.timeline_outlined)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
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
