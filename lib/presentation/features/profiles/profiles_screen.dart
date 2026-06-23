import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/profile_entity.dart';
import 'providers/profile_provider.dart';
import 'widgets/edit_profile_dialog.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  bool _isEditing = false;

  void _showPinDialog(ProfileEntity profile) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Código PIN Requerido',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa el PIN de 4 dígitos para acceder al perfil de ${profile.name}:',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.secondary)),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.black),
            onPressed: () {
              if (pinController.text == profile.pinCode) {
                Navigator.of(context).pop();
                context.go('/home');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN incorrecto, intenta de nuevo.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ingresar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isEditing ? 'Administrar Perfiles' : '¿Quién está viendo ahora?',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 48),
              
              // Profiles list row
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 32,
                runSpacing: 32,
                children: profiles.map((profile) {
                  return InkWell(
                    onTap: () {
                      if (_isEditing) {
                        // Open edit dialog
                        showDialog(
                          context: context,
                          builder: (_) => EditProfileDialog(profile: profile),
                        );
                      } else {
                        // Regular login profile
                        if (profile.pinCode != null && profile.pinCode!.isNotEmpty) {
                          _showPinDialog(profile);
                        } else {
                          context.go('/home');
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.panel,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isEditing ? AppColors.secondary : AppColors.glassBorder,
                                  width: 2,
                                ),
                                image: DecorationImage(
                                  image: profile.avatarUrl.startsWith('assets/')
                                      ? AssetImage(profile.avatarUrl) as ImageProvider
                                      : NetworkImage(profile.avatarUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Gray / Pencil overlay if editing
                            if (_isEditing)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (profile.pinCode != null && profile.pinCode!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.lock_outline, size: 16, color: Colors.white38),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 64),
              
              // Administration Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _isEditing ? AppColors.secondary : Colors.white24),
                    ),
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    },
                    icon: Icon(_isEditing ? Icons.check : Icons.settings, color: _isEditing ? AppColors.secondary : Colors.white70),
                    label: Text(
                      _isEditing ? 'Listo' : 'Administrar Perfiles',
                      style: TextStyle(color: _isEditing ? AppColors.secondary : Colors.white70),
                    ),
                  ),
                  if (!_isEditing && profiles.length < 5) ...[
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const EditProfileDialog(),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Perfil'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
