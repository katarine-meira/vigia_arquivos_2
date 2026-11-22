import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Encapsula todas as chamadas ao Firebase Auth.
/// As ViewModels nunca importam firebase_auth diretamente.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream que emite o usuário Firebase a cada mudança de estado de autenticação.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _toModel(credential.user!);
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user!.updateDisplayName(name.trim());
    await credential.user!.reload();
    return _toModel(_auth.currentUser!);
  }

  Future<void> signOut() => _auth.signOut();

  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user != null ? _toModel(user) : null;
  }

  UserModel _toModel(User user) => UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: (user.displayName?.isNotEmpty ?? false)
            ? user.displayName!
            : (user.email?.split('@').first ?? 'Usuário'),
      );
}
