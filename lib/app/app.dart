import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

class YouTVPlayApp extends ConsumerWidget {
  const YouTVPlayApp({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider); // Observa el cambio
    final themeNotifier = ref.read(themeProvider.notifier);
 
    return MaterialApp.router(
      title: 'YouTVPlay',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.currentThemeData,
      routerConfig: router,
    );
  }
}
