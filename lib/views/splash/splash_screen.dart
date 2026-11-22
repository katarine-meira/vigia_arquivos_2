import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const AppLogo(),
              const Spacer(),
              const _DocIllustration(),
              const Spacer(),
              const Text(
                'CONTROLE EM SUAS MÃOS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Seus arquivos.\nSeu controle.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Compartilhe documentos, gerencie permissões e acompanhe os acessos registrados.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Começar'),
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

class _DocIllustration extends StatelessWidget {
  const _DocIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF4FF),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 118,
              height: 148,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PDF',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        height: 7,
                        width: 72.0 - (i * 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 12,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.verified_user, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
