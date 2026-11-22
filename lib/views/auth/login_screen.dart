import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/app_logo.dart';
import 'register_screen.dart';
import 'widgets/auth_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final success = await vm.signIn(_emailCtrl.text, _passCtrl.text);
    if (success && mounted) {
      // Remove toda a pilha de navegação; AuthWrapper exibirá HomeScreen.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 36),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: AppTheme.textDark,
                ),
                const SizedBox(height: 28),
                const AppLogo(),
                const SizedBox(height: 36),
                const Text(
                  'Que bom ter você aqui',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entre para acessar seus arquivos protegidos.',
                  style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 36),
                // Banner de erro
                Consumer<AuthViewModel>(
                  builder: (_, vm, __) {
                    if (vm.error == null) return const SizedBox.shrink();
                    return ErrorBanner(message: vm.error!);
                  },
                ),
                const FieldLabel('E-mail'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => context.read<AuthViewModel>().clearError(),
                  decoration: const InputDecoration(hintText: 'seu@email.com'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                    if (!v.contains('@')) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const FieldLabel('Senha'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  onChanged: (_) => context.read<AuthViewModel>().clearError(),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: VisibilityToggle(
                      obscure: _obscurePass,
                      onToggle: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe a senha' : null,
                ),
                const SizedBox(height: 28),
                Consumer<AuthViewModel>(
                  builder: (_, vm, __) => ElevatedButton(
                    onPressed: vm.isLoading ? null : _submit,
                    child: vm.isLoading
                        ? const ButtonLoader()
                        : const Text('Entrar'),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Ainda não tem conta? ',
                        style: TextStyle(
                            fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text(
                          'Criar conta',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
