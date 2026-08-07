import 'package:flutter_test/flutter_test.dart';
import 'package:vitalai/core/services/ai_explanation_service.dart';
import 'package:vitalai/core/services/ai_service.dart';

void main() {
  group('AiService Tailored Answers Tests', () {
    late AiService aiService;

    setUp(() {
      aiService = AiService(null); // Offline mode testing
    });

    test('Different query intents produce distinct, tailored responses', () async {
      final responseDefinition = await aiService.askAssistant("What is blood pressure?");
      final responseImprovement = await aiService.askAssistant("How can I lower my blood pressure?");
      final responseDoctorPrep = await aiService.askAssistant("What questions should I ask my doctor?");
      final responseStress = await aiService.askAssistant("Does stress increase my heart rate?");
      final responseWater = await aiService.askAssistant("How does water affect my vitals?");

      // Verify that responses are distinct and tailored to each prompt
      expect(responseDefinition, isNot(equals(responseImprovement)));
      expect(responseImprovement, isNot(equals(responseDoctorPrep)));
      expect(responseDoctorPrep, isNot(equals(responseStress)));
      expect(responseStress, isNot(equals(responseWater)));

      // Check content specific to questions
      expect(responseDefinition, contains("Blood pressure measures the force"));
      expect(responseImprovement, contains("DASH Eating Plan"));
      expect(responseDoctorPrep, contains("Top 3 Questions to Ask Your Doctor"));
      expect(responseStress, contains("sympathetic nervous system"));
      expect(responseWater, contains("Blood Volume"));
    });

    test('Explanation prompt interception only triggers on definition requests', () {
      final definitionCheck = AiExplanationService.handleExplanationPrompt("What is SpO2?");
      final improvementCheck = AiExplanationService.handleExplanationPrompt("How do I improve my SpO2?");

      expect(definitionCheck, isNotNull);
      expect(definitionCheck, contains("SpO₂ (Blood Oxygen Saturation) measures"));

      // Non-definition intent should pass through (return null) so AiService can generate tailored intent answers
      expect(improvementCheck, isNull);
    });
  });
}
