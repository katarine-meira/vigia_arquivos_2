import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

/// ViewModel de autenticação.
/// Expõe estado reativo para Login, Cadastro e Logout.
class AuthViewModel extends ChangeNotifier {
  final AuthService _service;
  StreamSubscription<User?>? _authSub;

  AuthViewModel(this._service) {
    // Escuta mudanças de estado do Firebase e atualiza a UI automaticamente.
    _authSub = _service.authStateChanges.listen(_onAuthChanged);
  }

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _status == AuthStatus.loading;

  void _onAuthChanged(User? firebaseUser) {
    if (firebaseUser != null) {
      _user = _service.currentUser;
      _status = AuthStatus.authenticated;
    } else {
      _user = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _startLoading();
    try {
      _user = await _service.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    _startLoading();
    try {
      _user = await _service.signUp(name: name, email: email, password: password);
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _startLoading() {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
  }

  String _mapError(String code) => switch (code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'E-mail ou senha incorretos.',
        'email-already-in-use' => 'Este e-mail já está cadastrado.',
        'weak-password' => 'A senha deve ter pelo menos 6 caracteres.',
        'invalid-email' => 'E-mail inválido.',
        'too-many-requests' => 'Muitas tentativas. Tente novamente mais tarde.',
        _ => 'Ocorreu um erro. Tente novamente.',
      };

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
