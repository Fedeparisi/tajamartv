import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../app/router/app_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/channel_entity.dart';
import '../admin/providers/channel_admin_provider.dart';
import '../player/player_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  ChannelEntity? _previewChannel;
  bool _initializedDefault = false;
  Timer? _hoverTimer;

  // Video Preview Controllers
  VideoPlayerController? _videoController;
  YoutubePlayerController? _ytController;
  bool _isYt = false;
  bool _isVideoInitialized = false;
  Timer? _videoInitTimer;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _videoInitTimer?.cancel();
    _videoController?.dispose();
    _ytController?.close();
    super.dispose();
  }

  void _initializePreviewVideo(ChannelEntity channel) {
    _videoInitTimer?.cancel();
    
    // Clean up current preview immediately
    setState(() {
      _videoController?.dispose();
      _videoController = null;
      _ytController?.close();
      _ytController = null;
      _isYt = false;
      _isVideoInitialized = false;
    });

    // Start delay to prevent loading preview while fast scrolling/hovering
    _videoInitTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted || _previewChannel?.id != channel.id) return;

      final isYoutube = channel.streamType.toLowerCase() == 'youtube' ||
          channel.url.contains('youtube.com') ||
          channel.url.contains('youtu.be');

      if (isYoutube) {
        final regExp = RegExp(
          r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
          caseSensitive: false,
        );
        final match = regExp.firstMatch(channel.url);
        String? videoId;
        if (match != null && match.groupCount >= 2) {
          final id = match.group(2);
          if (id != null && id.length == 11) {
            videoId = id;
          }
        }

        if (videoId != null) {
          if (!mounted || _previewChannel?.id != channel.id) return;
          setState(() {
            _isYt = true;
            _ytController = YoutubePlayerController.fromVideoId(
              videoId: videoId!,
              autoPlay: true,
              params: const YoutubePlayerParams(
                showControls: false,
                showFullscreenButton: false,
                mute: true,
                enableKeyboard: false,
                pointerEvents: PointerEvents.none,
              ),
            )..stream.listen((value) {
                if (value.playerState == PlayerState.cued) {
                  _ytController?.playVideo();
                }
                if (value.playerState == PlayerState.playing && mounted) {
                  setState(() {
                    _isVideoInitialized = true;
                  });
                }
              });
          });
          _ytController?.playVideo();
        }
      } else {
        if (channel.url.isNotEmpty) {
          final controller = VideoPlayerController.networkUrl(Uri.parse(channel.url));
          _videoController = controller;
          controller.initialize().then((_) {
            if (mounted && _previewChannel?.id == channel.id) {
              controller.setVolume(0.0);
              controller.setLooping(true);
              controller.play();
              setState(() {
                _isVideoInitialized = true;
              });
            } else {
              controller.dispose();
            }
          }).catchError((_) {
            // Ignore init errors for preview
          });
        }
      }
    });
  }

  void _startPreviewDelay(ChannelEntity channel) {
    if (_previewChannel?.id == channel.id) return;
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _previewChannel = channel;
        });
        _initializePreviewVideo(channel);
      }
    });
  }

  String _getCategoryPreviewImage(String categoryId) {
    final cat = categoryId.toLowerCase();
    if (cat.contains('deportes') || cat.contains('sports') || cat.contains('deporte')) {
      return 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?q=80&w=1200&auto=format&fit=crop';
    }
    if (cat.contains('cine') || cat.contains('peliculas') || cat.contains('películas') || cat.contains('movies')) {
      return 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?q=80&w=1200&auto=format&fit=crop';
    }
    if (cat.contains('noticias') || cat.contains('news')) {
      return 'https://images.unsplash.com/photo-1495020689067-958852a6565d?q=80&w=1200&auto=format&fit=crop';
    }
    if (cat.contains('musica') || cat.contains('música') || cat.contains('music')) {
      return 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=1200&auto=format&fit=crop';
    }
    if (cat.contains('infantil') || cat.contains('niños') || cat.contains('kids') || cat.contains('cartoon')) {
      return 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=1200&auto=format&fit=crop';
    }
    if (cat.contains('documentales') || cat.contains('ciencia') || cat.contains('nature') || cat.contains('documentary')) {
      return 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?q=80&w=1200&auto=format&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1593305841991-05c297ba4575?q=80&w=1200&auto=format&fit=crop';
  }

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
          'YouTVPlay',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          if (ref.watch(userRoleProvider) == 'admin' || ref.watch(userRoleProvider) == 'super_admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: AppColors.secondary),
              tooltip: 'Panel de Admin',
              onPressed: () => context.go('/admin'),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).state = false;
            },
          ),
        ],
      ),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error al cargar canales: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
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
                      'No hay canales disponibles en este momento.',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Inicia sesión como administrador (admin@youtvplay.com) para añadir canales desde el panel de gestión.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          final safeChannels = List<ChannelEntity>.from(channels);

          final featuredChannel = safeChannels.firstWhere(
            (c) => c.featured,
            orElse: () => safeChannels.first,
          );

          if (!_initializedDefault) {
            _initializedDefault = true;
            _previewChannel = featuredChannel;
            _initializePreviewVideo(featuredChannel);
          }

          final activeChannel = _previewChannel ?? featuredChannel;
          final categories = safeChannels.map((c) => c.categoryId).toSet().toList();

          return ListView(
            children: [
              // Dynamic Hero Preview Section (Shows category specific background and small channel logo)
              Container(
                height: 380,
                width: double.infinity,
                color: AppColors.panel,
                child: Stack(
                  children: [
                    // Base Static Background Image (Placeholder)
                    Positioned.fill(
                      child: Image.network(
                        _getCategoryPreviewImage(activeChannel.categoryId),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                    
                    // Video Preview Overlay (Fades in when initialized)
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: _isVideoInitialized ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 600),
                        child: IgnorePointer(
                          child: _isYt
                              ? (_ytController != null
                                  ? FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: 640,
                                        height: 360,
                                        child: YoutubePlayer(
                                          controller: _ytController!,
                                        ),
                                      ),
                                    )
                                  : const SizedBox())
                              : (_videoController != null && _videoController!.value.isInitialized
                                  ? FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: _videoController!.value.size.width,
                                        height: _videoController!.value.size.height,
                                        child: VideoPlayer(_videoController!),
                                      ),
                                    )
                                  : const SizedBox()),
                        ),
                      ),
                    ),

                    // Dark Gradient Vignette for text readability
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black45,
                              Colors.black87,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content overlay (Texts, logo, play button)
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'VISTA PREVIA',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (activeChannel.logo.isNotEmpty)
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.white10,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white24),
                                          image: DecorationImage(
                                            image: activeChannel.logo.startsWith('assets/')
                                                ? AssetImage(activeChannel.logo) as ImageProvider
                                                : NetworkImage(_getProxiedImageUrl(activeChannel.logo)),
                                            fit: BoxFit.contain,
                                            onError: (e, s) {},
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            activeChannel.name,
                                            style: GoogleFonts.outfit(
                                              fontSize: 34,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Stream: ${activeChannel.streamType.toUpperCase()} • ${activeChannel.categoryId}',
                                            style: const TextStyle(color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Stop home preview when leaving
                                        _videoController?.pause();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PlayerScreen(
                                              channel: activeChannel,
                                              channels: safeChannels,
                                            ),
                                          ),
                                        ).then((_) {
                                          // Resume preview when returning
                                          if (mounted && _videoController != null && _previewChannel?.id == activeChannel.id) {
                                            _videoController?.play();
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Reproducir ahora'),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Carousels by Category
              for (final cat in categories)
                _buildCategoryCarousel(
                  context,
                  cat,
                  safeChannels.where((c) => c.categoryId == cat).toList(),
                  safeChannels,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryCarousel(
    BuildContext context,
    String title,
    List<ChannelEntity> channels,
    List<ChannelEntity> allChannels,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return MouseRegion(
                onEnter: (_) => _startPreviewDelay(channel),
                child: GestureDetector(
                  onTap: () {
                    _hoverTimer?.cancel();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(
                          channel: channel,
                          channels: allChannels,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 240,
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: channel.logo.startsWith('assets/')
                            ? AssetImage(channel.logo) as ImageProvider
                            : NetworkImage(_getProxiedImageUrl(channel.logo)),
                        fit: BoxFit.cover,
                        onError: (e, s) {},
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              channel.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.play_circle_fill,
                            color: AppColors.secondary,
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
