import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Logo do Vigia Arquivos com ícone de documento limpo e direto.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.description_outlined,
            color: AppTheme.primary,
            size: size * 0.65,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VIGIA',
              style: TextStyle(
                fontSize: size * 0.44,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: 1.2,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Arquivos',
              style: TextStyle(
                fontSize: size * 0.32,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
                letterSpacing: 0.3,
                height: 1.05,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
