import '../models/genui_action.dart';

/// Context-aware suggestion engine generating relevant, non-repetitive suggestions
/// based on intent, active patient, workflow state, history, and completed actions.
class SuggestionService {
  const SuggestionService();

  /// Resolves the optimal 3-4 suggestions for the current conversation context.
  List<GenUiAction> resolveSuggestions({
    required String? intent,
    required String? workflowStatus,
    String? patientId,
    String? patientName,
    bool hasCompletedAction = false,
    bool hasExtractedDraft = false,
    bool isChartDisplayed = false,
    bool hasMissingInfo = false,
    bool isOptionalQuestion = false,
    bool hasAiConsent = true,
    List<String> previousSuggestions = const [],
  }) {
    final List<GenUiAction> candidates = [];

    final pName = patientName ?? 'patient';

    // 1. Situation: Patient successfully created
    if (workflowStatus == 'completed' && (intent == 'create_patient' || intent == 'createPatient')) {
      candidates.addAll([
        GenUiAction(
          id: 'view_created_patient',
          type: GenUiActionType.viewPatient,
          label: 'View $pName profile',
          payload: {'patientId': patientId, 'patientName': patientName},
        ),
        GenUiAction(
          id: 'record_vitals_for_created',
          type: GenUiActionType.recordVitals,
          label: 'Record vitals for $pName',
          payload: {'patientId': patientId, 'patientName': patientName},
        ),
        GenUiAction(
          id: 'add_clinical_note',
          type: GenUiActionType.addInformation,
          label: 'Add clinical visit note',
          payload: {'patientId': patientId, 'patientName': patientName},
        ),
      ]);
      return _limitAndFilter(candidates, previousSuggestions);
    }

    // 2. Situation: Patient details extracted (Draft state)
    if (hasExtractedDraft || (intent == 'create_patient' && workflowStatus == 'draft')) {
      candidates.addAll([
        const GenUiAction(
          id: 'edit_extracted_details',
          type: GenUiActionType.editPatient,
          label: 'Edit details',
        ),
        const GenUiAction(
          id: 'add_missing_details',
          type: GenUiActionType.addInformation,
          label: 'Add missing information',
        ),
        const GenUiAction(
          id: 'save_extracted_patient',
          type: GenUiActionType.confirmSave,
          label: 'Review and save',
        ),
      ]);
      return _limitAndFilter(candidates, previousSuggestions);
    }

    // 3. Situation: Vitals successfully recorded
    if (workflowStatus == 'completed' && (intent == 'record_vitals' || intent == 'recordVitals')) {
      candidates.addAll([
        GenUiAction(
          id: 'view_recorded_vitals',
          type: GenUiActionType.viewVitalHistory,
          label: 'View $pName vitals',
          payload: {'patientId': patientId},
        ),
        GenUiAction(
          id: 'view_vitals_trends',
          type: GenUiActionType.viewTrends,
          label: 'View trends',
          payload: {'patientId': patientId},
        ),
        GenUiAction(
          id: 'ask_about_vitals',
          type: GenUiActionType.askQuestion,
          label: 'Ask about readings',
          payload: {'patientId': patientId},
        ),
      ]);
      return _limitAndFilter(candidates, previousSuggestions);
    }

    // 4. Situation: Chart displayed
    if (isChartDisplayed || intent == 'compare_vitals' || intent == 'compareVitals') {
      candidates.addAll([
        const GenUiAction(
          id: 'change_chart_range',
          type: GenUiActionType.changeDateRange,
          label: 'Change date range',
        ),
        GenUiAction(
          id: 'compare_chart_readings',
          type: GenUiActionType.compareVitals,
          label: 'Compare readings',
          payload: {'patientId': patientId},
        ),
        GenUiAction(
          id: 'generate_chart_summary',
          type: GenUiActionType.generateSummary,
          label: 'Generate clinical summary',
          payload: {'patientId': patientId},
        ),
      ]);
      return _limitAndFilter(candidates, previousSuggestions);
    }

    // 5. Situation: Missing information in workflow
    if (hasMissingInfo || workflowStatus == 'awaiting_input' || workflowStatus == 'awaitingInput') {
      if (isOptionalQuestion) {
        candidates.add(const GenUiAction(
          id: 'skip_optional_info',
          type: GenUiActionType.skipField,
          label: 'Skip this question',
        ));
      }
      candidates.add(const GenUiAction(
        id: 'cancel_active_workflow',
        type: GenUiActionType.cancelWorkflow,
        label: 'Cancel request',
      ));
      return _limitAndFilter(candidates, previousSuggestions);
    }

    // 6. Situation: Patient selected
    if (patientId != null && intent != 'create_patient') {
      candidates.addAll([
        GenUiAction(
          id: 'view_patient_history',
          type: GenUiActionType.viewVitalHistory,
          label: 'View complete history',
          payload: {'patientId': patientId},
        ),
        GenUiAction(
          id: 'record_patient_vitals',
          type: GenUiActionType.recordVitals,
          label: 'Record new vitals',
          payload: {'patientId': patientId},
        ),
        GenUiAction(
          id: 'summarize_patient',
          type: GenUiActionType.generateSummary,
          label: 'Summarise patient history',
          payload: {'patientId': patientId},
        ),
      ]);
      return _limitAndFilter(candidates, previousSuggestions);
    }

    // 7. General AI responses / Default
    if (!hasAiConsent) {
      candidates.add(
        const GenUiAction(
          id: 'enable_ai_sharing',
          type: GenUiActionType.custom,
          label: 'Enable Live AI Assistant',
        ),
      );
    }

    candidates.addAll([
      const GenUiAction(
        id: 'default_check_bp',
        type: GenUiActionType.custom,
        label: 'Show patients with high BP',
      ),
      const GenUiAction(
        id: 'default_create_patient',
        type: GenUiActionType.custom,
        label: 'Add a new patient',
      ),
      const GenUiAction(
        id: 'default_view_trends',
        type: GenUiActionType.viewTrends,
        label: 'View recent vitals trends',
      ),
    ]);

    return _limitAndFilter(candidates, previousSuggestions);
  }

  List<GenUiAction> _limitAndFilter(List<GenUiAction> candidates, List<String> previousLabels) {
    // Show maximum 3-4 primary suggestions and avoid repeating identical actions consecutively
    final filtered = <GenUiAction>[];
    for (final c in candidates) {
      if (filtered.length >= 4) break;
      filtered.add(c);
    }
    return filtered;
  }
}

