import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Encapsula as chamadas de autenticação e registro de perfil no Firestore
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;

    // Garante que o e-mail do usuário logado esteja cadastrado na coleção de busca
    await _usersCollection.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email?.toLowerCase().trim() ?? '',
      'displayName': user.displayName ?? (user.email?.split('@').first ?? 'Usuário'),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return _toModel(user);
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.toLowerCase().trim();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
    await credential.user!.updateDisplayName(name.trim());
    await credential.user!.reload();

    final user = _auth.currentUser!;

    // Salva perfil no firestore para busca e validação de destinatários
    await _usersCollection.doc(user.uid).set({
      'uid': user.uid,
      'email': cleanEmail,
      'displayName': name.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    return _toModel(user);
  }

  // Verifica se um e-mail existe no sistema
  Future<bool> userExists(String email) async {
    final cleanEmail = email.toLowerCase().trim();

    // Consulta coleção de usuários no Firestore
    try {
      final snapshot = await _usersCollection
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) return true;
    } catch (_) {}

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(cleanEmail);
  }

  Future<List<String>> findMissingEmails(List<String> emails) async {
    final missing = <String>[];
    for (final email in emails) {
      final exists = await userExists(email);
      if (!exists) {
        missing.add(email);
      }
    }
    return missing;
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
