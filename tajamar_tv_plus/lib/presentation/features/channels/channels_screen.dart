import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/channel_entity.dart';
import '../../../core/constants/app_colors.dart';
import '../player/player_screen.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  // Mock data para UI inicial
  final List<ChannelEntity> mockChannels = List.generate(
    20,
    (index) => ChannelEntity(
      id: index.toString(),
      companyId: 'company_tajamar',
      name: 'Canal HD ${index + 1}',
      logo: 'https://images.unsplash.com/photo-1616469829581-73993eb86b02?q=80&w=2070&auto=format&fit=crop',
      categoryId: index % 3 == 0 ? 'Deportes' : 'General',
      url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8', // Stream de prueba estándar
      streamType: 'hls',
      language: 'es',
      country: 'AR',
      epgId: 'tvg_123',
    ),
  );

  String selectedCategory = 'Todos';
  final List<String> categories = ['Todos', 'Deportes', 'Cine', 'Noticias', 'Infantil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TV en Vivo',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SizedBox(
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
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 16 / 9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: mockChannels.length,
        itemBuilder: (context, index) {
          final channel = mockChannels[index];
          return _buildChannelCard(channel);
        },
      ),
    );
  }

  Widget _buildChannelCard(ChannelEntity channel) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PlayerScreen(channel: channel),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(channel.logo),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
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
