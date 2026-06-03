import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Reads android/app/google-services.json (project dittoc-5a839). Don't block
  // app start if Firebase is unavailable — Google sign-in just won't work.
  try {
    await Firebase.initializeApp();
  } catch (_) {/* continue without Firebase */}
  runApp(const ProviderScope(child: CourseForgeApp()));
}

class CourseForgeApp extends ConsumerWidget {
  const CourseForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'CourseForge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (mode) {
        ThemeModeChoice.system => ThemeMode.system,
        ThemeModeChoice.light => ThemeMode.light,
        ThemeModeChoice.dark => ThemeMode.dark,
      },
      routerConfig: router,
      // Tap anywhere outside a field to dismiss the keyboard (premium feel).
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
    );
  }
}
