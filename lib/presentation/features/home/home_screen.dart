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

  // Search state
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    _ytController?.close().catchError((e) {
      // ignore
    });
    _searchController.dispose();
    super.dispose();
  }

  void _initializePreviewVideo(ChannelEntity channel) {
    _videoInitTimer?.cancel();
    
    // Clean up current preview immediately
    setState(() {
      _videoController?.dispose();
      _videoController = null;
      _ytController?.close().catchError((e) {
        // ignore
      });
      _ytController = null;
      _isYt = false;
      _isVideoInitialized = false;
    });

    // Start delay to prevent loading preview while fast scrolling/hovering
    _videoInitTimer = Timer(const Duration(milliseconds: 400), () {
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
    return 'assets/images/youtvplay_logo.png';
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Buscar canales...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : Text(
                'YouTVPlay',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cerrar búsqueda',
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _isSearching = false;
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Buscar',
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            if (ref.watch(userRoleProvider) == 'admin' || ref.watch(userRoleProvider) == 'super_admin')
              IconButton(
                icon: const Icon(Icons.admin_panel_settings, color: AppColors.secondary),
                tooltip: 'Panel de Admin',
                onPressed: () => context.go('/admin'),
              ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Cambiar de Perfil',
              onPressed: () => context.go('/profiles'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authStateProvider.notifier).state = false;
              },
            ),
          ],
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

          // Apply real-time search filtering
          final filteredChannels = safeChannels.where((c) {
            final query = _searchQuery.toLowerCase();
            return c.name.toLowerCase().contains(query) ||
                c.categoryId.toLowerCase().contains(query);
          }).toList();

          if (filteredChannels.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No se encontraron resultados para "$_searchQuery"',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Prueba con otra palabra o categoría.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      child: const Text('Limpiar búsqueda'),
                    ),
                  ],
                ),
              ),
            );
          }

          final featuredChannel = filteredChannels.firstWhere(
            (c) => c.featured,
            orElse: () => filteredChannels.first,
          );

          if (!_initializedDefault) {
            _initializedDefault = true;
            _previewChannel = featuredChannel;
            _initializePreviewVideo(featuredChannel);
          }

          final activeChannel = filteredChannels.contains(_previewChannel)
              ? (_previewChannel ?? featuredChannel)
              : featuredChannel;
          final categories = filteredChannels.map((c) => c.categoryId).toSet().toList();

          return ListView(
            children: [
              // Dynamic Hero Preview Section (Shows category specific background and small channel logo)
              Container(
                height: 380,
                width: double.infinity,
                color: AppColors.panel,
                child: Stack(
                  children: [
                    // Video Preview Player (Underneath placeholder, always visible to browser to allow autoplay)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.5,
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

                    // Base Static Background Image (Placeholder) on top of video, fades out when video is initialized
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: _isVideoInitialized ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 600),
                        child: () {
                          final img = _getCategoryPreviewImage(activeChannel.categoryId);
                          if (img.startsWith('assets/')) {
                            return Image.asset(
                              img,
                              fit: BoxFit.cover,
                            );
                          }
                          return Image.network(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                          );
                        }(),
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
                CategoryCarousel(
                  title: cat,
                  channels: filteredChannels.where((c) => c.categoryId == cat).toList(),
                  allChannels: filteredChannels,
                  onHoverChannel: _startPreviewDelay,
                ),
            ],
          );
        },
      ),
    );
  }
}

class CategoryCarousel extends StatefulWidget {
  final String title;
  final List<ChannelEntity> channels;
  final List<ChannelEntity> allChannels;
  final Function(ChannelEntity) onHoverChannel;

  const CategoryCarousel({
    super.key,
    required this.title,
    required this.channels,
    required this.allChannels,
    required this.onHoverChannel,
  });

  @override
  State<CategoryCarousel> createState() => _CategoryCarouselState();
}

