import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../app/theme/layout_provider.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final currentLayout = ref.watch(layoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Estilo de Pantalla Principal',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildLayoutOption(
            context: context,
            ref: ref,
            layout: HomeLayoutStyle.netflix,
            currentLayout: currentLayout,
            title: 'Clásico (Netflix)',
            subtitle: 'Carruseles horizontales y gran portada superior.',
            icon: Icons.movie_filter,
          ),
          const SizedBox(height: 12),
          _buildLayoutOption(
            context: context,
            ref: ref,
            layout: HomeLayoutStyle.disney,
            currentLayout: currentLayout,
            title: 'Marcas (Disney+)',
            subtitle: 'Botones por categoría destacada y carrusel superior.',
            icon: Icons.stars,
          ),
          const SizedBox(height: 12),
          _buildLayoutOption(
            context: context,
            ref: ref,
            layout: HomeLayoutStyle.directv,
            currentLayout: currentLayout,
            title: 'TV en Vivo (DirecTV GO)',
            subtitle: 'Reproductor fijo y guía de programación inferior.',
            icon: Icons.live_tv,
          ),
          const SizedBox(height: 12),
          _buildLayoutOption(
            context: context,
            ref: ref,
            layout: HomeLayoutStyle.flow,
            currentLayout: currentLayout,
            title: 'Navegación Lateral (Flow)',
            subtitle: 'Menú a la izquierda y contenido estructurado.',
            icon: Icons.menu_open,
          ),
          const SizedBox(height: 32),
          Text(
            'Paleta de Colores',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildThemeOption(
            context: context,
            ref: ref,
            mode: AppThemeMode.dark,
            currentMode: currentTheme,
            title: 'Premium Dark',
            subtitle: 'Modo oscuro por defecto, alto contraste.',
            icon: Icons.dark_mode,
            color: const Color(0xFF111827),
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context: context,
            ref: ref,
            mode: AppThemeMode.light,
            currentMode: currentTheme,
            title: 'Tajamar Light',
            subtitle: 'Estilo claro y vibrante con colores de marca.',
            icon: Icons.light_mode,
            color: const Color(0xFFF3F4F6),
            textColor: Colors.black87,
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context: context,
            ref: ref,
            mode: AppThemeMode.midnight,
            currentMode: currentTheme,
            title: 'Midnight Blue',
            subtitle: 'Tonos azules profundos y elegantes.',
            icon: Icons.nightlight_round,
            color: const Color(0xFF0B0F19),
          ),
          const SizedBox(height: 32),
          Text(
            'Cuenta y Dispositivos',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.devices, color: AppColors.secondary),
              title: const Text('Mis Dispositivos', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Gestiona las pantallas vinculadas a tu cuenta.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/devices');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutOption({
    required BuildContext context,
    required WidgetRef ref,
    required HomeLayoutStyle layout,
    required HomeLayoutStyle currentLayout,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = layout == currentLayout;
    return InkWell(
      onTap: () {
        ref.read(layoutProvider.notifier).setLayout(layout);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Theme.of(context).iconTheme.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required AppThemeMode mode,
    required AppThemeMode currentMode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Color textColor = Colors.white,
  }) {
    final isSelected = mode == currentMode;
    return InkWell(
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(mode);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
