import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import '../../../domain/entities/channel_entity.dart';
import '../../../core/constants/app_colors.dart';
import '../admin/providers/channel_admin_provider.dart';
import '../admin/widgets/edit_channel_dialog.dart';
import '../../../app/router/app_router.dart';
import 'fullscreen_utils.dart';

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
  late List<ChannelEntity> _channelsList;
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
  bool _isFullscreen = false;

  bool _isHoveringLeftArrow = false;
  bool _isHoveringRightArrow = false;

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    _channelsList = List.from(widget.channels);
    
    // Register global keyboard listener to capture keys before they get intercepted
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
    
    // Register listener for native browser fullscreen changes
    registerFullscreenListener((isFullscreen) {
      if (mounted) {
        setState(() {
          _isFullscreen = isFullscreen;
        });
      }
    });

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
        _controller?.setVolume((_volumePercent / 100.0 * _currentChannel.volumeFactor).clamp(0.0, 1.0));
      }
    }

    setState(() {
      _volumePercent = (_volumePercent + delta).clamp(0, 100);
      _showVolumeHUD = true;
    });

    if (_isYoutube) {
      _ytController?.setVolume((_volumePercent * _currentChannel.volumeFactor).round().clamp(0, 100));
    } else {
      _controller?.setVolume((_volumePercent / 100.0 * _currentChannel.volumeFactor).clamp(0.0, 1.0));
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
    
    final playAsNativeYoutube = nextIsYoutube && !kIsWeb && Platform.isWindows;

    setState(() {
      _currentChannel = channel;
      _hasError = false;
      _errorMessage = '';
      _isYoutube = nextIsYoutube && !playAsNativeYoutube;
      
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
      if (playAsNativeYoutube) {
        if (_ytController != null) {
          _ytController!.close().catchError((e) {});
          _ytController = null;
        }
        _controller?.dispose();
        _controller = null;
        _initializeYoutubePlayerWindows(channel.url);
      } else {
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
          _ytController!.close().catchError((e) {});
          _ytController = null;
        }
        _controller?.dispose();
        _controller = null;
        _initializeYoutubePlayer(channel.url);
      }
    } else {
      // Clean up YouTube player if zapping to normal channel
      if (_ytController != null) {
        _ytController!.close().catchError((e) {});
        _ytController = null;
      }
      
      // Speed check: Check if we have preloaded the controller for this channel
      if (_preloadedControllers.containsKey(channel.id)) {
        final preloaded = _preloadedControllers[channel.id]!;
        _controller?.dispose(); // Dispose old controller
        _controller = preloaded;
        _preloadedControllers.remove(channel.id); // Active, remove from cache list
        
        if (_controller!.value.isInitialized) {
          _controller!.setVolume(_isMuted ? 0.0 : (_volumePercent / 100.0 * channel.volumeFactor).clamp(0.0, 1.0));
          _controller!.play();
          setState(() {});
        } else {
          // If in the middle of initializing, wait and play
          _controller!.initialize().then((_) {
            if (mounted && _currentChannel.id == channel.id) {
              _controller?.setVolume(_isMuted ? 0.0 : (_volumePercent / 100.0 * channel.volumeFactor).clamp(0.0, 1.0));
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
    if (_channelsList.isEmpty) return;
    final currentIndex = _channelsList.indexWhere((c) => c.id == _currentChannel.id);
    if (currentIndex == -1) return;

    final nextIndex = (currentIndex + 1) % _channelsList.length;
    final prevIndex = (currentIndex - 1 + _channelsList.length) % _channelsList.length;

    final nextChannel = _channelsList[nextIndex];
    final prevChannel = _channelsList[prevIndex];

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
        origin: 'https://www.youtube-nocookie.com',
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
      // If we are not muted, make sure YouTube player is unmuted once it starts playing
      if (value.playerState == PlayerState.playing && !_isMuted) {
        _ytController?.unMute();
        _ytController?.setVolume((_volumePercent * _currentChannel.volumeFactor).round().clamp(0, 100));
      }
    });
    
    // Initial play request
    _ytController?.playVideo();
    
    setState(() {});
  }

  Future<void> _initializeYoutubePlayerWindows(String url) async {
    final videoId = _extractYoutubeId(url);
    if (videoId == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No se pudo extraer el ID del video de YouTube';
      });
      return;
    }

    try {
      final yt = yt_explode.YoutubeExplode();
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      // Filter for highest quality muxed stream (video + audio)
      final streamInfo = manifest.muxed.withHighestBitrate();
      final streamUrl = streamInfo.url.toString();
      yt.close();

      _controller = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
      await _controller!.initialize();
      if (mounted && _currentChannel.url == url) {
        _controller!.setVolume(_isMuted ? 0.0 : (_volumePercent / 100.0 * _currentChannel.volumeFactor).clamp(0.0, 1.0));
        _controller!.play();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error al extraer streaming de YouTube: $e';
        });
      }
    }
  }

  void _unmute() {
    _focusNode.requestFocus();
    if (_isYoutube) {
      if (_ytController != null) {
        _ytController!.unMute();
        _ytController!.setVolume((_volumePercent * _currentChannel.volumeFactor).round().clamp(0, 100));
        _ytController!.playVideo();
      }
    } else {
      _controller?.setVolume((_volumePercent / 100.0 * _currentChannel.volumeFactor).clamp(0.0, 1.0));
    }
    setState(() {
      _isMuted = false;
      _showZapHUD = true;
    });
    _zapHUDTimer?.cancel();
    _zapHUDTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _showZapHUD = false);
    });
  }

  void _initializePlayer(String url) {
    final uri = Uri.parse(url);
    _controller = VideoPlayerController.networkUrl(uri)
      ..initialize().then((_) {
        if (mounted) {
          _controller?.setVolume(_isMuted ? 0.0 : (_volumePercent / 100.0 * _currentChannel.volumeFactor).clamp(0.0, 1.0)); // Respect mute state
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
    if (_channelsList.isEmpty) return;
    final currentIndex = _channelsList.indexWhere((c) => c.id == _currentChannel.id);
    if (currentIndex == -1) return;
    final nextIndex = (currentIndex + 1) % _channelsList.length;
    _loadChannel(_channelsList[nextIndex]);
  }

  void _previousChannel() {
    if (_channelsList.isEmpty) return;
    final currentIndex = _channelsList.indexWhere((c) => c.id == _currentChannel.id);
    if (currentIndex == -1) return;
    final prevIndex = (currentIndex - 1 + _channelsList.length) % _channelsList.length;
    _loadChannel(_channelsList[prevIndex]);
  }

  void _confirmDeleteChannel(BuildContext context) {
    // Temporarily exit fullscreen if active to show dialog properly
    final wasFullscreen = _isFullscreen;
    if (wasFullscreen) {
      exitFullScreen();
      setState(() => _isFullscreen = false);
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 12),
              const Text('¿Eliminar Canal?', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar permanentemente el canal "${_currentChannel.name}"? Esta acción no se puede deshacer.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Restore fullscreen if cancelled
                if (wasFullscreen) {
                  enterFullScreen();
                  setState(() => _isFullscreen = true);
                }
              },
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                
                final channelToDelete = _currentChannel;
                
                // Determine if we need to exit or switch channel
                final remainingChannels = _channelsList.where((c) => c.id != channelToDelete.id).toList();
                final shouldExit = remainingChannels.isEmpty;
                
                if (!shouldExit) {
                  // Switch to next channel before deleting to ensure seamless viewing
                  final currentIndex = _channelsList.indexWhere((c) => c.id == channelToDelete.id);
                  if (currentIndex != -1) {
                    final nextIndex = (currentIndex + 1) % _channelsList.length;
                    var targetChannel = _channelsList[nextIndex];
                    if (targetChannel.id == channelToDelete.id) {
                      targetChannel = remainingChannels.first;
                    }
                    _loadChannel(targetChannel);
                  } else {
                    _loadChannel(remainingChannels.first);
                  }
                }
                
                try {
                  // Show loading indicator
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Eliminando canal "${channelToDelete.name}"...'),
                        backgroundColor: Colors.blueAccent,
                      ),
                    );
                  }

                  // Delete the channel
                  await ref.read(channelAdminControllerProvider.notifier).deleteChannel(channelToDelete.id);
                  
                  // Update local copy of channels list on success
                  _channelsList.removeWhere((c) => c.id == channelToDelete.id);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Canal "${channelToDelete.name}" eliminado correctamente.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    
                    if (shouldExit) {
                      Navigator.of(context).pop(); // Exit player screen if no channels left
                    } else {
                      // Restore fullscreen if it was active
                      if (wasFullscreen) {
                        enterFullScreen();
                        setState(() => _isFullscreen = true);
                      }
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar canal: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    // Restore fullscreen on error
                    if (wasFullscreen) {
                      enterFullScreen();
                      setState(() => _isFullscreen = true);
                    }
                  }
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _editChannel(BuildContext context) async {
    final wasFullscreen = _isFullscreen;
    if (wasFullscreen) {
      exitFullScreen();
      setState(() => _isFullscreen = false);
    }

    final updatedChannel = await showDialog<ChannelEntity>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditChannelDialog(channel: _currentChannel),
    );

    if (updatedChannel != null) {
      // Update local copy of channels list
      final index = _channelsList.indexWhere((c) => c.id == updatedChannel.id);
      if (index != -1) {
        _channelsList[index] = updatedChannel;
      }
      _loadChannel(updatedChannel);
    } else {
      // Restore fullscreen if cancelled
      if (wasFullscreen) {
        enterFullScreen();
        setState(() => _isFullscreen = true);
      }
    }
  }

  @override
  void dispose() {
    if (_isFullscreen) {
      exitFullScreen();
    }
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    _focusNode.dispose();
    _controller?.dispose();
    _ytController?.close().catchError((e) {});
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
                                    onTap: _unmute,
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
                  child: GestureDetector(
                    onTap: _unmute,
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
              ),
            
            // Video controls overlay (Play/Pause when initialized, for non-youtube streams only)
            if (!_isYoutube && isInitialized && !_hasError)
               Positioned.fill(
                 child: GestureDetector(
                   onTap: () {
                     _focusNode.requestFocus(); // Reclaim keyboard focus
                     if (_isMuted) {
                       _unmute();
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
            
            // Edit Channel (Admin/SuperAdmin only option)
            if (ref.watch(userRoleProvider) == 'admin' || ref.watch(userRoleProvider) == 'super_admin')
              Positioned(
                top: 16,
                right: 210,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.purple.withOpacity(0.5)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.purpleAccent, size: 28),
                      tooltip: 'Editar Canal',
                      onPressed: () => _editChannel(context),
                    ),
                  ),
                ),
              ),

            // Delete Channel (Admin/SuperAdmin only option)
            if (ref.watch(userRoleProvider) == 'admin' || ref.watch(userRoleProvider) == 'super_admin')
              Positioned(
                top: 16,
                right: 150,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 28),
                      tooltip: 'Eliminar Canal de la lista',
                      onPressed: () => _confirmDeleteChannel(context),
                    ),
                  ),
                ),
              ),
            
            // Channel Watermark and Info
            Positioned(
              top: 16,
              right: 16,
              child: const Opacity(
                opacity: 0.5,
                child: Text(
                  'YouTVPlay',
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
                  onEnter: (_) => setState(() => _isHoveringLeftArrow = true),
                  onExit: (_) => setState(() => _isHoveringLeftArrow = false),
                  child: AnimatedRotation(
                    turns: _isHoveringLeftArrow ? -1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
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
            ),
 
            // Right Navigation Arrow (Next Channel)
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _isHoveringRightArrow = true),
                  onExit: (_) => setState(() => _isHoveringRightArrow = false),
                  child: AnimatedRotation(
                    turns: _isHoveringRightArrow ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
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
            ),

            // Fullscreen Button (Bottom Right)
            Positioned(
              bottom: 16,
              right: 16,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      _focusNode.requestFocus();
                      setState(() {
                        if (_isFullscreen) {
                          exitFullScreen();
                          _isFullscreen = false;
                        } else {
                          enterFullScreen();
                          _isFullscreen = true;
                        }
                      });
                    },
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
