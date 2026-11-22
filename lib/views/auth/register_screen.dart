import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'widgets/auth_components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aceite os termos para continuar.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final vm = context.read<AuthViewModel>();
    final success = await vm.signUp(
      _nameCtrl.text,
      _emailCtrl.text,
      _passCtrl.text,
    );
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: AppTheme.surface,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Criar conta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Preencha os dados para começar.',
                  style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                Consumer<AuthViewModel>(
                  builder: (_, vm, __) {
                    if (vm.error == null) return const SizedBox.shrink();
                    return ErrorBanner(message: vm.error!);
                  },
                ),
                const FieldLabel('Nome completo'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'Ex.: Ana Martins'),
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Nome inválido' : null,
                ),
                const SizedBox(height: 20),
                const FieldLabel('E-mail'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => context.read<AuthViewModel>().clearError(),
                  decoration: const InputDecoration(hintText: 'voce@exemplo.com'),
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
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Mínimo de 6 caracteres',
                    suffixIcon: VisibilityToggle(
                      obscure: _obscurePass,
                      onToggle: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo de 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 20),
                const FieldLabel('Confirmar senha'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Digite novamente',
                    suffixIcon: VisibilityToggle(
                      obscure: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) =>
                      v != _passCtrl.text ? 'As senhas não coincidem' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (v) =>
                          setState(() => _termsAccepted = v ?? false),
                      activeColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                          children: [
                            TextSpan(text: 'Li e concordo com os '),
                            TextSpan(
                              text: 'Termos de Uso',
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: ' e o '),
                            TextSpan(
                              text: 'Aviso de Privacidade',
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Consumer<AuthViewModel>(
                  builder: (_, vm, __) => ElevatedButton(
                    onPressed: vm.isLoading ? null : _submit,
                    child: vm.isLoading
                        ? const ButtonLoader()
                        : const Text('Criar conta'),
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