class _CategoryCarouselState extends State<CategoryCarousel> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;
  bool _isHoveringRow = false;
  bool _isHoveringLeftArrow = false;
  bool _isHoveringRightArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // Delay check to see if content is scrollable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollListener();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    setState(() {
      _showLeftArrow = currentScroll > 10;
      _showRightArrow = maxScroll > 0 && currentScroll < (maxScroll - 10);
    });
  }

  void _scroll(double offset) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + offset).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
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
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHoveringRow = true);
        _scrollListener(); // update positions on hover
      },
      onExit: (_) => setState(() => _isHoveringRow = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              widget.title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Stack(
            children: [
              SizedBox(
                height: 185,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: widget.channels.length,
                  itemBuilder: (context, index) {
                    final channel = widget.channels[index];
                    return HoverableChannelCard(
                      channel: channel,
                      allChannels: widget.allChannels,
                      onHoverChannel: widget.onHoverChannel,
                      getProxiedImageUrl: _getProxiedImageUrl,
                    );
                  },
                ),
              ),
              
              // Left navigation arrow button overlay
              if (_showLeftArrow && _isHoveringRow)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isHoveringLeftArrow = true),
                      onExit: (_) => setState(() => _isHoveringLeftArrow = false),
                      child: AnimatedRotation(
                        turns: _isHoveringLeftArrow ? -1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            onPressed: () => _scroll(-480),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Right navigation arrow button overlay
              if (_showRightArrow && _isHoveringRow)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isHoveringRightArrow = true),
                      onExit: (_) => setState(() => _isHoveringRightArrow = false),
                      child: AnimatedRotation(
                        turns: _isHoveringRightArrow ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                            onPressed: () => _scroll(480),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class HoverableChannelCard extends StatefulWidget {
  final ChannelEntity channel;
  final List<ChannelEntity> allChannels;
  final Function(ChannelEntity) onHoverChannel;
  final String Function(String) getProxiedImageUrl;

  const HoverableChannelCard({
    super.key,
    required this.channel,
    required this.allChannels,
    required this.onHoverChannel,
    required this.getProxiedImageUrl,
  });

  @override
  State<HoverableChannelCard> createState() => _HoverableChannelCardState();
}

class _HoverableChannelCardState extends State<HoverableChannelCard> {
  bool _isHovered = false;
  
  // Preview Player Controllers
  VideoPlayerController? _videoController;
  YoutubePlayerController? _ytController;
  bool _isYt = false;
  bool _isPlayingPreview = false;
  Timer? _previewTimer;

  @override
  void dispose() {
    _previewTimer?.cancel();
    _videoController?.dispose();
    _ytController?.close().catchError((e) {});
    super.dispose();
  }

  void _startPreview() {
    _previewTimer?.cancel();
    
    // If the controller is already created and paused, resume playing instantly!
    if (_isYt && _ytController != null) {
      _ytController?.playVideo();
      setState(() {
        _isPlayingPreview = true;
      });
      return;
    } else if (!_isYt && _videoController != null && _videoController!.value.isInitialized) {
      _videoController?.play();
      setState(() {
        _isPlayingPreview = true;
      });
      return;
    }

    _previewTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted || !_isHovered) return;

      final isYoutube = widget.channel.streamType.toLowerCase() == 'youtube' ||
          widget.channel.url.contains('youtube.com') ||
          widget.channel.url.contains('youtu.be');

      if (isYoutube) {
        final regExp = RegExp(
          r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
          caseSensitive: false,
        );
        final match = regExp.firstMatch(widget.channel.url);
        String? videoId;
        if (match != null && match.groupCount >= 2) {
          final id = match.group(2);
          if (id != null && id.length == 11) {
            videoId = id;
          }
        }

        if (videoId != null) {
          if (!mounted || !_isHovered) return;
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
                    _isPlayingPreview = true;
                  });
                }
              });
          });
          _ytController?.playVideo();
        }
      } else {
        if (widget.channel.url.isNotEmpty) {
          final controller = VideoPlayerController.networkUrl(Uri.parse(widget.channel.url));
          _videoController = controller;
          controller.initialize().then((_) {
            if (mounted && _isHovered) {
              controller.setVolume(0.0);
              controller.setLooping(true);
              controller.play();
              setState(() {
                _isYt = false;
                _isPlayingPreview = true;
              });
            } else {
              controller.dispose();
            }
          }).catchError((_) {
            // Ignore init errors for card preview
          });
        }
      }
    });
  }

  void _pausePreview() {
    _previewTimer?.cancel();
    if (_isYt) {
      _ytController?.pauseVideo();
    } else {
      _videoController?.pause();
    }
  }

  void _stopPreview() {
    _previewTimer?.cancel();
    setState(() {
      _isPlayingPreview = false;
      _videoController?.dispose();
      _videoController = null;
      _ytController?.close().catchError((e) {});
      _ytController = null;
      _isYt = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHoverChannel(widget.channel);
        _startPreview();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _pausePreview();
      },
      child: GestureDetector(
        onTap: () {
          _stopPreview();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlayerScreen(
                channel: widget.channel,
                channels: widget.allChannels,
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 240,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -6.0 : 0.0)
            ..scale(_isHovered ? 1.06 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                )
              else
                const BoxShadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Render running preview video inside the card underneath the placeholder
                if (_ytController != null || (_videoController != null && _videoController!.value.isInitialized))
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _isYt
                          ? (_ytController != null
                              ? FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: 320,
                                    height: 180,
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

                // Base Static Background Image (Placeholder) on top, fades out when video starts playing
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _isPlayingPreview ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: widget.channel.logo.startsWith('assets/')
                        ? Image.asset(
                            widget.channel.logo,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            widget.getProxiedImageUrl(widget.channel.logo),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                          ),
                  ),
                ),

                // Info overlay (Gradients and Channel details)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          _isPlayingPreview ? Colors.black54 : Colors.black87,
                        ],
                      ),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.channel.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!_isHovered)
                          const Icon(
                            Icons.play_circle_fill,
                            color: AppColors.secondary,
                            size: 32,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
