import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/package_entity.dart';

class AdminPackagesScreen extends StatefulWidget {
  const AdminPackagesScreen({super.key});

  @override
  State<AdminPackagesScreen> createState() => _AdminPackagesScreenState();
}

class _AdminPackagesScreenState extends State<AdminPackagesScreen> {
  final List<PackageEntity> _packages = [
    PackageEntity(
      id: 'pkg_1',
      companyId: 'company_tajamar',
      name: 'BÁSICO',
      price: 2500,
      maxDevices: 1,
      maxConcurrent: 1,
      categoryIds: ['General', 'Noticias'],
    ),
    PackageEntity(
      id: 'pkg_2',
      companyId: 'company_tajamar',
      name: 'ESTÁNDAR',
      price: 4000,
      maxDevices: 3,
      maxConcurrent: 2,
      categoryIds: ['General', 'Noticias', 'Infantil'],
    ),
    PackageEntity(
      id: 'pkg_3',
      companyId: 'company_tajamar',
      name: 'PREMIUM',
      price: 6500,
      maxDevices: 5,
      maxConcurrent: 3,
      categoryIds: ['General', 'Noticias', 'Infantil', 'Cine', 'Deportes'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gestión de Paquetes Comerciales',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Paquete'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 0.8,
            ),
            itemCount: _packages.length,
            itemBuilder: (context, index) {
              final package = _packages[index];
              return _buildPackageCard(package);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(PackageEntity package) {
    return Card(
      color: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: package.name == 'PREMIUM' ? AppColors.secondary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (package.name == 'PREMIUM')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('RECOMENDADO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            const SizedBox(height: 16),
            Text(
              package.name,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '\$${package.price.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            Text(package.currency, style: const TextStyle(color: AppColors.textSecondary)),
            const Divider(height: 48, color: AppColors.glassBorder),
            _buildFeatureRow(Icons.devices, 'Máx. ${package.maxDevices} dispositivos'),
            const SizedBox(height: 12),
            _buildFeatureRow(Icons.person, '${package.maxConcurrent} visualizaciones sim.'),
            const SizedBox(height: 12),
            _buildFeatureRow(Icons.category, '${package.categoryIds.length} Categorías'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Editar Paquete'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.secondary),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}
