import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'home/home_screen.dart';
import 'splash/splash_screen.dart';

// Decide qual tela exibir com base no estado de autenticação.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        return switch (vm.status) {
          AuthStatus.initial => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          AuthStatus.authenticated => const HomeScreen(),
          _ => const SplashScreen(),
        };
      },
    );
  }
}
