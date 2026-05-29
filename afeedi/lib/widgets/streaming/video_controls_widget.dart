import 'package:flutter/material.dart';
import '../../models/content_model.dart';
import '../../services/browser_streaming_service.dart';
import '../../services/analytics_service.dart';
import 'quality_selector_widget.dart';

class VideoControlsWidget extends StatefulWidget {
  final StreamingPlayer? player;
  final Content content;
  final bool isMobile;
  final VoidCallback? onFullscreen;
  final Function(String)? onQualityChanged;
  final Function(double)? onProgress;
  
  const VideoControlsWidget({
    super.key,
    required this.player,
    required this.content,
    this.isMobile = false,
    this.onFullscreen,
    this.onQualityChanged,
    this.onProgress,
  });
  
  @override
  State<VideoControlsWidget> createState() => _VideoControlsWidgetState();
}

class _VideoControlsWidgetState extends State<VideoControlsWidget> {
  bool _isPlaying = false;
  double _currentTime = 0.0;
  double _duration = 0.0;
  double _volume = 1.0;
  bool _isMuted = false;
  bool _showVolumeSlider = false;
  String _currentQuality = '720p';
  bool _showQualitySelector = false;
  
  @override
  void initState() {
    super.initState();
    _updatePlayerState();
  }
  
  void _updatePlayerState() {
    if (widget.player != null) {
      setState(() {
        _isPlaying = widget.player!.isPlaying;
        _currentTime = widget.player!.currentTime;
        _duration = widget.player!.duration;
        _currentQuality = widget.player!.currentQuality;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            _buildProgressBar(),
            
            // Control buttons
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressBar() {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          activeTrackColor: Colors.red,
          inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
          thumbColor: Colors.red,
          overlayColor: Colors.red.withValues(alpha: 0.2),
        ),
        child: Slider(
          value: _duration > 0 ? _currentTime / _duration : 0.0,
          onChanged: (value) {
            final newTime = value * _duration;
            setState(() {
              _currentTime = newTime;
            });
            widget.player?.seekTo(newTime);
            widget.onProgress?.call(value);
            
            AnalyticsService.instance.trackUserInteraction(
              action: 'video_seeked',
              screen: 'video_player',
              additionalData: {
                'content_id': widget.content.id,
                'seek_position': newTime,
                'seek_percentage': value,
              },
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Play/Pause button
          _buildPlayPauseButton(),
          
          const SizedBox(width: 16),
          
          // Time display
          _buildTimeDisplay(),
          
          const Spacer(),
          
          // Volume control (desktop only)
          if (!widget.isMobile) ...<Widget>[
            _buildVolumeControl(),
            const SizedBox(width: 16),
          ],
          
          // Quality selector
          _buildQualityButton(),
          
          const SizedBox(width: 16),
          
          // Fullscreen button
          _buildFullscreenButton(),
        ],
      ),
    );
  }
  
  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTap: () async {
        if (widget.player != null) {
          if (_isPlaying) {
            await widget.player!.pause();
          } else {
            await widget.player!.play();
          }
          _updatePlayerState();
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.black,
          size: 24,
        ),
      ),
    );
  }
  
  Widget _buildTimeDisplay() {
    return Text(
      '${_formatTime(_currentTime)} / ${_formatTime(_duration)}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
  
  Widget _buildVolumeControl() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isMuted = !_isMuted;
            });
            
            AnalyticsService.instance.trackUserInteraction(
              action: _isMuted ? 'video_muted' : 'video_unmuted',
              screen: 'video_player',
              additionalData: {
                'content_id': widget.content.id,
              },
            );
          },
          child: Icon(
            _isMuted ? Icons.volume_off : Icons.volume_up,
            color: Colors.white,
            size: 24,
          ),
        ),
        if (_showVolumeSlider) ...<Widget>[
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _isMuted ? 0.0 : _volume,
                onChanged: (value) {
                  setState(() {
                    _volume = value;
                    _isMuted = value == 0.0;
                  });
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildQualityButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showQualitySelector = !_showQualitySelector;
        });
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _currentQuality,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_showQualitySelector)
            Positioned(
              bottom: 30,
              right: 0,
              child: QualitySelectorWidget(
                currentQuality: _currentQuality,
                availableQualities: const ['1080p', '720p', '480p', '360p'],
                onQualitySelected: (quality) {
                  setState(() {
                    _currentQuality = quality;
                    _showQualitySelector = false;
                  });
                  
                  widget.player?.setQuality(quality);
                  widget.onQualityChanged?.call(quality);
                  
                  AnalyticsService.instance.trackUserInteraction(
                    action: 'video_quality_changed',
                    screen: 'video_player',
                    additionalData: {
                      'content_id': widget.content.id,
                      'new_quality': quality,
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildFullscreenButton() {
    return GestureDetector(
      onTap: widget.onFullscreen,
      child: const Icon(
        Icons.fullscreen,
        color: Colors.white,
        size: 24,
      ),
    );
  }
  
  String _formatTime(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}

// Mini video controls for mobile
class MiniVideoControls extends StatelessWidget {
  final StreamingPlayer? player;
  final Content content;
  final VoidCallback? onFullscreen;
  
  const MiniVideoControls({
    super.key,
    required this.player,
    required this.content,
    this.onFullscreen,
  });
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMiniButton(
            icon: Icons.fullscreen,
            onTap: onFullscreen,
          ),
          const SizedBox(height: 8),
          _buildMiniButton(
            icon: player?.isPlaying == true ? Icons.pause : Icons.play_arrow,
            onTap: () async {
              if (player != null) {
                if (player!.isPlaying) {
                  await player!.pause();
                } else {
                  await player!.play();
                }
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildMiniButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}