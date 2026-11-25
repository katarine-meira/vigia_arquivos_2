import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/file_model.dart';
import '../../models/share_model.dart';
import '../../viewmodels/audit_viewmodel.dart';
import '../share/share_screen.dart';

class ProtectedViewerScreen extends StatefulWidget {
  final ShareModel share;
  final String currentUserEmail;

  const ProtectedViewerScreen({
    super.key,
    required this.share,
    required this.currentUserEmail,
  });

  @override
  State<ProtectedViewerScreen> createState() => _ProtectedViewerScreenState();
}

class _ProtectedViewerScreenState extends State<ProtectedViewerScreen> {
  int _currentPage = 0;
  int _totalPages = 0;
  bool _pdfReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Registra evento de visualização que aparecerá APENAS para o proprietário do documento
        context.read<AuditViewModel>().log(
              fileId: widget.share.fileId,
              fileName: widget.share.fileName,
              actorId: '',
              actorEmail: widget.currentUserEmail,
              ownerId: widget.share.ownerId,
              ownerEmail: widget.share.ownerEmail,
              action: 'VIEW',
              details: 'Destinatário ${widget.currentUserEmail} abriu e visualizou o documento',
            );
      }
    });
  }

  bool get _isPdf => widget.share.extension.toUpperCase() == 'PDF';

  bool get _isImage {
    final ext = widget.share.extension.toUpperCase();
    return ['PNG', 'JPG', 'JPEG', 'WEBP', 'GIF'].contains(ext);
  }

  bool get _isText {
    final ext = widget.share.extension.toUpperCase();
    return ['TXT', 'CSV', 'JSON', 'MD', 'LOG'].contains(ext);
  }

  Future<String> _readTextContent() async {
    try {
      final file = File(widget.share.localPath);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return 'Conteúdo textual não disponível no dispositivo.';
  }

  Future<void> _handleDownload(BuildContext context) async {
    try {
      final sourceFile = File(widget.share.localPath);
      if (!await sourceFile.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arquivo original não encontrado localmente neste dispositivo.'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Salva uma cópia na pasta de documentos da aplicação
      final docsDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${docsDir.path}/downloads');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final targetFile = File('${exportDir.path}/${widget.share.fileName}');
      await sourceFile.copy(targetFile.path);

      if (context.mounted) {
        // Notifica o proprietário que uma cópia física foi baixada
        context.read<AuditViewModel>().log(
              fileId: widget.share.fileId,
              fileName: widget.share.fileName,
              actorId: '',
              actorEmail: widget.currentUserEmail,
              ownerId: widget.share.ownerId,
              ownerEmail: widget.share.ownerEmail,
              action: 'DOWNLOAD',
              details: 'Destinatário ${widget.currentUserEmail} baixou uma cópia do arquivo',
            );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cópia salva com sucesso! Abrindo documento...'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await OpenFilex.open(targetFile.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao baixar cópia: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleReshare(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShareScreen(
          initialFile: FileModel(
            id: widget.share.fileId,
            ownerId: widget.share.ownerId,
            fileName: widget.share.fileName,
            fileSize: widget.share.fileSize,
            mimeType: widget.share.mimeType,
            localPath: widget.share.localPath,
            uploadedAt: widget.share.createdAt,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileExists = widget.share.localPath.isNotEmpty && File(widget.share.localPath).existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B), // Fundo escuro focado para leitura
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.share.fileName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _isPdf && _pdfReady && _totalPages > 0
                  ? 'Pág. ${_currentPage + 1} de $_totalPages • De: ${widget.share.ownerEmail}'
                  : 'Enviado por: ${widget.share.ownerEmail}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (widget.share.canReshare)
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20, color: Colors.white),
              tooltip: 'Re-compartilhar com terceiros',
              onPressed: () => _handleReshare(context),
            ),
          if (widget.share.canDownload)
            IconButton(
              icon: const Icon(Icons.download_rounded, size: 20, color: Colors.white),
              tooltip: 'Baixar / Salvar cópia',
              onPressed: () => _handleDownload(context),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Conteúdo do documento visualizado dentro do próprio app
          Center(
            child: !fileExists
                ? _buildNotFoundView()
                : _isPdf
                    ? PDFView(
                        filePath: widget.share.localPath,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: true,
                        pageFling: true,
                        backgroundColor: const Color(0xFF0B132B),
                        onRender: (pages) {
                          setState(() {
                            _totalPages = pages ?? 0;
                            _pdfReady = true;
                          });
                        },
                        onPageChanged: (page, total) {
                          setState(() {
                            _currentPage = page ?? 0;
                          });
                        },
                        onError: (error) {
                          debugPrint('Erro ao renderizar PDF: $error');
                        },
                      )
                    : _isImage
                        ? InteractiveViewer(
                            minScale: 0.8,
                            maxScale: 4.0,
                            child: Image.file(
                              File(widget.share.localPath),
                              fit: BoxFit.contain,
                            ),
                          )
                        : _isText
                            ? FutureBuilder<String>(
                                future: _readTextContent(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const CircularProgressIndicator(color: Colors.white);
                                  }
                                  return SingleChildScrollView(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      snapshot.data!,
                                      style: const TextStyle(
                                        color: Color(0xFFE2E8F0),
                                        fontSize: 14,
                                        height: 1.6,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  );
                                },
                              )
                            : _buildGenericDocumentView(),
          ),

          // Marca d'água dinâmica e translúcida
          IgnorePointer(
            child: Center(
              child: Transform.rotate(
                angle: -0.4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.currentUserEmail,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.13),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'VIGIA ARQUIVOS • RASTREADO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.10),
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tarja inferior de status e permissões
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 15, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Visualização interna • ${widget.share.canDownload ? "Download liberado" : "Download bloqueado"} • ${widget.share.canReshare ? "Re-envio liberado" : "Re-envio bloqueado"}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.file_copy_outlined, size: 56, color: Color(0xFF64748B)),
        const SizedBox(height: 16),
        Text(
          widget.share.fileName,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'O arquivo foi registrado pelo remetente,\nmas a cópia física não está neste dispositivo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildGenericDocumentView() {
    final isWord = ['DOCX', 'DOC'].contains(widget.share.extension.toUpperCase());
    final isExcel = ['XLSX', 'XLS', 'CSV'].contains(widget.share.extension.toUpperCase());

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isWord
                      ? const Color(0xFFEFF6FF)
                      : isExcel
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.share.extension.toUpperCase(),
                  style: TextStyle(
                    color: isWord
                        ? const Color(0xFF2563EB)
                        : isExcel
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.share.fileName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                isWord
                    ? 'Documento Microsoft Word (.docx)\nVisualização nativa protegida é otimizada para PDFs e Imagens.'
                    : 'Documento protegido • Visualização controlada',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              if (widget.share.canDownload) ...[
                ElevatedButton.icon(
                  onPressed: () => _handleDownload(context),
                  icon: const Icon(Icons.file_open_outlined, size: 18),
                  label: const Text('Abrir no leitor de documentos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
                const SizedBox(height: 14),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_clock_outlined, size: 16, color: Color(0xFFDC2626)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Download restrito pelo remetente: cópia externa bloqueada.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: AppTheme.primary),
                    SizedBox(width: 6),
                    Text(
                      'Custódia e-ARQ Brasil • LGPD',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
