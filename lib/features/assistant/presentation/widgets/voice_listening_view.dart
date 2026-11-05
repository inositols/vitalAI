import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

/// Fullscreen listening state view matching Screen 3 in the concept image.
/// Displays pulsing radial waves, audio equalizer bars, editable speech bubble,
/// Stop button and Cancel action.
class VoiceListeningView extends StatefulWidget {
  final String transcript;
  final bool isListening;
  final VoidCallback onStop;
  final VoidCallback onCancel;
  final Function(String newText)? onTranscriptChanged;

  const VoiceListeningView({
    super.key,
    required this.transcript,
    required this.isListening,
    required this.onStop,
    required this.onCancel,
    this.onTranscriptChanged,
  });

  @override
  State<VoiceListeningView> createState() => _VoiceListeningViewState();
}

class _VoiceListeningViewState extends State<VoiceListeningView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late TextEditingController _transcriptController;
  bool _isEditingTranscript = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _transcriptController = TextEditingController(text: widget.transcript);
  }

  @override
  void didUpdateWidget(covariant VoiceListeningView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingTranscript && widget.transcript != oldWidget.transcript) {
      _transcriptController.text = widget.transcript;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: const SizedBox(width: 48), // Spacer to balance close button
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.subtleTealBorder,
                  width: 1.0,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/vitalai_logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.primary,
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VoiceVitals',
                  style: AppTypography.titleMedium(
                    color: isDark ? Colors.white : AppColors.secondary,
                  ),
                ),
                Text(
                  'Clinical Workspace',
                  style: AppTypography.labelSmall(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            color: isDark ? Colors.white : AppColors.secondary,
            onPressed: widget.onCancel,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // 1. Concentric Radial Wave Mic Centerpiece
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Pulsing Ring 2
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final val = _pulseController.value;
                        return Container(
                          width: 140 + (val * 70),
                          height: 140 + (val * 70),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(
                              alpha: (0.12 * (1.0 - val)).clamp(0.0, 0.2),
                            ),
                          ),
                        );
                      },
                    ),
                    // Outer Pulsing Ring 1
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final val = (_pulseController.value + 0.5) % 1.0;
                        return Container(
                          width: 130 + (val * 50),
                          height: 130 + (val * 50),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(
                              alpha: (0.18 * (1.0 - val)).clamp(0.0, 0.25),
                            ),
                          ),
                        );
                      },
                    ),
                    // Primary Teal Mic Circle
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. Status Text
              Text(
                'Listening...',
                style: AppTypography.displaySmall(
                  color: isDark ? Colors.white : AppColors.secondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Speak clearly and naturally',
                style: AppTypography.bodyMedium(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // 3. Audio Equalizer Waveform Bars
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(24, (idx) {
                      final waveOffset = (idx * 0.25) + (_waveController.value * 3.14);
                      final normalized = (0.3 + 0.7 * (0.5 + 0.5 * (waveOffset % 2.0 - 1.0).abs()));
                      final height = (idx == 0 || idx == 23)
                          ? 6.0
                          : (8.0 + (normalized * 28.0));

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 3.5,
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: 0.4 + (0.6 * normalized).clamp(0.0, 1.0),
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  );
                },
              ),

              const Spacer(flex: 1),

              // 4. Recognized Speech Transcript Bubble (Editable)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Soundwave Icon
                    const Icon(
                      Icons.graphic_eq_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),

                    // Transcript Text / TextField
                    Expanded(
                      child: _isEditingTranscript
                          ? TextField(
                              controller: _transcriptController,
                              autofocus: true,
                              style: AppTypography.bodyMedium(
                                color: isDark ? Colors.white : AppColors.secondary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (val) {
                                setState(() => _isEditingTranscript = false);
                                widget.onTranscriptChanged?.call(val);
                              },
                            )
                          : Text(
                              _transcriptController.text.isNotEmpty
                                  ? _transcriptController.text
                                  : 'Listening to your request...',
                              style: AppTypography.bodyMedium(
                                color: isDark ? Colors.white : AppColors.secondary,
                              ),
                            ),
                    ),

                    // Pencil Edit Button
                    IconButton(
                      icon: Icon(
                        _isEditingTranscript ? Icons.check_rounded : Icons.edit_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditingTranscript = !_isEditingTranscript;
                        });
                        if (!_isEditingTranscript) {
                          widget.onTranscriptChanged?.call(_transcriptController.text);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. Red "Stop" Button
              SizedBox(
                width: 130,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(
                    Icons.stop_rounded,
                    color: AppColors.error,
                    size: 22,
                  ),
                  label: const Text(
                    'Stop',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                    backgroundColor: const Color(0xFFFFF1F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    if (_isEditingTranscript) {
                      widget.onTranscriptChanged?.call(_transcriptController.text);
                    }
                    widget.onStop();
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 6. Cancel Action
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  'Cancel',
                  style: AppTypography.labelMedium(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
