import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/home/home_screen.dart';
import '../../presentation/features/admin/admin_dashboard_screen.dart';
import '../../presentation/features/profiles/profiles_screen.dart';

final authStateProvider = StateProvider<bool>((ref) => false);
final userRoleProvider = StateProvider<String>((ref) => 'client'); // client, admin, super_admin

final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(authStateProvider);
  final userRole = ref.watch(userRoleProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _ProviderListenable(ref),
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) {
        if (userRole == 'admin' || userRole == 'super_admin') {
          return '/admin';
        }
        return '/profiles'; // Cambio: Ir a selector de perfiles primero
      }

      // Proteger rutas de admin
      if (state.matchedLocation.startsWith('/admin')) {
        if (userRole != 'admin' && userRole != 'super_admin') {
          return '/profiles';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profiles',
        name: 'profiles',
        builder: (context, state) => const ProfilesScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});

class _ProviderListenable extends ChangeNotifier {
  _ProviderListenable(ProviderRef ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(userRoleProvider, (_, __) => notifyListeners());
  }
}
