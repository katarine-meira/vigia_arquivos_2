import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../core/theme/app_theme.dart';
import '../models/file_model.dart';

class FileCard extends StatelessWidget {
  final FileModel file;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  const FileCard({
    super.key,
    required this.file,
    this.onDelete,
    this.onShare,
  });

  Color _badgeBackgroundColor(String ext) {
    return switch (ext) {
      'PDF' => const Color(0xFFFEE2E2),
      'DOC' || 'DOCX' => const Color(0xFFEFF6FF),
      'PNG' || 'JPG' || 'JPEG' => const Color(0xFFDCFCE7),
      _ => const Color(0xFFF1F5F9),
    };
  }

  Color _badgeTextColor(String ext) {
    return switch (ext) {
      'PDF' => const Color(0xFFDC2626),
      'DOC' || 'DOCX' => AppTheme.primary,
      'PNG' || 'JPG' || 'JPEG' => const Color(0xFF16A34A),
      _ => AppTheme.textSecondary,
    };
  }

  Future<void> _openFile(BuildContext context) async {
    if (file.localPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caminho do arquivo não encontrado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final localFile = File(file.localPath);
    if (!await localFile.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O arquivo não foi encontrado no dispositivo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final result = await OpenFilex.open(file.localPath);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível abrir o arquivo: ${result.message}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(file.uploadedAt);
    final ext = file.extension;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Badge do tipo de arquivo
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _badgeBackgroundColor(ext),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              ext,
              style: TextStyle(
                color: _badgeTextColor(ext),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Informações do arquivo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${file.formattedSize} • $formattedDate',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Ação rápida de abrir e menu
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            color: AppTheme.textSecondary,
            tooltip: 'Visualizar arquivo',
            onPressed: () => _openFile(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'open') _openFile(context);
              if (val == 'delete') onDelete?.call();
              if (val == 'share') onShare?.call();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 18, color: AppTheme.textDark),
                    SizedBox(width: 8),
                    Text('Abrir'),
                  ],
                ),
              ),
              if (onShare != null)
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, size: 18, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text('Compartilhar'),
                    ],
                  ),
                ),
              if (onDelete != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                      SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: AppTheme.errorColor)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
