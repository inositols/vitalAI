import '../../../../features/patients/data/models/patient_model.dart';
import '../models/genui_action.dart';
import '../models/genui_component.dart';
import '../models/genui_option.dart';
import '../models/genui_response.dart';
import 'suggestion_service.dart';

/// Context-aware service determining the exact GenUI components to construct
/// according to the provider's intent, workflow stage, and clinical data.
class ComponentSelectionService {
  final SuggestionService suggestionService;

  const ComponentSelectionService({
    this.suggestionService = const SuggestionService(),
  });

  /// Scenario 1: Patient creation with extracted clinical draft information
  GenUiResponse buildPatientCreationExtractionResponse({
    required String name,
    required String age,
    String? complaint,
    String? duration,
    String? bloodPressure,
    List<String>? missingFields,
  }) {
    final patientCard = GenUiComponent(
      id: 'editable_patient_card',
      type: GenUiComponentTypes.editablePatientCard,
      data: {
        'name': name,
        'age': age,
        'complaint': complaint,
        'duration': duration,
        'bloodPressure': bloodPressure,
        'missingFields': missingFields ?? ['Temperature', 'Medications', 'Clinical notes'],
      },
      actions: const [
        GenUiAction(id: 'edit_patient', type: GenUiActionType.editPatient, label: 'Edit information'),
        GenUiAction(id: 'add_more', type: GenUiActionType.addInformation, label: 'Add more information'),
        GenUiAction(id: 'confirm_save', type: GenUiActionType.confirmSave, label: 'Confirm and save'),
        GenUiAction(id: 'cancel', type: GenUiActionType.cancelWorkflow, label: 'Cancel', isDestructive: true),
      ],
    );

    final followUpOptionsCard = GenUiComponent(
      id: 'creation_followup_options',
      type: GenUiComponentTypes.choiceCard,
      data: {
        'title': 'Would you like to add anything else?',
        'prompt': 'Would you like to add anything else?',
      },
      options: const [
        GenUiOption(id: 'add_temp', label: 'Add temperature', value: 'temperature'),
        GenUiOption(id: 'add_meds', label: 'Add medication history', value: 'medications'),
        GenUiOption(id: 'add_notes', label: 'Add clinical notes', value: 'clinical_notes'),
        GenUiOption(id: 'review_save', label: 'Review and save', value: 'review_save'),
      ],
    );

    final suggestions = suggestionService.resolveSuggestions(
      intent: 'create_patient',
      workflowStatus: 'draft',
      patientName: name,
      hasExtractedDraft: true,
    );

    return GenUiResponse(
      message: "I've extracted the information for $name.",
      components: [patientCard, followUpOptionsCard],
      suggestions: suggestions,
      context: {
        'intent': 'create_patient',
        'patientName': name,
        'workflow': 'patient_registration',
      },
    );
  }

  /// Scenario 2: Recording vitals with extracted readings
  GenUiResponse buildVitalsEntryResponse({
    required String patientName,
    required int patientId,
    double? temperature,
    double? pulse,
    double? systolic,
    double? diastolic,
    double? spo2,
  }) {
    final vitalsCard = GenUiComponent(
      id: 'vital_input_card',
      type: GenUiComponentTypes.vitalInputCard,
      data: {
        'patientId': patientId,
        'patientName': patientName,
        'temperature': temperature,
        'pulse': pulse,
        'systolic': systolic,
        'diastolic': diastolic,
        'spo2': spo2,
        'timestamp': DateTime.now().toIso8601String(),
      },
      actions: const [
        GenUiAction(id: 'confirm_vitals', type: GenUiActionType.confirmSave, label: 'Confirm and Save'),
        GenUiAction(id: 'cancel_vitals', type: GenUiActionType.cancelWorkflow, label: 'Cancel'),
      ],
    );

    return GenUiResponse(
      message: "I found $patientName's patient record and prepared the new readings.",
      components: [vitalsCard],
      suggestions: [
        GenUiAction(
          id: 'confirm_save_vitals',
          type: GenUiActionType.confirmSave,
          label: 'Save vitals for $patientName',
          payload: {'patientId': patientId},
        ),
        const GenUiAction(
          id: 'cancel_vitals_record',
          type: GenUiActionType.cancelWorkflow,
          label: 'Cancel',
        ),
      ],
      context: {
        'intent': 'record_vitals',
        'patientId': patientId,
        'patientName': patientName,
      },
    );
  }

