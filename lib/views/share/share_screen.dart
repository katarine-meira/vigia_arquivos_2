import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/file_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/file_viewmodel.dart';
import '../../viewmodels/share_viewmodel.dart';
import '../auth/widgets/auth_components.dart';

class ShareScreen extends StatefulWidget {
  final FileModel? initialFile;

  const ShareScreen({super.key, this.initialFile});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _emailCtrl = TextEditingController();
  final List<String> _recipients = [];

  FileModel? _selectedFile;
  PlatformFile? _pickedLocalFile;
  bool _canDownload = false;
  bool _canReshare = false;
  bool _viewOnce = false;
  int _selectedExpirationDays = 7; // 0 = sem expiração, 1 = 24h, 7 = 7 dias, 30 = 30 dias

  @override
  void initState() {
    super.initState();
    _selectedFile = widget.initialFile;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ShareViewModel>().clearError();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  DateTime? _calculateExpirationDate() {
    if (_viewOnce || _selectedExpirationDays == 0) return null;
    return DateTime.now().add(Duration(days: _selectedExpirationDays));
  }

  void _addEmail() {
    final rawText = _emailCtrl.text.trim();
    if (rawText.isEmpty) return;

    final myEmail = context.read<AuthViewModel>().user?.email.toLowerCase() ?? '';

    // Permite adicionar múltiplos separados por vírgula, ponto-e-vírgula ou espaço
    final emails = rawText.split(RegExp(r'[,;\s]+')).where((e) => e.isNotEmpty).toList();

    for (final email in emails) {
      final clean = email.toLowerCase().trim();
      if (!clean.contains('@') || !clean.contains('.')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('E-mail "$clean" possui formato inválido.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (clean == myEmail) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você não pode compartilhar com seu próprio e-mail.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (!_recipients.contains(clean)) {
        _recipients.add(clean);
      }
    }

    _emailCtrl.clear();
    setState(() {});
  }

  Future<void> _submit() async {
    // Se o usuário digitou no campo mas esqueceu de clicar no "+", adiciona automaticamente
    if (_emailCtrl.text.trim().isNotEmpty) {
      _addEmail();
    }

    if (_selectedFile == null && _pickedLocalFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um arquivo para compartilhar.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um e-mail de destinatário.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authVm = context.read<AuthViewModel>();
    final fileVm = context.read<FileViewModel>();
    final shareVm = context.read<ShareViewModel>();
    final user = authVm.user;
    if (user == null) return;

    if (_selectedFile == null && _pickedLocalFile != null) {
      final uploaded = await fileVm.uploadPlatformFile(
        _pickedLocalFile!,
        user.uid,
        userEmail: user.email,
      );
      if (uploaded == null) {
        if (mounted && fileVm.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(fileVm.error!),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      _selectedFile = uploaded;
      _pickedLocalFile = null;
    }

    final success = await shareVm.createShares(
      file: _selectedFile!,
      ownerId: user.uid,
      ownerEmail: user.email,
      recipientEmails: _recipients,
      canView: true,
      canDownload: _viewOnce ? false : _canDownload,
      canReshare: _viewOnce ? false : _canReshare,
      viewOnce: _viewOnce,
      expiresAt: _calculateExpirationDate(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arquivo compartilhado com ${_recipients.length} destinatário(s)!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileVm = context.watch<FileViewModel>();
    final shareVm = context.watch<ShareViewModel>();

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
        title: const Text('Compartilhar arquivo'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Definir acesso seguro',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Escolha o documento, os destinatários cadastrados e as permissões de acesso com validade.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 28),

              if (shareVm.error != null)
                ErrorBanner(message: shareVm.error!),

              // 1. Seleção do arquivo
              const FieldLabel('Arquivo selecionado'),
              const SizedBox(height: 8),
              if (_selectedFile != null)
                _FileSummaryCard(
                  fileName: _selectedFile!.fileName,
                  formattedSize: _selectedFile!.formattedSize,
                  extension: _selectedFile!.extension,
                  onChange: () => setState(() => _selectedFile = null),
                )
              else if (_pickedLocalFile != null)
                _FileSummaryCard(
                  fileName: _pickedLocalFile!.name,
                  formattedSize: _formatBytes(_pickedLocalFile!.lengthSync() ?? 0),
                  extension: _extractExtension(_pickedLocalFile!.name),
                  onChange: () => setState(() => _pickedLocalFile = null),
                )
              else ...[
                if (fileVm.files.isNotEmpty) ...[
                  _FileDropdownPicker(
                    files: fileVm.files,
                    onSelected: (file) => setState(() => _selectedFile = file),
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await fileVm.pickLocalFile();
                    if (picked != null && mounted) {
                      setState(() => _pickedLocalFile = picked);
                    }
                  },
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: const Text('Selecionar novo arquivo do dispositivo'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppTheme.primary),
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 2. Destinatários múltiplos
              const FieldLabel('Destinatário(s) cadastrado(s)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addEmail(),
                      decoration: const InputDecoration(
                        hintText: 'Digite o e-mail cadastrado',
                        prefixIcon: Icon(Icons.person_search_outlined, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _addEmail,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Adicionar destinatário',
                  ),
                ],
              ),

              // Lista de chips dos e-mails adicionados
              if (_recipients.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recipients.map((email) {
                    return Chip(
                      label: Text(email, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _recipients.remove(email)),
                      backgroundColor: AppTheme.primaryLight,
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 28),

              // 3. Permissões de Acesso
              const FieldLabel('Permissões de acesso'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _viewOnce,
                      onChanged: (val) => setState(() {
                        _viewOnce = val;
                        if (val) {
                          _canDownload = false;
                          _canReshare = false;
                        }
                      }),
                      title: const Text('Visualização única', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Permite abrir o documento apenas uma vez', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      activeColor: AppTheme.primary,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: _canDownload,
                      onChanged: _viewOnce ? null : (val) => setState(() => _canDownload = val),
                      title: const Text('Baixar cópia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Permite exportar ou salvar no dispositivo', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      activeColor: AppTheme.primary,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: _canReshare,
                      onChanged: _viewOnce ? null : (val) => setState(() => _canReshare = val),
                      title: const Text('Re-compartilhar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Permite enviar o documento a terceiros', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      activeColor: AppTheme.primary,
                    ),
                  ],
                ),
              ),

              // 4. Prazo de validade / Expiração (não exibido em visualização única)
              if (!_viewOnce) ...[
                const SizedBox(height: 28),
                const FieldLabel('Prazo de validade'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ExpirationChip(
                      label: '24 horas',
                      days: 1,
                      isSelected: _selectedExpirationDays == 1,
                      onTap: () => setState(() => _selectedExpirationDays = 1),
                    ),
                    _ExpirationChip(
                      label: '7 dias',
                      days: 7,
                      isSelected: _selectedExpirationDays == 7,
                      onTap: () => setState(() => _selectedExpirationDays = 7),
                    ),
                    _ExpirationChip(
                      label: '30 dias',
                      days: 30,
                      isSelected: _selectedExpirationDays == 30,
                      onTap: () => setState(() => _selectedExpirationDays = 30),
                    ),
                    _ExpirationChip(
                      label: 'Sem prazo',
                      days: 0,
                      isSelected: _selectedExpirationDays == 0,
                      onTap: () => setState(() => _selectedExpirationDays = 0),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 36),

              // Botão de confirmação
              ElevatedButton(
                onPressed: (shareVm.isSaving || fileVm.isUploading) ? null : _submit,
                child: (shareVm.isSaving || fileVm.isUploading)
                    ? const ButtonLoader()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(_recipients.length > 1
                              ? 'Compartilhar com ${_recipients.length} pessoas'
                              : 'Confirmar compartilhamento'),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _extractExtension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot != -1 && dot < name.length - 1) {
      return name.substring(dot + 1).toUpperCase();
    }
    return 'ARQ';
  }
}

class _FileSummaryCard extends StatelessWidget {
  final String fileName;
  final String formattedSize;
  final String extension;
  final VoidCallback onChange;

  const _FileSummaryCard({
    required this.fileName,
    required this.formattedSize,
    required this.extension,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
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
              extension,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(formattedSize, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text('Trocar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _FileDropdownPicker extends StatelessWidget {
  final List<FileModel> files;
  final ValueChanged<FileModel> onSelected;

  const _FileDropdownPicker({required this.files, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Text(
          'Você ainda não possui arquivos para compartilhar. Envie um arquivo primeiro.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FileModel>(
          isExpanded: true,
          hint: const Text('Selecione um arquivo', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          items: files.map((f) {
            return DropdownMenuItem<FileModel>(
              value: f,
              child: Text(f.fileName, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onSelected(val);
          },
        ),
      ),
    );
  }
}

class _ExpirationChip extends StatelessWidget {
  final String label;
  final int days;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExpirationChip({
    required this.label,
    required this.days,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppTheme.primary : AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}
