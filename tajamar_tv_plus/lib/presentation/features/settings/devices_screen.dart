import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/device_entity.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final int maxDevicesAllowed = 3;
  
  final List<DeviceEntity> _devices = [
    DeviceEntity(
      id: 'dev_1',
      userId: 'usr_me',
      companyId: 'company_tajamar',
      platform: 'android_tv',
      deviceName: 'Smart TV Living',
      deviceId: 'hwid_123',
      lastAccess: DateTime.now(),
    ),
    DeviceEntity(
      id: 'dev_2',
      userId: 'usr_me',
      companyId: 'company_tajamar',
      platform: 'android',
      deviceName: 'Samsung S23',
      deviceId: 'hwid_456',
      lastAccess: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Dispositivos',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Tu plan PREMIUM permite hasta $maxDevicesAllowed dispositivos vinculados.',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    '${_devices.length}/$maxDevicesAllowed',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return Card(
                    color: AppColors.panel,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(
                        device.platform == 'android_tv' ? Icons.tv : Icons.smartphone,
                        size: 40,
                        color: AppColors.secondary,
                      ),
                      title: Text(
                        device.deviceName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Plataforma: ${device.platform}'),
                          Text('Último acceso: ${device.lastAccess.toString().substring(0, 16)}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.logout, color: AppColors.offline),
                        tooltip: 'Desvincular',
                        onPressed: () {
                          // Acción para desvincular el dispositivo
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
