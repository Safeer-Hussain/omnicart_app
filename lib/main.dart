import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'presentation/splash/splash_view.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };

      try {
        setupDependencyInjection();
      } catch (_) {
        // Defensive non-blocking initialization
      }

      runApp(const ProviderScope(child: OmniCartApp()));
    },
    (error, stack) {
      // Uncaught asynchronous zone error logger
      debugPrint('OmniCart Unhandled Error: $error');
    },
  );
}

class OmniCartApp extends ConsumerWidget {
  const OmniCartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashView(),
    );
  }
}
