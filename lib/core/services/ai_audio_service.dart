import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Playback status of chat audio / TTS engine.
enum AudioPlaybackStatus {
  idle,
  playing,
  paused,
  stopped,
  error,
}

/// State representation of the active chat audio playback.
class AudioPlaybackState {
  final String? messageId;
  final AudioPlaybackStatus status;
  final double progress;
  final double speechRate;
  final String? errorMessage;

  const AudioPlaybackState({
    this.messageId,
    this.status = AudioPlaybackStatus.idle,
    this.progress = 0.0,
    this.speechRate = 0.5,
    this.errorMessage,
  });

  bool get isPlaying => status == AudioPlaybackStatus.playing;
  bool get isPaused => status == AudioPlaybackStatus.paused;
  bool get isActive => isPlaying || isPaused;

  bool isSpeakingMessage(String id) => messageId == id && isPlaying;
  bool isMessageActive(String id) => messageId == id && isActive;

  AudioPlaybackState copyWith({
    String? messageId,
    AudioPlaybackStatus? status,
    double? progress,
    double? speechRate,
    String? errorMessage,
  }) {
    return AudioPlaybackState(
      messageId: messageId ?? this.messageId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      speechRate: speechRate ?? this.speechRate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Core audio playback and text-to-speech service for VitalAI chat.
/// Features clean clinical text sanitization, multi-turn playback coordination,
/// speed regulation, and responsive audio status broadcasting.
class AiAudioService {
  final FlutterTts _tts;
  final _stateController = StreamController<AudioPlaybackState>.broadcast();

  AudioPlaybackState _currentState = const AudioPlaybackState();
  bool _isInitialized = false;

  AiAudioService({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _init();
  }

  /// Current audio playback state snapshot
  AudioPlaybackState get currentState => _currentState;

  /// Observable broadcast stream for UI components
  Stream<AudioPlaybackState> get stateStream => _stateController.stream;

  Future<void> _init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_currentState.speechRate);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _updateState(_currentState.copyWith(status: AudioPlaybackStatus.playing, progress: 0.0));
      });

      _tts.setCompletionHandler(() {
        _updateState(_currentState.copyWith(
          status: AudioPlaybackStatus.stopped,
          progress: 1.0,
        ));
      });

      _tts.setCancelHandler(() {
        _updateState(_currentState.copyWith(
          status: AudioPlaybackStatus.stopped,
        ));
      });

      _tts.setPauseHandler(() {
        _updateState(_currentState.copyWith(status: AudioPlaybackStatus.paused));
      });

      _tts.setContinueHandler(() {
        _updateState(_currentState.copyWith(status: AudioPlaybackStatus.playing));
      });

      _tts.setErrorHandler((dynamic msg) {
        _updateState(_currentState.copyWith(
          status: AudioPlaybackStatus.error,
          errorMessage: msg?.toString() ?? 'Audio playback error',
        ));
      });

      _tts.setProgressHandler((String text, int start, int end, String word) {
        if (text.isNotEmpty) {
          final p = (end / text.length).clamp(0.0, 1.0);
          _updateState(_currentState.copyWith(progress: p));
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[AiAudioService] TTS engine initialization warning: $e');
    }
  }

  void _updateState(AudioPlaybackState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  /// Speaks the provided text for a specific message ID.
  /// If the message is already playing, this acts as a toggle to pause it.
  /// If another message was playing, it is stopped first.
  Future<void> playMessage({
    required String messageId,
    required String rawText,
  }) async {
    await _init();

    // If tapping the currently playing message -> toggle pause/stop
    if (_currentState.messageId == messageId) {
      if (_currentState.isPlaying) {
        await pause();
        return;
      } else if (_currentState.isPaused) {
        await resume();
        return;
      }
    }

    // Stop any existing playback first
    await stop();

    final cleanedText = cleanTextForSpeech(rawText);
    if (cleanedText.trim().isEmpty) return;

    _updateState(AudioPlaybackState(
      messageId: messageId,
      status: AudioPlaybackStatus.playing,
      progress: 0.0,
      speechRate: _currentState.speechRate,
    ));

    try {
      final res = await _tts.speak(cleanedText);
      if (res == 0) {
        // Platform returned 0 indicating failed or unavailable engine
        debugPrint('[AiAudioService] Speak call returned 0');
      }
    } catch (e) {
      debugPrint('[AiAudioService] Failed to speak message: $e');
      _updateState(_currentState.copyWith(
        status: AudioPlaybackStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Pause current audio playback
  Future<void> pause() async {
    try {
      await _tts.pause();
      _updateState(_currentState.copyWith(status: AudioPlaybackStatus.paused));
    } catch (e) {
      debugPrint('[AiAudioService] Error pausing TTS: $e');
      await stop();
    }
  }

  /// Resume paused audio playback
  Future<void> resume() async {
    try {
      _updateState(_currentState.copyWith(status: AudioPlaybackStatus.playing));
      // Some platforms don't support resume directly, flutter_tts handles continue or speak
      await _tts.speak('');
    } catch (e) {
      debugPrint('[AiAudioService] Error resuming TTS: $e');
    }
  }

  /// Stop current audio playback
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('[AiAudioService] Error stopping TTS: $e');
    } finally {
      _updateState(const AudioPlaybackState(status: AudioPlaybackStatus.stopped));
    }
  }

  /// Adjust speech rate (typically 0.4 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    _currentState = _currentState.copyWith(speechRate: rate);
    try {
      await _tts.setSpeechRate(rate);
    } catch (e) {
      debugPrint('[AiAudioService] Error setting speech rate: $e');
    }
    _updateState(_currentState);
  }

  /// Sanitizes raw clinical AI messages into natural human-spoken sentences.
  /// Removes JSON/GenUI payloads, markdown fences, technical syntax, and translates
  /// abbreviations (mmHg, mg/dL, SpO2) into clear, friendly phonetics.
  static String cleanTextForSpeech(String raw) {
    if (raw.trim().isEmpty) return '';

    String text = raw;

    // 1. Remove JSON code blocks entirely (```json ... ``` or ``` ... ```)
    text = text.replaceAll(RegExp(r'```(?:json)?[\s\S]*?```', multiLine: true), ' ');

    // 2. Remove standalone JSON objects that might not be wrapped in code blocks
    text = text.replaceAll(RegExp(r'\{\s*"type"\s*:\s*"[^"]+"[\s\S]*?\}', multiLine: true), ' ');

    // 3. Remove raw markdown headers (###, ##, #)
    text = text.replaceAll(RegExp(r'^\s*#{1,6}\s*', multiLine: true), '');

    // 4. Clean bullet points (* or -) into natural phrase pauses
    text = text.replaceAll(RegExp(r'^\s*[\*\-•]\s+', multiLine: true), '. ');

    // 5. Remove bold and italics formatting (**bold**, *italic*, __bold__)
    text = text.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m[1] ?? '');
    text = text.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m[1] ?? '');
    text = text.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m[1] ?? '');
    text = text.replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m[1] ?? '');

    // 6. Remove markdown links [Label](url) -> Label
    text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1] ?? '');

    // 7. Remove emojis that would clutter voice speech
    text = text.replaceAll(
      RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}]',
          unicode: true),
      '',
    );

    // 8. Natural Clinical Metric Pronunciations
    // Blood pressure slashes: e.g. "120/80" -> "120 over 80"
    text = text.replaceAllMapped(RegExp(r'(\b\d{2,3})\s*/\s*(\d{2,3})\b'), (m) {
      return '${m[1]} over ${m[2]}';
    });

    // Units
    text = text.replaceAll(RegExp(r'\bmmHg\b', caseSensitive: false), 'millimeters of mercury');
    text = text.replaceAll(RegExp(r'\bmg/dL\b', caseSensitive: false), 'milligrams per deciliter');
    text = text.replaceAll(RegExp(r'\bmmol/L\b', caseSensitive: false), 'millimoles per liter');
    text = text.replaceAll(RegExp(r'\bbpm\b', caseSensitive: false), 'beats per minute');
    text = text.replaceAll(RegExp(r'\bSpO2\b|\bSpO₂\b', caseSensitive: false), 'blood oxygen saturation');

    // Symbols
    text = text.replaceAll('≥', 'greater than or equal to ');
    text = text.replaceAll('≤', 'less than or equal to ');
    text = text.replaceAll('>', 'greater than ');
    text = text.replaceAll('<', 'less than ');
    text = text.replaceAll('%', ' percent');

    // 9. Clean extra whitespace and newlines
    text = text.replaceAll(RegExp(r'\n+'), '. ');
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ');
    text = text.replaceAll(RegExp(r'\.{2,}'), '.');

    return text.trim();
  }

  void dispose() {
    stop();
    _stateController.close();
  }
}
