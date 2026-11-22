import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Rótulo padrão para campos de formulário de autenticação.
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      );
}

/// Banner de feedback visual para exibição de erros retornados pela autenticação.
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão de alternância para mostrar/ocultar senha no input.
class VisibilityToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onToggle;

  const VisibilityToggle({
    super.key,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppTheme.textSecondary,
        size: 20,
      ),
      onPressed: onToggle,
    );
  }
}

/// Indicador de carregamento compacto para botões.
class ButtonLoader extends StatelessWidget {
  const ButtonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white,
      ),
    );
  }
}
