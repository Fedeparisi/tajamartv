import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/user_entity.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  // Mock Data
  final List<UserEntity> _users = List.generate(
    15,
    (index) => UserEntity(
      id: 'usr_$index',
      companyId: 'company_tajamar',
      email: 'cliente$index@correo.com',
      displayName: 'Cliente $index',
      role: index == 0 ? 'admin' : 'client',
      blocked: index == 3,
      emailVerified: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gestión de Usuarios',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Usuario'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          color: AppColors.panel,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar por email o nombre...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Importar CSV'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Card(
            color: AppColors.panel,
            child: ListView.separated(
              itemCount: _users.length,
              separatorBuilder: (context, index) => const Divider(color: AppColors.glassBorder),
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.role == 'admin' ? AppColors.primary : Colors.grey[800],
                    child: Icon(
                      user.role == 'admin' ? Icons.shield : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user.blocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.offline.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.offline),
                          ),
                          child: const Text('Bloqueado', style: TextStyle(color: AppColors.offline, fontSize: 12)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.online.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.online),
                          ),
                          child: const Text('Activo', style: TextStyle(color: AppColors.online, fontSize: 12)),
                        ),
                      const SizedBox(width: 16),
                      IconButton(icon: const Icon(Icons.edit, color: AppColors.secondary), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.block, color: AppColors.offline), onPressed: () {}),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
