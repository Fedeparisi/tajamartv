import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/channel_entity.dart';
import 'providers/channel_admin_provider.dart';
import 'widgets/add_channel_dialog.dart';
import 'widgets/edit_channel_dialog.dart';
import 'widgets/import_m3u_dialog.dart';
import 'widgets/import_youtube_dialog.dart';
import 'widgets/url_checker.dart';

class AdminChannelsScreen extends ConsumerStatefulWidget {
  const AdminChannelsScreen({super.key});

  @override
  ConsumerState<AdminChannelsScreen> createState() => _AdminChannelsScreenState();
}

class _AdminChannelsScreenState extends ConsumerState<AdminChannelsScreen> {
  bool _isChecking = false;
  String _checkingProgress = '';

  Future<void> _runChannelChecks(List<ChannelEntity> channels) async {
    if (channels.isEmpty) return;

    setState(() {
      _isChecking = true;
      _checkingProgress = 'Iniciando chequeo...';
    });

    final repository = ref.read(channelRepositoryProvider);
    int total = channels.length;
    int processed = 0;

    for (final channel in channels) {
      if (!mounted) break;
      
      processed++;
      setState(() {
        _checkingProgress = 'Chequeando: $processed / $total\n(${channel.name})';
      });

      String newStatus = 'online';
      if (channel.url.isEmpty) {
        newStatus = 'offline';
      } else {
        final isOnline = await checkUrlOnline(channel.url);
        newStatus = isOnline ? 'online' : 'offline';
      }

      if (channel.status != newStatus) {
        final updatedChannel = ChannelEntity(
          id: channel.id,
          companyId: channel.companyId,
          name: channel.name,
          logo: channel.logo,
          categoryId: channel.categoryId,
          url: channel.url,
          streamType: channel.streamType,
          language: channel.language,
          country: channel.country,
          epgId: channel.epgId,
          featured: channel.featured,
          active: channel.active,
          order: channel.order,
          status: newStatus,
        );
        await repository.updateChannel(updatedChannel);
      }
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
        _checkingProgress = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Chequeo de canales completado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteOfflineChannels(List<ChannelEntity> channels) async {
    final offlineChannels = channels.where((c) => c.status == 'offline').toList();
    if (offlineChannels.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro que deseas eliminar de forma permanente los ${offlineChannels.length} canales que están caídos (OFFLINE)?',
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
      final repository = ref.read(channelRepositoryProvider);
      int deletedCount = 0;
      
      for (final channel in offlineChannels) {
        await repository.deleteChannel(channel.id);
        deletedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se eliminaron $deletedCount canales caídos.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllChannels(List<ChannelEntity> channels) async {
    if (channels.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Confirmar Eliminación Completa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro de que deseas eliminar de forma permanente TODOS los ${channels.length} canales de la lista?',
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
            child: const Text('Eliminar Todo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final repository = ref.read(channelRepositoryProvider);
      int deletedCount = 0;
      
      for (final channel in channels) {
        await repository.deleteChannel(channel.id);
        deletedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se eliminaron todos los $deletedCount canales.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            Text(
              'Gestión de Canales IPTV',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            channelsAsync.maybeWhen(
              data: (channels) {
                final hasOffline = channels.any((c) => c.status == 'offline');
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_isChecking)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _checkingProgress,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    else ...[
                      OutlinedButton.icon(
                        onPressed: () => _runChannelChecks(channels),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Chequear Estados'),
                      ),
                      if (hasOffline)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
                          onPressed: () => _deleteOfflineChannels(channels),
                          icon: const Icon(Icons.delete_sweep),
                          label: const Text('Limpiar Caídos'),
                        ),
                    ],
                    if (channels.isNotEmpty)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                        onPressed: () => _deleteAllChannels(channels),
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Vaciar Lista'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const ImportM3uDialog(),
                        );
                      },
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Importar M3U'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const ImportYoutubeDialog(),
                        );
                      },
                      icon: const Icon(Icons.video_library),
                      label: const Text('Importar YouTube'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AddChannelDialog(),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo Canal'),
                    ),
                  ],
                );
              },
              orElse: () => Container(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Card(
            color: AppColors.panel,
            child: channelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              data: (channels) {
                if (channels.isEmpty) {
                  return const Center(child: Text('No hay canales configurados. Importa una lista o añade uno.'));
                }
                return ListView.separated(
                  itemCount: channels.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.glassBorder),
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return ListTile(
                      leading: Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: channel.logo.startsWith('assets/')
                                ? AssetImage(channel.logo) as ImageProvider
                                : NetworkImage(channel.logo),
                            fit: BoxFit.cover,
                            onError: (e, s) {},
                          ),
                        ),
                      ),
                      title: Text(
                        channel.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${channel.streamType.toUpperCase()} • ${channel.categoryId}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: channel.status == 'online'
                                  ? AppColors.online.withOpacity(0.2)
                                  : AppColors.offline.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: channel.status == 'online' ? AppColors.online : AppColors.offline,
                              ),
                            ),
                            child: Text(
                              channel.status.toUpperCase(),
                              style: TextStyle(
                                color: channel.status == 'online' ? AppColors.online : AppColors.offline,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => EditChannelDialog(channel: channel),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.offline),
                            onPressed: () {
                              ref.read(channelAdminControllerProvider.notifier).deleteChannel(channel.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
