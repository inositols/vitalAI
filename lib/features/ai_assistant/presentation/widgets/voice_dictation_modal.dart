import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/extensions/build_context_ext.dart';

class VoiceDictationModal extends StatefulWidget {
  final Function(String text) onTextRecognized;

  const VoiceDictationModal({super.key, required this.onTextRecognized});

  @override
  State<VoiceDictationModal> createState() => _VoiceDictationModalState();
}

class _VoiceDictationModalState extends State<VoiceDictationModal> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late TextEditingController _textController;
  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  double _soundLevel = 0.0;
  String _statusMessage = 'Initializing microphone...';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _initSpeechEngine();
  }

  Future<void> _initSpeechEngine() async {
    try {
      _speech = stt.SpeechToText();
      bool available = await _speech!.initialize(
        onStatus: (status) {
          if (mounted) {
            setState(() {
              _isListening = status == 'listening';
              _statusMessage = _isListening ? 'Listening... Speak into microphone' : 'Tap mic button to listen';
            });
          }
        },
        onError: (err) {
          if (mounted) setState(() { _isListening = false; _statusMessage = 'Speech error: ${err.errorMsg}'; });
        },
      );
      if (mounted) {
        setState(() {
          _speechAvailable = available;
          _statusMessage = available ? 'Microphone ready.' : 'Speech recognition unavailable.';
          if (available) _startListening();
        });
      }
    } catch (e) {
      if (mounted) setState(() { _speechAvailable = false; _statusMessage = 'Permission/engine error: $e'; });
    }
  }

  void _startListening() async {
    if (_speech == null) return;
    if (!_speechAvailable) { await _initSpeechEngine(); return; }
    try {
      setState(() { _isListening = true; _statusMessage = 'Listening... Speak now'; });
      await _speech!.listen(
        onResult: (res) {
          if (mounted) {
            setState(() {
              _textController.text = res.recognizedWords;
              _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
            });
          }
        },
        onSoundLevelChange: (lvl) { if (mounted) setState(() => _soundLevel = lvl); },
        listenOptions: stt.SpeechListenOptions(listenMode: stt.ListenMode.dictation, partialResults: true),
      );
    } catch (e) {
      if (mounted) setState(() { _isListening = false; _statusMessage = 'Error: $e'; });
    }
  }

  void _stopListening() async {
    try { if (_speech != null && _speech!.isListening) await _speech!.stop(); } catch (_) {}
    if (mounted) setState(() { _isListening = false; _soundLevel = 0.0; _statusMessage = 'Tap mic to listen'; });
  }

  @override
  void dispose() {
    _textController.dispose();
    if (_pulseController.isAnimating) _pulseController.stop();
    _pulseController.dispose();
    try { _speech?.stop(); } catch (_) {}
    super.dispose();
  }

  void _finishDictation() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) widget.onTextRecognized(text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: context.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isListening ? Icons.graphic_eq : Icons.mic, color: _isListening ? context.colorScheme.primary : context.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(_isListening ? 'Voice Assistant Active' : 'Speech Dictation', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(_statusMessage, textAlign: TextAlign.center, style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _isListening ? Tween<double>(begin: 0.95, end: 1.12).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)) : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _isListening ? context.colorScheme.primary : context.colorScheme.primaryContainer),
                        child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 42, color: _isListening ? Colors.white : context.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isListening)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(7, (idx) {
                          final h = 6.0 + ((_soundLevel.abs() + idx * 3) % 20);
                          return Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 4, height: h, decoration: BoxDecoration(color: context.colorScheme.primary, borderRadius: BorderRadius.circular(2)));
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16)),
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 2,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.4),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Spoken text will appear here...'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.send_rounded), label: const Text('Use Voice Text'), onPressed: _finishDictation)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