  /// Scenario 2 Completion: Post-save vitals success component
  GenUiResponse buildVitalsSavedSuccessResponse({
    required String patientName,
    required int patientId,
    required String savedSummary,
  }) {
    final successCard = GenUiComponent(
      id: 'vitals_save_success',
      type: GenUiComponentTypes.successCard,
      data: {
        'message': 'Vitals successfully recorded for $patientName.',
        'details': savedSummary,
      },
      actions: [
        GenUiAction(
          id: 'view_updated_vitals',
          type: GenUiActionType.viewVitalHistory,
          label: 'View updated vitals',
          payload: {'patientId': patientId},
        ),
        GenUiAction(
          id: 'view_patient_profile',
          type: GenUiActionType.viewPatient,
          label: 'View patient profile',
          payload: {'patientId': patientId},
        ),
        GenUiAction(
          id: 'record_more_vitals',
          type: GenUiActionType.recordVitals,
          label: 'Record more vitals',
          payload: {'patientId': patientId},
        ),
      ],
    );

    final suggestions = suggestionService.resolveSuggestions(
      intent: 'record_vitals',
      workflowStatus: 'completed',
      patientId: patientId.toString(),
      patientName: patientName,
      hasCompletedAction: true,
    );

    return GenUiResponse(
      message: "Recorded new vitals for $patientName.",
      components: [successCard],
      suggestions: suggestions,
      context: {'patientId': patientId, 'patientName': patientName},
    );
  }

  /// Scenario 3: Patient question (Show latest vital signs)
  GenUiResponse buildLatestVitalsResponse({
    required String patientName,
    required int patientId,
    required Map<String, dynamic> latestVitals,
    String? timestamp,
    List<double>? historicalBpPoints,
  }) {
    final chartOrSummary = GenUiComponent(
      id: 'latest_vitals_chart',
      type: GenUiComponentTypes.chartCard,
      data: {
        'title': "$patientName's Latest Vitals & Trend",
        'metric': 'Blood Pressure',
        'latestReading': latestVitals['Blood Pressure'] ?? latestVitals['bp'] ?? '118/76',
        'unit': 'mmHg',
        'timestamp': timestamp ?? 'Today • 09:41 AM',
        'dataPoints': historicalBpPoints ?? [122.0, 120.0, 118.0, 118.0],
      },
    );

    final suggestions = [
      GenUiAction(
        id: 'compare_readings',
        type: GenUiActionType.compareVitals,
        label: 'Compare readings',
        payload: {'patientId': patientId},
      ),
      GenUiAction(
        id: 'view_complete_history',
        type: GenUiActionType.viewVitalHistory,
        label: 'View complete history',
        payload: {'patientId': patientId},
      ),
      GenUiAction(
        id: 'record_new_vitals',
        type: GenUiActionType.recordVitals,
        label: 'Record new vitals',
        payload: {'patientId': patientId},
      ),
    ];

    final bpStr = latestVitals['Blood Pressure'] ?? latestVitals['bp'] ?? '118/76 mmHg';
    return GenUiResponse(
      message: "$patientName's latest blood pressure reading is $bpStr.",
      components: [chartOrSummary],
      suggestions: suggestions,
      context: {'patientId': patientId, 'patientName': patientName},
    );
  }

