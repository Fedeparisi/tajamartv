import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/profile_entity.dart';
import '../providers/profile_provider.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  final ProfileEntity? profile;

  const EditProfileDialog({super.key, this.profile});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _pinController;
  late String _selectedType;
  late String _selectedAvatarUrl;

  final List<Map<String, String>> _avatars = [
    {
      'name': 'Adulto',
      'url': 'assets/images/avatar_adult.png',
    },
    {
      'name': 'Infantil',
      'url': 'assets/images/avatar_kids.png',
    },
    {
      'name': 'Gamer',
      'url': 'assets/images/avatar_gamer.png',
    },
    {
      'name': 'Cine',
      'url': 'assets/images/avatar_cine.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    _pinController = TextEditingController(text: widget.profile?.pinCode ?? '');
    _selectedType = widget.profile?.type ?? 'adult';
    _selectedAvatarUrl = widget.profile?.avatarUrl ?? _avatars[0]['url']!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.profile == null;
    final profiles = ref.watch(profileProvider);
    final canDelete = !isNew && profiles.length > 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorder),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isNew ? 'Nuevo Perfil' : 'Editar Perfil',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Avatar Selection
                Text(
                  'Elige un Avatar',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _avatars.length,
                    itemBuilder: (context, index) {
                      final avatar = _avatars[index];
                      final isSelected = _selectedAvatarUrl == avatar['url'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatarUrl = avatar['url']!;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.secondary : Colors.transparent,
                              width: 3,
                            ),
                            image: DecorationImage(
                              image: avatar['url']!.startsWith('assets/')
                                  ? AssetImage(avatar['url']!) as ImageProvider
                                  : NetworkImage(avatar['url']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Perfil',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.secondary),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Type Selection (Dropdown)
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  dropdownColor: AppColors.panel,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Perfil',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'adult',
                      child: Text('Adulto'),
                    ),
                    DropdownMenuItem(
                      value: 'kids',
                      child: Text('Infantil'),
                    ),
                    DropdownMenuItem(
                      value: 'guest',
                      child: Text('Invitado'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedType = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Parental Control PIN (Optional)
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Código PIN (Opcional - 4 dígitos)',
                    labelStyle: TextStyle(color: Colors.white60),
                    helperText: 'Añade un PIN para bloquear el acceso a este perfil',
                    helperStyle: TextStyle(color: Colors.white38),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.secondary),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (canDelete)
                      TextButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: const Text('Confirmar', style: TextStyle(color: Colors.white)),
                              content: Text(
                                '¿Estás seguro que deseas eliminar el perfil "${widget.profile!.name}"?',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            await ref.read(profileProvider.notifier).deleteProfile(widget.profile!.id);
                            if (mounted) Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        label: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                      )
                    else
                      const SizedBox(),
                    
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.black,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final name = _nameController.text.trim();
                              final pin = _pinController.text.isEmpty ? null : _pinController.text;
                              
                              if (isNew) {
                                await ref.read(profileProvider.notifier).addProfile(
                                  name: name,
                                  avatarUrl: _selectedAvatarUrl,
                                  type: _selectedType,
                                  pinCode: pin,
                                );
                              } else {
                                final updated = ProfileEntity(
                                  id: widget.profile!.id,
                                  userId: widget.profile!.userId,
                                  name: name,
                                  avatarUrl: _selectedAvatarUrl,
                                  type: _selectedType,
                                  pinCode: pin,
                                );
                                await ref.read(profileProvider.notifier).updateProfile(updated);
                              }
                              
                              if (mounted) {
                                Navigator.of(context).pop();
                              }
                            }
                          },
                          child: Text(isNew ? 'Crear' : 'Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
