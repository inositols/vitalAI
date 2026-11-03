import 'package:flutter/material.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/services/ai_audio_service.dart';
import '../../../../core/theme/design_tokens.dart';

/// Interactive audio player bar with equalizer wave animation,
/// playback progress, speed control, and play/pause/stop actions.
class AiAudioPlaybackBar extends StatefulWidget {
  final AudioPlaybackState playbackState;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final Function(double speed) onSpeedChanged;

  const AiAudioPlaybackBar({
    super.key,
    required this.playbackState,
    required this.onPlayPause,
    required this.onStop,
    required this.onSpeedChanged,
  });

  @override
  State<AiAudioPlaybackBar> createState() => _AiAudioPlaybackBarState();
}

class _AiAudioPlaybackBarState extends State<AiAudioPlaybackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.playbackState.isPlaying) {
      _waveController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AiAudioPlaybackBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playbackState.isPlaying && !_waveController.isAnimating) {
      _waveController.repeat(reverse: true);
    } else if (!widget.playbackState.isPlaying && _waveController.isAnimating) {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _cycleSpeed() {
    final currentSpeed = widget.playbackState.speechRate;
    // Map speechRate (0.4 - 0.7) to human display or use explicit speed values
    // In FlutterTts, 0.5 is approximately 1.0x normal voice.
    int nextIdx = 0;
    if (currentSpeed <= 0.4) {
      nextIdx = 1; // 1.0x (0.5)
    } else if (currentSpeed <= 0.52) {
      nextIdx = 2; // 1.25x (0.6)
    } else if (currentSpeed <= 0.65) {
      nextIdx = 3; // 1.5x (0.75)
    } else {
      nextIdx = 0; // 0.8x (0.4)
    }

    final double newRate;
    switch (nextIdx) {
      case 0:
        newRate = 0.4; // 0.8x
        break;
      case 1:
        newRate = 0.5; // 1.0x
        break;
      case 2:
        newRate = 0.6; // 1.25x
        break;
      case 3:
      default:
        newRate = 0.75; // 1.5x
        break;
    }
    widget.onSpeedChanged(newRate);
  }

  String _formatSpeedLabel(double rate) {
    if (rate <= 0.42) return '0.8x';
    if (rate <= 0.55) return '1.0x';
    if (rate <= 0.68) return '1.25x';
    return '1.5x';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isPlaying = widget.playbackState.isPlaying;
    final progress = widget.playbackState.progress.clamp(0.0, 1.0);
    final speedLabel = _formatSpeedLabel(widget.playbackState.speechRate);

    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.tertiary.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 1. Play / Pause Button
              InkWell(
                onTap: widget.onPlayPause,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Animated Sound Wave / Equalizer
              _buildEqualizer(isDark),
              const SizedBox(width: 10),

              // 3. Status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPlaying ? 'Reading response aloud...' : 'Audio playback paused',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'AI Voice Assistant',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Speed Pill Chip
              InkWell(
                onTap: _cycleSpeed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    speedLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 5. Stop Button
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Stop audio',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                onPressed: widget.onStop,
              ),
            ],
          ),

          // Progress Bar
          if (progress > 0.0) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2.5,
                backgroundColor: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPlaying ? AppColors.tertiary : AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEqualizer(bool isDark) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final val = _waveController.value;
        // 4 equalizer bars of different phase heights
        final heights = [
          8.0 + (val * 10.0),
          14.0 - (val * 8.0),
          6.0 + ((1.0 - val) * 12.0),
          12.0 + (val * 6.0),
        ];

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: widget.playbackState.isPlaying ? heights[index] : 4.0,
              decoration: BoxDecoration(
                color: widget.playbackState.isPlaying
                    ? AppColors.tertiary
                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}
