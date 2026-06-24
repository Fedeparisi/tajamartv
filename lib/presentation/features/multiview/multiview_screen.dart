import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/channel_entity.dart';
import '../admin/providers/channel_admin_provider.dart';
import '../player/player_screen.dart';

class MultiViewScreen extends ConsumerStatefulWidget {
  final int gridCount;

  const MultiViewScreen({
    super.key,
    required this.gridCount,
  });

  @override
  ConsumerState<MultiViewScreen> createState() => _MultiViewScreenState();
}

class _MultiViewScreenState extends ConsumerState<MultiViewScreen> {
  final List<VideoPlayerController?> _videoControllers = [];
  final List<YoutubePlayerController?> _ytControllers = [];
  final List<bool> _isYoutubeList = [];
  final List<bool> _isInitializedList = [];
  
  int _unmutedIndex = -1; // Index of the channel with audio enabled
  bool _controllersInitialized = false;
  List<ChannelEntity> _activeChannels = [];

  @override
  void dispose() {
    _cleanupControllers();
    super.dispose();
  }

  void _cleanupControllers() {
    for (final controller in _videoControllers) {
      controller?.dispose();
    }
    for (final controller in _ytControllers) {
      controller?.close().catchError((e) {});
    }
    _videoControllers.clear();
    _ytControllers.clear();
    _isYoutubeList.clear();
    _isInitializedList.clear();
  }

  void _initializeControllers(List<ChannelEntity> channels) {
    if (_controllersInitialized) return;
    _controllersInitialized = true;
    _activeChannels = channels;

    // We take up to widget.gridCount channels. If there are fewer channels, we repeat them.
    final List<ChannelEntity> selectedChannels = [];
    if (channels.isNotEmpty) {
      for (int i = 0; i < widget.gridCount; i++) {
        selectedChannels.add(channels[i % channels.length]);
      }
    }

    for (int i = 0; i < selectedChannels.length; i++) {
      final channel = selectedChannels[i];
      final isYt = channel.streamType.toLowerCase() == 'youtube' ||
          channel.url.contains('youtube.com') ||
          channel.url.contains('youtu.be');

      _isYoutubeList.add(isYt);
      _isInitializedList.add(false);

      if (isYt) {
        _videoControllers.add(null);
        final videoId = _extractYoutubeId(channel.url);
        if (videoId != null) {
          final index = i;
          final ytController = YoutubePlayerController.fromVideoId(
            videoId: videoId,
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
                _ytControllers[index]?.playVideo();
              }
              if (value.playerState == PlayerState.playing && mounted) {
                if (!_isInitializedList[index]) {
                  setState(() {
                    _isInitializedList[index] = true;
                  });
                }
              }
            });
          _ytControllers.add(ytController);
          ytController.playVideo();
        } else {
          _ytControllers.add(null);
        }
      } else {
        _ytControllers.add(null);
        if (channel.url.isNotEmpty) {
          final index = i;
          final controller = VideoPlayerController.networkUrl(Uri.parse(channel.url));
          _videoControllers.add(controller);
          controller.initialize().then((_) {
            if (mounted) {
              controller.setVolume(0.0);
              controller.setLooping(true);
              controller.play();
              setState(() {
                _isInitializedList[index] = true;
              });
            } else {
              controller.dispose();
            }
          }).catchError((_) {
            // Ignore preview grid load errors
          });
        } else {
          _videoControllers.add(null);
        }
      }
    }
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

  void _toggleMute(int index) {
    setState(() {
      if (_unmutedIndex == index) {
        // Mute current
        _unmuteChannel(index, false);
        _unmutedIndex = -1;
      } else {
        // Mute old unmuted
        if (_unmutedIndex != -1) {
          _unmuteChannel(_unmutedIndex, false);
        }
        // Unmute new
        _unmuteChannel(index, true);
        _unmutedIndex = index;
      }
    });
  }

  void _unmuteChannel(int index, bool unmute) {
    if (index < 0 || index >= _isYoutubeList.length) return;
    if (_isYoutubeList[index]) {
      final yt = _ytControllers[index];
      if (yt != null) {
        if (unmute) {
          yt.unMute();
          yt.setVolume(100);
        } else {
          yt.mute();
        }
      }
    } else {
      final video = _videoControllers[index];
      if (video != null && video.value.isInitialized) {
        video.setVolume(unmute ? 1.0 : 0.0);
      }
    }
  }

  int _calculateCrossAxisCount() {
    final count = widget.gridCount;
    if (count <= 4) return 2;
    if (count <= 8) return 4;
    if (count <= 10) return 5;
    if (count <= 12) return 4;
    return 4; // default for 16 is 4x4
  }

  double _calculateAspectRatio() {
    final count = widget.gridCount;
    if (count == 6) return 16 / 10;
    if (count == 10) return 16 / 10;
    return 16 / 9;
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Mosaico Multi-Pantalla (${widget.gridCount} Canales)',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Toca un canal para escuchar • Doble clic para pantalla completa',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (channels) {
          if (channels.isEmpty) {
            return const Center(
              child: Text('No hay canales disponibles para el mosaico.', style: TextStyle(color: Colors.white)),
            );
          }

          _initializeControllers(channels);
          
          final List<ChannelEntity> selectedChannels = [];
          for (int i = 0; i < widget.gridCount; i++) {
            selectedChannels.add(channels[i % channels.length]);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _calculateCrossAxisCount(),
              childAspectRatio: _calculateAspectRatio(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: selectedChannels.length,
            itemBuilder: (context, index) {
              final channel = selectedChannels[index];
              final isInitialized = _isInitializedList[index];
              final isAudioOn = _unmutedIndex == index;

              return GestureDetector(
                onTap: () => _toggleMute(index),
                onDoubleTap: () {
                  _cleanupControllers();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        channel: channel,
                        channels: channels,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAudioOn ? AppColors.secondary : Colors.white12,
                      width: isAudioOn ? 3.0 : 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Stack(
                      children: [
                        // Video Player
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _isYoutubeList[index]
                                ? (_ytControllers[index] != null
                                    ? FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: 320,
                                          height: 180,
                                          child: YoutubePlayer(
                                            controller: _ytControllers[index]!,
                                          ),
                                        ),
                                      )
                                    : const SizedBox())
                                : (_videoControllers[index] != null &&
                                        _videoControllers[index]!.value.isInitialized
                                    ? FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _videoControllers[index]!.value.size.width,
                                          height: _videoControllers[index]!.value.size.height,
                                          child: VideoPlayer(_videoControllers[index]!),
                                        ),
                                      )
                                    : const SizedBox()),
                          ),
                        ),

                        // Placeholder if not initialized
                        if (!isInitialized)
                          Positioned.fill(
                            child: Image.network(
                              channel.logo.startsWith('assets/') ? '' : channel.logo,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.black,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ),

                        // Dark vignette and channel details
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black87],
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    channel.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  isAudioOn ? Icons.volume_up : Icons.volume_off,
                                  color: isAudioOn ? AppColors.secondary : Colors.white60,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Focus indicators
                        if (isAudioOn)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AUDIO ACTIVO',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