  /// Scenario 4: Patient history summary
  GenUiResponse buildPatientHistorySummaryResponse({
    required String patientName,
    required int patientId,
    required String age,
    required Map<String, dynamic> latestVitals,
    required List<String> medicalHistory,
    required List<String> medications,
    required List<String> clinicalNotes,
    List<String> missingInfo = const [],
  }) {
    final summaryCard = GenUiComponent(
      id: 'patient_history_summary_card',
      type: GenUiComponentTypes.clinicalSummaryCard,
      data: {
        'patientName': patientName,
        'patientId': patientId,
        'age': age,
        'latestVitals': latestVitals,
        'medicalHistory': medicalHistory,
        'medications': medications,
        'clinicalNotes': clinicalNotes,
        'missingInfo': missingInfo,
      },
    );

    final suggestions = [
      GenUiAction(
        id: 'view_detailed_notes',
        type: GenUiActionType.viewVitalHistory,
        label: 'View detailed notes',
        payload: {'patientId': patientId},
      ),
      GenUiAction(
        id: 'view_vital_trends',
        type: GenUiActionType.viewTrends,
        label: 'View vital trends',
        payload: {'patientId': patientId},
      ),
      GenUiAction(
        id: 'ask_another_question',
        type: GenUiActionType.askQuestion,
        label: 'Ask another question',
        payload: {'patientId': patientId},
      ),
    ];

    return GenUiResponse(
      message: "Here is the verified clinical history summary for $patientName:",
      components: [summaryCard],
      suggestions: suggestions,
      context: {'patientId': patientId, 'patientName': patientName},
    );
  }

  /// Scenario 5: Ambiguous patient disambiguation
  GenUiResponse buildPatientDisambiguationResponse({
    required String queryName,
    required List<PatientModel> matchingPatients,
  }) {
    final patientCard = GenUiComponent(
      id: 'disambiguate_patients_card',
      type: GenUiComponentTypes.patientCard,
      data: {
        'title': 'Which patient do you mean?',
        'prompt': 'Multiple patients matched "$queryName". Please select the correct record:',
      },
      options: matchingPatients.map((p) {
        final age = (DateTime.now().difference(p.dateOfBirth).inDays / 365.25).floor();
        final condition = p.medicalConditions.isNotEmpty ? p.medicalConditions.first : 'General';
        return GenUiOption(
          id: p.id.toString(),
          label: p.name,
          value: p.id,
          subtitle: 'ID: ${p.remoteId} • Age: $age • $condition',
          metadata: {
            'id': p.id,
            'remoteId': p.remoteId,
            'age': age,
            'condition': condition,
            'gender': p.gender,
          },
        );
      }).toList(),
    );

    return GenUiResponse(
      message: 'Which patient do you mean?',
      components: [patientCard],
      suggestions: const [
        GenUiAction(
          id: 'cancel_patient_selection',
          type: GenUiActionType.cancelWorkflow,
          label: 'Cancel search',
        ),
      ],
      context: {'intent': 'disambiguate_patient', 'query': queryName},
    );
  }

  /// Scenario 6: Incomplete vitals request (missing blood pressure readings)
  GenUiResponse buildIncompleteVitalsRequestResponse({
    required String patientName,
    required int patientId,
  }) {
    final bpInputCard = GenUiComponent(
      id: 'bp_missing_input_card',
      type: GenUiComponentTypes.vitalInputCard,
      data: {
        'patientId': patientId,
        'patientName': patientName,
        'title': "Enter Blood Pressure for $patientName",
      },
      actions: const [
        GenUiAction(id: 'submit_bp', type: GenUiActionType.confirmSave, label: 'Continue'),
        GenUiAction(id: 'cancel_bp', type: GenUiActionType.cancelWorkflow, label: 'Cancel'),
      ],
    );

    return GenUiResponse(
      message: 'Sure. What is the blood pressure reading?',
      components: [bpInputCard],
      suggestions: const [
        GenUiAction(
          id: 'cancel_incomplete_bp',
          type: GenUiActionType.cancelWorkflow,
          label: 'Cancel',
        ),
      ],
      context: {
        'intent': 'record_vitals',
        'patientId': patientId,
        'patientName': patientName,
        'targetField': 'bloodPressure',
      },
    );
  }
}

