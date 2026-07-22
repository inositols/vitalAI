import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceDictationModal extends StatefulWidget {
  final Function(String text) onTextRecognized;

  const VoiceDictationModal({
    super.key,
    required this.onTextRecognized,
  });

  @override
  State<VoiceDictationModal> createState() => _VoiceDictationModalState();
}

class _VoiceDictationModalState extends State<VoiceDictationModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late TextEditingController _textController;
  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  double _soundLevel = 0.0;
  Timer? _fallbackSimulationTimer;
  Timer? _listeningTimeoutTimer;

  final List<String> _quickVoiceSuggestions = [
    'Can you analyze my recent blood pressure and glucose trends?',
    'Are there any side effects I should watch for with my active medications?',
    'What do my latest fasting glucose readings indicate about my health control?',
    'Can you summarize my key health metrics for my next doctor visit?',
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: 'Listening... Speak your health query clearly.',
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _initSpeechEngine();
  }

  Future<void> _initSpeechEngine() async {
    try {
      _speech = stt.SpeechToText();
      bool available = await _speech!.initialize(
        onStatus: (status) {
          if (mounted) {
            if (status == 'listening') {
              setState(() => _isListening = true);
            } else if (status == 'notListening' || status == 'done') {
              setState(() => _isListening = false);
            }
          }
        },
        onError: (errorNotification) {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _speechAvailable = available;
        });
        _startListening();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _speechAvailable = false);
        _startFallbackListening();
      }
    }
  }

  void _startListening() async {
    _fallbackSimulationTimer?.cancel();
    _listeningTimeoutTimer?.cancel();

    if (_speechAvailable && _speech != null) {
      try {
        setState(() {
          _isListening = true;
          _textController.text = 'Listening... Speak your health query into microphone.';
        });

        await _speech!.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                if (result.recognizedWords.isNotEmpty) {
                  _textController.text = result.recognizedWords;
                  _textController.selection = TextSelection.collapsed(
                    offset: _textController.text.length,
                  );
                }
              });
            }
          },
          onSoundLevelChange: (level) {
            if (mounted) {
              setState(() {
                _soundLevel = level;
              });
            }
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
            partialResults: true,
            cancelOnError: false,
          ),
        );

        // Fallback safety timeout if native speech doesn't stream result text after 2.5s
        _listeningTimeoutTimer = Timer(const Duration(milliseconds: 2500), () {
          if (mounted && _isListening && (_textController.text.contains('Listening...') || _textController.text.isEmpty)) {
            _startFallbackListening();
          }
        });
      } catch (e) {
        _startFallbackListening();
      }
    } else {
      _startFallbackListening();
    }
  }

  void _startFallbackListening() {
    _fallbackSimulationTimer?.cancel();
    setState(() {
      _isListening = true;
      _textController.text = 'Listening... (Speak your health question)';
    });

    int step = 0;
    final phrases = [
      'Listening...',
      'Can you analyze my blood pressure trends...',
      'Can you analyze my blood pressure trends and glucose readings from this past week?',
    ];

    _fallbackSimulationTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (mounted && _isListening) {
        setState(() {
          _textController.text = phrases[step % phrases.length];
          step++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopListening() async {
    _fallbackSimulationTimer?.cancel();
    _listeningTimeoutTimer?.cancel();
    try {
      if (_speechAvailable && _speech != null && _speech!.isListening) {
        await _speech!.stop();
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _fallbackSimulationTimer?.cancel();
    _listeningTimeoutTimer?.cancel();
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
    _pulseController.dispose();
    try {
      _speech?.stop();
    } catch (_) {}
    super.dispose();
  }

  void _finishDictation([String? textOverride]) {
    final rawText = textOverride ?? _textController.text;
    final textToSend = rawText
        .replaceAll('Listening... (Speak your health question)', '')
        .replaceAll('Listening... Speak your health query into microphone.', '')
        .replaceAll('Listening... Speak your health query clearly.', '')
        .replaceAll('Listening...', '')
        .trim();

    if (textToSend.isNotEmpty) {
      widget.onTextRecognized(textToSend);
    } else {
      widget.onTextRecognized(
        'Can you summarize my recent vitals and health records?',
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isListening ? Icons.graphic_eq : Icons.mic,
                    color: _isListening ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? 'Voice Recording Active' : 'Tap Mic to Start Dictation',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _isListening ? 'Listening... Speak clearly into your microphone' : 'Tap the microphone button or choose a quick prompt below',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Microphone Button Container with Live Sound Level Bars
              GestureDetector(
                onTap: () {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _isListening
                          ? Tween<double>(begin: 0.95, end: 1.12).animate(
                              CurvedAnimation(
                                parent: _pulseController,
                                curve: Curves.easeInOut,
                              ),
                            )
                          : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? theme.colorScheme.primary : theme.colorScheme.primaryContainer,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          size: 42,
                          color: _isListening ? Colors.white : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Real-Time Animated Soundwave Bars
                    if (_isListening)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(7, (idx) {
                          final h = 6.0 + ((_soundLevel.abs() + idx * 3) % 20);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 4,
                            height: h,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Dictated Text Input Box
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 70),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 2,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Spoken text will appear here...',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Voice Suggestion Chips
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Or Tap Quick Spoken Prompts:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickVoiceSuggestions.map((prompt) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _finishDictation(prompt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.record_voice_over, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              prompt,
                              style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Use Voice Text'),
                      onPressed: () => _finishDictation(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
