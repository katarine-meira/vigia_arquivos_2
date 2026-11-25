import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/file_service.dart';
import 'services/share_service.dart';
import 'viewmodels/audit_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/file_viewmodel.dart';
import 'viewmodels/share_viewmodel.dart';
import 'views/auth_wrapper.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VigiaApp());
}

class VigiaApp extends StatelessWidget {
  const VigiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final fileService = FileService();
    final shareService = ShareService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authService),
        ),
        ChangeNotifierProvider(
          create: (_) => FileViewModel(fileService),
        ),
        ChangeNotifierProvider(
          create: (_) => ShareViewModel(shareService, authService),
        ),
        ChangeNotifierProvider(
          create: (_) => AuditViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Vigia Arquivos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthWrapper(),
      ),
    );
  }
}
