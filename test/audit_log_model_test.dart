import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_arquivos/models/audit_log_model.dart';

void main() {
  group('AuditLogModel Tests', () {
    test('Deve retornar descrições legíveis para cada tipo de ação', () {
      final uploadLog = AuditLogModel(
        id: '1',
        fileId: 'f1',
        fileName: 'contrato.pdf',
        actorId: 'u1',
        actorEmail: 'joao@gmail.com',
        ownerId: 'u1',
        ownerEmail: 'joao@gmail.com',
        action: 'UPLOAD',
        details: 'Upload realizado',
        timestamp: DateTime(2026, 11, 22, 14, 0),
      );
      expect(uploadLog.actionDescription, 'Upload de arquivo');

      final shareLog = AuditLogModel(
        id: '2',
        fileId: 'f1',
        fileName: 'contrato.pdf',
        actorId: 'u1',
        actorEmail: 'joao@gmail.com',
        ownerId: 'u1',
        ownerEmail: 'joao@gmail.com',
        action: 'SHARE',
        details: 'Compartilhado com maria@gmail.com',
        timestamp: DateTime(2026, 11, 22, 14, 10),
      );
      expect(shareLog.actionDescription, 'Compartilhamento');

      final viewLog = AuditLogModel(
        id: '3',
        fileId: 'f1',
        fileName: 'contrato.pdf',
        actorId: 'u2',
        actorEmail: 'maria@gmail.com',
        ownerId: 'u1',
        ownerEmail: 'joao@gmail.com',
        action: 'VIEW',
        details: 'Visualização interna',
        timestamp: DateTime(2026, 11, 22, 14, 15),
      );
      expect(viewLog.actionDescription, 'Visualização protegida');

      final downloadLog = AuditLogModel(
        id: '4',
        fileId: 'f1',
        fileName: 'contrato.pdf',
        actorId: 'u2',
        actorEmail: 'maria@gmail.com',
        ownerId: 'u1',
        ownerEmail: 'joao@gmail.com',
        action: 'DOWNLOAD',
        details: 'Cópia baixada',
        timestamp: DateTime(2026, 11, 22, 14, 18),
      );
      expect(downloadLog.actionDescription, 'Cópia baixada');

      final revokeLog = AuditLogModel(
        id: '5',
        fileId: 'f1',
        fileName: 'contrato.pdf',
        actorId: 'u1',
        actorEmail: 'joao@gmail.com',
        ownerId: 'u1',
        ownerEmail: 'joao@gmail.com',
        action: 'REVOKE',
        details: 'Revogado',
        timestamp: DateTime(2026, 11, 22, 14, 20),
      );
      expect(revokeLog.actionDescription, 'Acesso revogado');

      final editLog = AuditLogModel(
        id: '6',
        fileId: 'f1',
        fileName: 'contrato.pdf',
        actorId: 'u1',
        actorEmail: 'joao@gmail.com',
        ownerId: 'u1',
        ownerEmail: 'joao@gmail.com',
        action: 'EDIT_PERMISSIONS',
        details: 'Permissões alteradas',
        timestamp: DateTime(2026, 11, 22, 14, 25),
      );
      expect(editLog.actionDescription, 'Permissões alteradas');
    });

    test('Deve formatar data de auditoria corretamente', () {
      final log = AuditLogModel(
        id: '1',
        fileId: 'f1',
        fileName: 'documento.docx',
        actorId: 'u1',
        actorEmail: 'admin@vigia.com',
        ownerId: 'u1',
        ownerEmail: 'admin@vigia.com',
        action: 'UPLOAD',
        details: 'Upload realizado',
        timestamp: DateTime(2026, 11, 22, 15, 30),
      );

      expect(log.formattedDate, '22/11/2026 15:30');
    });
  });
}
