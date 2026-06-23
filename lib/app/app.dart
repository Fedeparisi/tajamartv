import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class YouTVPlayApp extends ConsumerWidget {
  const YouTVPlayApp({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
 
    return MaterialApp.router(
      title: 'YouTVPlay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Obligatorio Dark Mode Premium
      routerConfig: router,
    );
  }
}
