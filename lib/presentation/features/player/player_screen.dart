import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../domain/entities/channel_entity.dart';
import '../../../core/constants/app_colors.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final ChannelEntity channel;
  final List<ChannelEntity> channels;

  const PlayerScreen({
    super.key,
    required this.channel,
    required this.channels,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late ChannelEntity _currentChannel;
  VideoPlayerController? _controller;
  YoutubePlayerController? _ytController;
  bool _isYoutube = false;
  bool _hasError = false;
  String _errorMessage = '';
  String? _lastCuedVideoId;
  
  // HUD state for channel zapping feedback
  bool _showZapHUD = false;
  Timer? _zapHUDTimer;
  bool _isMuted = true;
  final FocusNode _focusNode = FocusNode();

  // Volume state properties
  int _volumePercent = 80; // Default volume level (80%)
  bool _showVolumeHUD = false;
  Timer? _volumeHUDTimer;

  // Cache for preloaded adjacent channel controllers
  final Map<String, VideoPlayerController> _preloadedControllers = {};

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    
    // Register global keyboard listener to capture keys before they get intercepted
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
    
    _loadChannel(_currentChannel);
    _preloadAdjacentChannels();

    // Request focus after build to capture keyboard events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextChannel();
        return true; // Event handled
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _previousChannel();
        return true; // Event handled
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _adjustVolume(5);
        return true; // Event handled
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _adjustVolume(-5);
        return true; // Event handled
      }
    }
    return false;
  }

  void _adjustVolume(int delta) {
    // Automatically unmute if user adjusts volume
    if (_isMuted) {
      _isMuted = false;
      if (_isYoutube) {
        _ytController?.unMute();
      } else {
        _controller?.setVolume(_volumePercent / 100.0);
      }
    }

    setState(() {
      _volumePercent = (_volumePercent + delta).clamp(0, 100);
      _showVolumeHUD = true;
    });

    if (_isYoutube) {
      _ytController?.setVolume(_volumePercent);
    } else {
      _controller?.setVolume(_volumePercent / 100.0);
    }

    _volumeHUDTimer?.cancel();
    _volumeHUDTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _showVolumeHUD = false;
        });
      }
    });
  }

  void _loadChannel(ChannelEntity channel) {
    final wasYoutube = _isYoutube;
    final nextIsYoutube = channel.streamType.toLowerCase() == 'youtube' ||
        channel.url.contains('youtube.com') ||
        channel.url.contains('youtu.be');

    setState(() {
      _isMuted = true;
      _currentChannel = channel;
      _hasError = false;
      _errorMessage = '';
      _isYoutube = nextIsYoutube;
      
      // Trigger Zap HUD overlay
      _showZapHUD = true;
    });

    // Start timer to hide the HUD after 2.5 seconds
    _zapHUDTimer?.cancel();
    _zapHUDTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showZapHUD = false;
        });
      }
    });

    if (nextIsYoutube) {
      final videoId = _extractYoutubeId(channel.url);
      if (videoId == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No se pudo extraer el ID del video de YouTube';
        });
        return;
      }

      // Always recreate YouTube Controller when switching to guarantee autoplay on web
      if (_ytController != null) {
        _ytController!.close();
        _ytController = null;
      }
      _controller?.dispose();
      _controller = null;
      _initializeYoutubePlayer(channel.url);
    } else {
      // Clean up YouTube player if zapping to normal channel
      if (_ytController != null) {
        _ytController!.close();
        _ytController = null;
      }
      
      // Speed check: Check if we have preloaded the controller for this channel
      if (_preloadedControllers.containsKey(channel.id)) {
        final preloaded = _preloadedControllers[channel.id]!;
        _controller?.dispose(); // Dispose old controller
        _controller = preloaded;
        _preloadedControllers.remove(channel.id); // Active, remove from cache list
        
        if (_controller!.value.isInitialized) {
          _controller!.play();
          setState(() {});
        } else {
          // If in the middle of initializing, wait and play
          _controller!.initialize().then((_) {
            if (mounted && _currentChannel.id == channel.id) {
              _controller?.setVolume(0.0);
              _controller?.play();
              setState(() {});
            }
          }).catchError((error) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = error.toString();
              });
            }
          });
        }
      } else {
        _controller?.dispose();
        _controller = null;
        _initializePlayer(channel.url);
      }
    }

    // Trigger preloading in background for the next/prev channels sequentially
    _preloadAdjacentChannels();
  }

  void _preloadAdjacentChannels() {
    if (widget.channels.isEmpty) return;
    final currentIndex = widget.channels.indexWhere((c) => c.id == _currentChannel.id);
    if (currentIndex == -1) return;

    final nextIndex = (currentIndex + 1) % widget.channels.length;
    final prevIndex = (currentIndex - 1 + widget.channels.length) % widget.channels.length;

    final nextChannel = widget.channels[nextIndex];
    final prevChannel = widget.channels[prevIndex];

    // Clean up cached controllers that are no longer adjacent
    final activeIds = {nextChannel.id, prevChannel.id};
    final keysToRemove = _preloadedControllers.keys.where((k) => !activeIds.contains(k)).toList();
    for (final k in keysToRemove) {
      _preloadedControllers[k]?.dispose();
      _preloadedControllers.remove(k);
    }

    // Preload next and previous channels asynchronously
    _preloadChannelController(nextChannel);
    _preloadChannelController(prevChannel);
  }

  void _preloadChannelController(ChannelEntity channel) {
    // Only preload standard/M3U streams (YouTube does not support multiple instances well)
    final isYt = channel.streamType.toLowerCase() == 'youtube' ||
        channel.url.contains('youtube.com') ||
        channel.url.contains('youtu.be');

    if (isYt) return;
    if (_preloadedControllers.containsKey(channel.id)) return;

    final uri = Uri.parse(channel.url);
    final controller = VideoPlayerController.networkUrl(uri);
    _preloadedControllers[channel.id] = controller;

    controller.initialize().then((_) {
      if (mounted) {
        controller.setVolume(0.0); // Muted in background
        // Start buffering in background
      }
    }).catchError((_) {
      // Discard on load error
      controller.dispose();
      _preloadedControllers.remove(channel.id);
    });
  }

  String? _extractYoutubeId(String url) {
    final regExp = RegExp(
      r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 2) {
      final id = match.group(2);
      if (id != null && id.length == 11) {
        return id;
      }
    }
    return null;
  }

  void _initializeYoutubePlayer(String url) {
    final videoId = _extractYoutubeId(url);
    if (videoId == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No se pudo extraer el ID del video de YouTube';
      });
      return;
    }

    _ytController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: false, // Hide controls so clicks don't focus iframe
        showFullscreenButton: false,
        mute: true, // Start muted to ensure autoplay works on modern browsers
        enableKeyboard: false,
        pointerEvents: PointerEvents.none,
      ),
    );

    _ytController!.stream.listen((value) {
      if (value.playerState == PlayerState.cued) {
        final currentId = _extractYoutubeId(_currentChannel.url);
        if (currentId != null && _lastCuedVideoId != currentId) {
          _lastCuedVideoId = currentId;
          _ytController?.playVideo();
        }
      }
    });
    
    // Initial play request
    _ytController?.playVideo();
    
    setState(() {});
  }

  void _initializePlayer(String url) {
    final uri = Uri.parse(url);
    _controller = VideoPlayerController.networkUrl(uri)
      ..initialize().then((_) {
        if (mounted) {
          _controller?.setVolume(0.0); // Start muted to guarantee autoplay works on web zapping
          setState(() {});
          _controller?.play(); // Autoplay
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = error.toString();
          });
        }
      });
  }

  void _nextChannel() {
    if (widget.channels.isEmpty) return;
    final currentIndex = widget.channels.indexWhere((c) => c.id == _currentChannel.id);
    if (currentIndex == -1) return;
    final nextIndex = (currentIndex + 1) % widget.channels.length;
    _loadChannel(widget.channels[nextIndex]);
  }

  void _previousChannel() {
    if (widget.channels.isEmpty) return;
    final currentIndex = widget.channels.indexWhere((c) => c.id == _currentChannel.id);
    if (currentIndex == -1) return;
    final prevIndex = (currentIndex - 1 + widget.channels.length) % widget.channels.length;
    _loadChannel(widget.channels[prevIndex]);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    _focusNode.dispose();
    _controller?.dispose();
    _ytController?.close();
    _zapHUDTimer?.cancel();
    
    // Dispose preloaded controllers to prevent memory leaks
    for (final preloaded in _preloadedControllers.values) {
      preloaded.dispose();
    }
    _preloadedControllers.clear();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = _isYoutube 
        ? _ytController != null 
        : (_controller != null && _controller!.value.isInitialized);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
            // Video Player Area
            Center(
              child: _hasError
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          _isYoutube ? 'Error de YouTube' : 'No se pudo reproducir este canal',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            _isYoutube 
                                ? 'La URL de YouTube ingresada no es válida o el video no está disponible.'
                                : 'Verifica la URL del canal o los formatos de reproducción soportados por el navegador.',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : isInitialized
                      ? _isYoutube
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: YoutubePlayer(
                                    key: ValueKey(_currentChannel.id),
                                    controller: _ytController!,
                                  ),
                                ),
                                // Transparent overlay that captures clicks and prevents YouTube iframe from stealing keyboard focus
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      _focusNode.requestFocus(); // Reclaim keyboard focus
                                      if (_ytController != null) {
                                        _ytController!.unMute();
                                        _ytController!.setVolume(_volumePercent);
                                        _ytController!.playVideo(); // Enforce play if blocked
                                        setState(() {
                                          _isMuted = false;
                                          _showZapHUD = true;
                                        });
                                        _zapHUDTimer?.cancel();
                                        _zapHUDTimer = Timer(const Duration(milliseconds: 2000), () {
                                          if (mounted) setState(() => _showZapHUD = false);
                                        });
                                      }
                                    },
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ],
                            )
                          : AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: VideoPlayer(
                                _controller!,
                                key: ValueKey(_currentChannel.id),
                              ),
                            )
                      : const CircularProgressIndicator(),
            ),
            
            // Unified Muted Banner overlay
            if (isInitialized && !_hasError && _isMuted)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_off, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Haz clic para activar el sonido',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Video controls overlay (Play/Pause when initialized, for non-youtube streams only)
            if (!_isYoutube && isInitialized && !_hasError)
               Positioned.fill(
                 child: GestureDetector(
                   onTap: () {
                     _focusNode.requestFocus(); // Reclaim keyboard focus
                     if (_isMuted) {
                       _controller?.setVolume(_volumePercent / 100.0);
                       setState(() {
                         _isMuted = false;
                         _showZapHUD = true;
                       });
                       _zapHUDTimer?.cancel();
                       _zapHUDTimer = Timer(const Duration(milliseconds: 2000), () {
                         if (mounted) setState(() => _showZapHUD = false);
                       });
                     } else {
                       setState(() {
                         if (_controller!.value.isPlaying) {
                           _controller!.pause();
                         } else {
                           _controller!.play();
                         }
                       });
                     }
                   },
                   child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: (_controller!.value.isPlaying && !_isMuted) ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            _isMuted 
                                ? Icons.volume_off
                                : (_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Back button custom over the video
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            
            // Channel Watermark and Info
            Positioned(
              top: 16,
              right: 16,
              child: const Opacity(
                opacity: 0.5,
                child: Text(
                  'TAJAMAR TV+',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            // Zap HUD (overlay showing current channel info during zapping)
            if (_showZapHUD)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentChannel.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentChannel.categoryId.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Volume HUD (Volume indicator displayed on change)
            if (_showVolumeHUD)
              Positioned(
                top: 80,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _volumePercent == 0
                            ? Icons.volume_mute
                            : _volumePercent < 40
                                ? Icons.volume_down
                                : Icons.volume_up,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Volumen: $_volumePercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Left Navigation Arrow (Previous Channel)
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                      onPressed: () {
                        _focusNode.requestFocus();
                        _previousChannel();
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Right Navigation Arrow (Next Channel)
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                      onPressed: () {
                        _focusNode.requestFocus();
                        _nextChannel();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
