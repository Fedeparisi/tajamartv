import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/channel_entity.dart';
import '../../../core/constants/app_colors.dart';
import '../player/player_screen.dart';
import '../admin/providers/channel_admin_provider.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  String selectedCategory = 'Todos';

  String _getProxiedImageUrl(String url) {
    if (url.isEmpty) {
      return 'https://images.unsplash.com/photo-1616469829581-73993eb86b02?q=80&w=200';
    }
    if (url.startsWith('http')) {
      final cleanUrl = url.replaceFirst(RegExp(r'https?://'), '');
      return 'https://images.weserv.nl/?url=$cleanUrl';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TV en Vivo',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (channels) {
          if (channels.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.tv_off, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No hay canales guardados.',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Agrega canales desde el panel de administración.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          final categories = ['Todos', ...channels.map((c) => c.categoryId).toSet()];
          final filteredChannels = selectedCategory == 'Todos'
              ? channels
              : channels.where((c) => c.categoryId == selectedCategory).toList();

          return Column(
            children: [
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => selectedCategory = category);
                        },
                        selectedColor: AppColors.primary,
                        checkmarkColor: AppColors.textPrimary,
                        backgroundColor: AppColors.panel,
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 16 / 9,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredChannels.length,
                  itemBuilder: (context, index) {
                    final channel = filteredChannels[index];
                    return _buildChannelCard(channel, channels);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChannelCard(ChannelEntity channel, List<ChannelEntity> allChannels) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              channel: channel,
              channels: allChannels,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(_getProxiedImageUrl(channel.logo)),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
            onError: (e, s) {},
          ),
        ),
        child: Stack(
          children: [
            // Status Indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: channel.status == 'online' ? AppColors.online : AppColors.offline,
                ),
              ),
            ),
            // Channel Name
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: Text(
                channel.name,
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Play Icon overlay
            const Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 40,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
