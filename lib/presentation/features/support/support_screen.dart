import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Centro de Soporte',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿En qué podemos ayudarte?',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildSupportCategory(context, Icons.build, 'Problema Técnico', 'Fallas en canales, buffer o app'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSupportCategory(context, Icons.payment, 'Facturación', 'Pagos, tarjetas o planes'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSupportCategory(context, Icons.help_outline, 'Consulta General', 'Dudas comerciales u otros'),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              'Mis Tickets Activos',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  Card(
                    color: AppColors.panel,
                    child: ListTile(
                      leading: const Icon(Icons.build, color: AppColors.primary),
                      title: const Text('Falla en el canal de deportes'),
                      subtitle: const Text('Técnico • Actualizado hace 2 horas'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.unstable.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.unstable),
                        ),
                        child: const Text('EN PROCESO', style: TextStyle(color: AppColors.unstable, fontSize: 12)),
                      ),
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('NUEVO TICKET'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSupportCategory(BuildContext context, IconData icon, String title, String description) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.secondary),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
