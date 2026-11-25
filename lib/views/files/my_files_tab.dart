import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/file_viewmodel.dart';
import '../../widgets/file_card.dart';
import '../share/share_screen.dart';
import '../upload/upload_screen.dart';

class MyFilesTab extends StatelessWidget {
  const MyFilesTab({super.key});

  Future<void> _confirmDelete(BuildContext context, dynamic file) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Excluir arquivo'),
            content: Text('Deseja realmente excluir "${file.fileName}"? Esta ação não pode ser desfeita.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  minimumSize: const Size(80, 40),
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && context.mounted) {
      final success = await context.read<FileViewModel>().deleteFile(file);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arquivo excluído com sucesso.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FileViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.files.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 36,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Nenhum arquivo enviado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Envie seus documentos para mantê-los protegidos e prontos para compartilhamento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UploadScreen()),
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Enviar arquivo'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(180, 48),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: vm.files.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final file = vm.files[index];
              return FileCard(
                file: file,
                onShare: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ShareScreen(initialFile: file)),
                ),
                onDelete: () => _confirmDelete(context, file),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadScreen()),
            ),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
