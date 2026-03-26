import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/loans/loans_provider.dart';
import 'features/bills/bills_provider.dart';
import 'services/firebase_service.dart';
import 'services/local_storage_service.dart';
import 'services/sync_service.dart';
import 'shell/main_shell.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final firebase = FirebaseService();
    final local = LocalStorageService();
    final sync = SyncService(firebase, local);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => LoansProvider(firebase, local, sync),
        ),
        ChangeNotifierProvider(
          create: (_) => BillsProvider(firebase, local, sync),
        ),
      ],
      child: MaterialApp(
        title: 'Bijouterie El-Hajjam',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('ar', 'MA'),
        ],
        locale: const Locale('fr', 'FR'),
        home: const _RootRouter(),
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>();
    if (authState.isLoggedIn) {
      return const MainShell();
    }
    return const LoginScreen();
  }
}
