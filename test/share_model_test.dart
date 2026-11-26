import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_arquivos/models/share_model.dart';

void main() {
  group('ShareModel Tests', () {
    test('Compartilhamento ativo sem expiração deve ter isActive true', () {
      final share = ShareModel(
        id: '1',
        fileId: 'f1',
        fileName: 'contrato.pdf',
        fileSize: 1024,
        mimeType: 'pdf',
        localPath: '/path/contrato.pdf',
        ownerId: 'user1',
        ownerEmail: 'dono@exemplo.com',
        recipientEmail: 'destinatario@exemplo.com',
        canView: true,
        canDownload: false,
        canReshare: false,
        expiresAt: null,
        isRevoked: false,
        createdAt: DateTime.now(),
      );

      expect(share.isActive, true);
      expect(share.isExpired, false);
      expect(share.statusDescription, 'Ativo');
    });

    test('Compartilhamento com data passada deve acusar isExpired true', () {
      final share = ShareModel(
        id: '2',
        fileId: 'f2',
        fileName: 'relatorio.pdf',
        fileSize: 2048,
        mimeType: 'pdf',
        localPath: '/path/relatorio.pdf',
        ownerId: 'user1',
        ownerEmail: 'dono@exemplo.com',
        recipientEmail: 'destinatario@exemplo.com',
        canView: true,
        canDownload: false,
        canReshare: false,
        expiresAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRevoked: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(share.isExpired, true);
      expect(share.isActive, false);
      expect(share.statusDescription, 'Expirado');
    });

    test('Compartilhamento revogado pelo proprietário deve ter isRevoked true e isActive false', () {
      final share = ShareModel(
        id: '3',
        fileId: 'f3',
        fileName: 'documento.pdf',
        fileSize: 500,
        mimeType: 'pdf',
        localPath: '/path/documento.pdf',
        ownerId: 'user1',
        ownerEmail: 'dono@exemplo.com',
        recipientEmail: 'destinatario@exemplo.com',
        canView: true,
        canDownload: false,
        canReshare: false,
        expiresAt: DateTime.now().add(const Duration(days: 5)),
        isRevoked: true,
        createdAt: DateTime.now(),
      );

      expect(share.isRevoked, true);
      expect(share.isActive, false);
      expect(share.statusDescription, 'Revogado');
    });

    test('Compartilhamento com visualização única deve ficar inativo após aberto', () {
      final shareNaoAberto = ShareModel(
        id: '4',
        fileId: 'f4',
        fileName: 'segredo.pdf',
        fileSize: 500,
        mimeType: 'pdf',
        localPath: '/path/segredo.pdf',
        ownerId: 'user1',
        ownerEmail: 'dono@exemplo.com',
        recipientEmail: 'destinatario@exemplo.com',
        canView: true,
        canDownload: false,
        canReshare: false,
        viewOnce: true,
        hasOpened: false,
        isRevoked: false,
        createdAt: DateTime.now(),
      );

      expect(shareNaoAberto.isViewOnceConsumed, false);
      expect(shareNaoAberto.isActive, true);
      expect(shareNaoAberto.statusDescription, 'Ativo');

      final shareAberto = ShareModel(
        id: '5',
        fileId: 'f4',
        fileName: 'segredo.pdf',
        fileSize: 500,
        mimeType: 'pdf',
        localPath: '/path/segredo.pdf',
        ownerId: 'user1',
        ownerEmail: 'dono@exemplo.com',
        recipientEmail: 'destinatario@exemplo.com',
        canView: true,
        canDownload: false,
        canReshare: false,
        viewOnce: true,
        hasOpened: true,
        isRevoked: false,
        createdAt: DateTime.now(),
      );

      expect(shareAberto.isViewOnceConsumed, true);
      expect(shareAberto.isActive, false);
      expect(shareAberto.statusDescription, 'Visualizado (1x)');
    });
  });
}
