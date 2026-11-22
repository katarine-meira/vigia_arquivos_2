import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_arquivos/models/file_model.dart';

void main() {
  group('FileModel Tests', () {
    test('Calcula extensão corretamente a partir do nome do arquivo', () {
      final file1 = FileModel(
        id: '1',
        ownerId: 'user1',
        fileName: 'contrato_estagio.pdf',
        fileSize: 1024,
        mimeType: 'pdf',
        localPath: '/path/contrato_estagio.pdf',
        uploadedAt: DateTime.now(),
      );
      expect(file1.extension, 'PDF');

      final file2 = FileModel(
        id: '2',
        ownerId: 'user1',
        fileName: 'relatorio.docx',
        fileSize: 2048,
        mimeType: 'docx',
        localPath: '/path/relatorio.docx',
        uploadedAt: DateTime.now(),
      );
      expect(file2.extension, 'DOCX');
    });

    test('Retorna fallback para arquivos sem extensão clara', () {
      final file = FileModel(
        id: '3',
        ownerId: 'user1',
        fileName: 'arquivo_sem_extensao',
        fileSize: 500,
        mimeType: '',
        localPath: '/path/arquivo_sem_extensao',
        uploadedAt: DateTime.now(),
      );
      expect(file.extension, 'ARQ');
    });

    test('Formata tamanho de arquivo em B, KB e MB', () {
      final fileBytes = FileModel(
        id: '1',
        ownerId: 'user1',
        fileName: 'doc.txt',
        fileSize: 512,
        mimeType: 'txt',
        localPath: '',
        uploadedAt: DateTime.now(),
      );
      expect(fileBytes.formattedSize, '512 B');

      final fileKb = FileModel(
        id: '2',
        ownerId: 'user1',
        fileName: 'doc.txt',
        fileSize: 1024 * 50,
        mimeType: 'txt',
        localPath: '',
        uploadedAt: DateTime.now(),
      );
      expect(fileKb.formattedSize, '50.0 KB');

      final fileMb = FileModel(
        id: '3',
        ownerId: 'user1',
        fileName: 'doc.txt',
        fileSize: 1024 * 1024 * 2 + 500000,
        mimeType: 'txt',
        localPath: '',
        uploadedAt: DateTime.now(),
      );
      expect(fileMb.formattedSize.endsWith('MB'), true);
    });
  });
}
