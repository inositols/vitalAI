import '../../../../features/patients/data/models/patient_model.dart';
import '../models/genui_response.dart';
import '../services/component_selection_service.dart';
import '../services/suggestion_service.dart';
import 'genui_validator.dart';

/// Central GenUI Engine orchestrating dynamic schema validation, component selection,
/// and context-aware suggestion resolution.
class GenUiEngine {
  final GenUiValidator validator;
  final SuggestionService suggestionService;
  final ComponentSelectionService componentSelectionService;

  const GenUiEngine({
    this.validator = const GenUiValidator(),
    this.suggestionService = const SuggestionService(),
    this.componentSelectionService = const ComponentSelectionService(),
  });

  /// Processes and parses a raw text response from the AI assistant.
  GenUiResponse processAiResponse(
    String rawText, {
    Map<String, dynamic>? context,
    String? intent,
    String? workflowStatus,
    String? patientId,
    String? patientName,
  }) {
    final parsed = GenUiResponse.fromRawAiText(rawText, initialContext: context);
    final validated = validator.validateResponse(parsed);

    // If no suggestions were extracted, resolve context-aware suggestions dynamically
    if (validated.suggestions.isEmpty) {
      final suggestions = suggestionService.resolveSuggestions(
        intent: intent ?? context?['intent']?.toString(),
        workflowStatus: workflowStatus ?? context?['status']?.toString(),
        patientId: patientId ?? context?['patientId']?.toString(),
        patientName: patientName ?? context?['patientName']?.toString(),
      );
      return validated.copyWith(suggestions: suggestions);
    }

    return validated;
  }

  /// Scenario 1 helper: Patient creation with extracted details
  GenUiResponse createPatientDraftResponse({
    required String name,
    required String age,
    String? complaint,
    String? duration,
    String? bloodPressure,
  }) {
    final res = componentSelectionService.buildPatientCreationExtractionResponse(
      name: name,
      age: age,
      complaint: complaint,
      duration: duration,
      bloodPressure: bloodPressure,
    );
    return validator.validateResponse(res);
  }

  /// Scenario 2 helper: Vitals entry pre-populated card
  GenUiResponse createVitalsEntryResponse({
    required String patientName,
    required int patientId,
    double? temperature,
    double? pulse,
    double? systolic,
    double? diastolic,
    double? spo2,
  }) {
    final res = componentSelectionService.buildVitalsEntryResponse(
      patientName: patientName,
      patientId: patientId,
      temperature: temperature,
      pulse: pulse,
      systolic: systolic,
      diastolic: diastolic,
      spo2: spo2,
    );
    return validator.validateResponse(res);
  }

  /// Scenario 2 success helper: Vitals recorded success card
  GenUiResponse createVitalsSavedResponse({
    required String patientName,
    required int patientId,
    required String summary,
  }) {
    final res = componentSelectionService.buildVitalsSavedSuccessResponse(
      patientName: patientName,
      patientId: patientId,
      savedSummary: summary,
    );
    return validator.validateResponse(res);
  }

  /// Scenario 3 helper: Latest vitals question response
  GenUiResponse createLatestVitalsResponse({
    required String patientName,
    required int patientId,
    required Map<String, dynamic> latestVitals,
    String? timestamp,
    List<double>? historicalBpPoints,
  }) {
    final res = componentSelectionService.buildLatestVitalsResponse(
      patientName: patientName,
      patientId: patientId,
      latestVitals: latestVitals,
      timestamp: timestamp,
      historicalBpPoints: historicalBpPoints,
    );
    return validator.validateResponse(res);
  }

  /// Scenario 4 helper: Patient history summary response
  GenUiResponse createPatientHistoryResponse({
    required String patientName,
    required int patientId,
    required String age,
    required Map<String, dynamic> latestVitals,
    required List<String> medicalHistory,
    required List<String> medications,
    required List<String> clinicalNotes,
    List<String> missingInfo = const [],
  }) {
    final res = componentSelectionService.buildPatientHistorySummaryResponse(
      patientName: patientName,
      patientId: patientId,
      age: age,
      latestVitals: latestVitals,
      medicalHistory: medicalHistory,
      medications: medications,
      clinicalNotes: clinicalNotes,
      missingInfo: missingInfo,
    );
    return validator.validateResponse(res);
  }

  /// Scenario 5 helper: Ambiguous patient disambiguation response
  GenUiResponse createPatientDisambiguationResponse({
    required String queryName,
    required List<PatientModel> matchingPatients,
  }) {
    final res = componentSelectionService.buildPatientDisambiguationResponse(
      queryName: queryName,
      matchingPatients: matchingPatients,
    );
    return validator.validateResponse(res);
  }

  /// Scenario 6 helper: Incomplete vitals request response
  GenUiResponse createIncompleteVitalsResponse({
    required String patientName,
    required int patientId,
  }) {
    final res = componentSelectionService.buildIncompleteVitalsRequestResponse(
      patientName: patientName,
      patientId: patientId,
    );
    return validator.validateResponse(res);
  }
}

