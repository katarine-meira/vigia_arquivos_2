import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _features = [
    _Feature(
      icon: Icons.shield_outlined,
      title: 'Controle de acesso',
      description: 'Escolha exatamente quem pode visualizar ou baixar.',
    ),
    _Feature(
      icon: Icons.schedule_outlined,
      title: 'Validade configurável',
      description: 'Defina por quanto tempo cada acesso fica disponível.',
    ),
    _Feature(
      icon: Icons.timeline_outlined,
      title: 'Histórico transparente',
      description: 'Consulte os eventos efetivamente registrados.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppLogo(),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('Pular'),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                'CONHEÇA O VIGIA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Compartilhe com\nconfiança',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Três camadas simples para manter você no controle.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ..._features.map((f) => _FeatureCard(feature: f)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continuar'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Modelos e sub-widgets privados
// ---------------------------------------------------------------------------

class _Feature {
  final IconData icon;
  final String title;
  final String description;
  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
