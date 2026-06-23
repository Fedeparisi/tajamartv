import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_users_screen.dart';
import 'admin_channels_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TAJAMAR TV+ | ADMIN',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.play_circle_fill, color: Colors.white),
            label: const Text('Ver TV App', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              ref.read(authStateProvider.notifier).state = false;
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: AppColors.panel,
            child: ListView(
              children: [
                _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
                _buildDrawerItem(Icons.people, 'Usuarios', 1),
                _buildDrawerItem(Icons.tv, 'Canales (IPTV)', 2),
                _buildDrawerItem(Icons.category, 'Categorías', 3),
                _buildDrawerItem(Icons.monetization_on, 'Facturación', 4),
                _buildDrawerItem(Icons.monitor_heart, 'Monitor Streams', 5),
                _buildDrawerItem(Icons.support_agent, 'Soporte', 6),
                _buildDrawerItem(Icons.settings, 'Configuración', 7),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return const AdminUsersScreen();
      case 2:
        return const AdminChannelsScreen();
      default:
        return const Center(child: Text('Módulo en construcción'));
    }
  }

  Widget _buildDashboardOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Ejecutivo',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Usuarios Activos', '12,450', Icons.people_outline, AppColors.primary)),
            const SizedBox(width: 24),
            Expanded(child: _buildMetricCard('Streams Online', '1,024', Icons.stream, AppColors.online)),
            const SizedBox(width: 24),
            Expanded(child: _buildMetricCard('Streams Offline', '12', Icons.warning_amber, AppColors.offline)),
            const SizedBox(width: 24),
            Expanded(child: _buildMetricCard('Ingresos (Mes)', '\$ 4.2M', Icons.attach_money, AppColors.secondary)),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Card(
            color: AppColors.panel,
            child: Center(
              child: Text(
                'Gráficos Analytics Integrados Aquí',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: AppColors.panel,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

