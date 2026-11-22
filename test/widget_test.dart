import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_arquivos/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('Calcula iniciais corretamente com nome e sobrenome', () {
      const user = UserModel(
        uid: '123',
        email: 'ana@exemplo.com',
        displayName: 'Ana Martins',
      );
      expect(user.initials, 'AM');
      expect(user.firstName, 'Ana');
    });

    test('Calcula iniciais com apenas um nome', () {
      const user = UserModel(
        uid: '456',
        email: 'carlos@exemplo.com',
        displayName: 'Carlos',
      );
      expect(user.initials, 'C');
      expect(user.firstName, 'Carlos');
    });

    test('Retorna fallback quando nome estiver vazio', () {
      const user = UserModel(
        uid: '789',
        email: 'semnome@exemplo.com',
        displayName: '',
      );
      expect(user.initials, '?');
    });
  });
}
