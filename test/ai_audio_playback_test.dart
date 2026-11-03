import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalai/core/services/ai_audio_service.dart';
import 'package:vitalai/features/ai_assistant/presentation/widgets/ai_audio_playback_bar.dart';
import 'package:vitalai/features/ai_assistant/presentation/widgets/chat_message_action_bar.dart';

void main() {
  group('AiAudioService Text Sanitization & Phonetics Tests', () {
    test('Cleans code blocks and JSON GenUI widgets completely', () {
      const raw = '''
### 🫀 Blood Pressure Evaluation
Your reading of **120/80 mmHg** is optimal.
```json
{
  "type": "vital_badge",
  "vital": "blood_pressure",
  "value": "120/80"
}
```
Please continue tracking regularly.
''';

      final cleaned = AiAudioService.cleanTextForSpeech(raw);

      // Verify JSON code blocks and markdown symbols are stripped
      expect(cleaned.contains('```'), isFalse);
      expect(cleaned.contains('"type"'), isFalse);
      expect(cleaned.contains('###'), isFalse);
      expect(cleaned.contains('**'), isFalse);
      expect(cleaned.contains('🫀'), isFalse);

      // Verify clinical phonetic expansions
      expect(cleaned.contains('120 over 80'), isTrue);
      expect(cleaned.contains('millimeters of mercury'), isTrue);
      expect(cleaned.contains('optimal'), isTrue);
      expect(cleaned.contains('Please continue tracking regularly'), isTrue);
    });

    test('Translates glucose units, SpO2, and bpm into human speech', () {
      const raw = 'Blood sugar is 95 mg/dL. SpO2 is 98% with pulse of 72 bpm.';
      final cleaned = AiAudioService.cleanTextForSpeech(raw);

      expect(cleaned.contains('milligrams per deciliter'), isTrue);
      expect(cleaned.contains('blood oxygen saturation'), isTrue);
      expect(cleaned.contains('98 percent'), isTrue);
      expect(cleaned.contains('beats per minute'), isTrue);
    });

    test('Cleans markdown bullet lists and links smoothly', () {
      const raw = '''
Key recommendations:
* Monitor daily [Learn More](https://vitalai.health/docs)
- Maintain low sodium intake
• Exercise 30 minutes
''';
      final cleaned = AiAudioService.cleanTextForSpeech(raw);

      expect(cleaned.contains('*'), isFalse);
      expect(cleaned.contains('https://'), isFalse);
      expect(cleaned.contains('Learn More'), isTrue);
      expect(cleaned.contains('Maintain low sodium intake'), isTrue);
      expect(cleaned.contains('Exercise 30 minutes'), isTrue);
    });

    test('Handles comparison operators in clinical advice', () {
      const raw = 'Readings ≥ 140 or > 180 require prompt clinical assessment.';
      final cleaned = AiAudioService.cleanTextForSpeech(raw);

      expect(cleaned.contains('greater than or equal to 140'), isTrue);
      expect(cleaned.contains('greater than 180'), isTrue);
    });
  });

  group('AudioPlaybackState State Model Tests', () {
    test('Calculates active and speaking flags accurately', () {
      const idle = AudioPlaybackState();
      expect(idle.isPlaying, isFalse);
      expect(idle.isPaused, isFalse);
      expect(idle.isActive, isFalse);
      expect(idle.isSpeakingMessage('msg-1'), isFalse);

      final playing = idle.copyWith(
        messageId: 'msg-1',
        status: AudioPlaybackStatus.playing,
        progress: 0.45,
      );
      expect(playing.isPlaying, isTrue);
      expect(playing.isPaused, isFalse);
      expect(playing.isActive, isTrue);
      expect(playing.isSpeakingMessage('msg-1'), isTrue);
      expect(playing.isSpeakingMessage('msg-2'), isFalse);
      expect(playing.isMessageActive('msg-1'), isTrue);

      final paused = playing.copyWith(status: AudioPlaybackStatus.paused);
      expect(paused.isPlaying, isFalse);
      expect(paused.isPaused, isTrue);
      expect(paused.isActive, isTrue);
      expect(paused.isSpeakingMessage('msg-1'), isFalse);
      expect(paused.isMessageActive('msg-1'), isTrue);
    });
  });

  group('AiAudioPlaybackBar Widget Tests', () {
    testWidgets('Renders playback bar with controls and triggers callbacks', (tester) async {
      bool playPauseCalled = false;
      bool stopCalled = false;
      double? changedSpeed;

      const state = AudioPlaybackState(
        messageId: 'msg-ai-1',
        status: AudioPlaybackStatus.playing,
        progress: 0.5,
        speechRate: 0.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiAudioPlaybackBar(
              playbackState: state,
              onPlayPause: () => playPauseCalled = true,
              onStop: () => stopCalled = true,
              onSpeedChanged: (s) => changedSpeed = s,
            ),
          ),
        ),
      );

      // Verify visual elements
      expect(find.text('Reading response aloud...'), findsOneWidget);
      expect(find.text('AI Voice Assistant'), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Tap Play/Pause button
      await tester.tap(find.byIcon(Icons.pause_rounded));
      expect(playPauseCalled, isTrue);

      // Tap Stop button
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(stopCalled, isTrue);

      // Tap Speed chip
      await tester.tap(find.text('1.0x'));
      expect(changedSpeed, equals(0.6)); // Cycles to 1.25x (rate 0.6)
    });

    testWidgets('Shows paused text and play icon when status is paused', (tester) async {
      const state = AudioPlaybackState(
        messageId: 'msg-ai-1',
        status: AudioPlaybackStatus.paused,
        progress: 0.3,
        speechRate: 0.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiAudioPlaybackBar(
              playbackState: state,
              onPlayPause: () {},
              onStop: () {},
              onSpeedChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Audio playback paused'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });

  group('ChatMessageActionBar Audio Controls Tests', () {
    testWidgets('Shows appropriate speaker icon for idle, playing, and paused', (tester) async {
      // 1. Idle state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageActionBar(
              feedbackIsPositive: null,
              isSpeaking: false,
              isPaused: false,
              onCopy: () {},
              onToggleThumbsUp: () {},
              onToggleThumbsDown: () {},
              onToggleSpeech: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);

      // 2. Playing state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageActionBar(
              feedbackIsPositive: null,
              isSpeaking: true,
              isPaused: false,
              onCopy: () {},
              onToggleThumbsUp: () {},
              onToggleThumbsDown: () {},
              onToggleSpeech: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);

      // 3. Paused state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageActionBar(
              feedbackIsPositive: null,
              isSpeaking: false,
              isPaused: true,
              onCopy: () {},
              onToggleThumbsUp: () {},
              onToggleThumbsDown: () {},
              onToggleSpeech: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    });
  });
}
