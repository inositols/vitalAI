import 'package:flutter/material.dart';
import '../../../../features/patients/data/models/patient_model.dart';
import '../models/conversation_intent.dart';
import '../models/conversation_workflow_state.dart';
import '../models/follow_up_question.dart';
import '../models/genui_question_type.dart';

/// Resolves the next single focused follow-up question and selects the appropriate GenUI component.
class FollowUpQuestionResolver {
  const FollowUpQuestionResolver();

  /// Resolve the next question based on current state and registered existing patients.
  FollowUpQuestion? resolveNextQuestion(
    ConversationWorkflowState state,
    List<PatientModel> existingPatients,
  ) {
    // 1. Check for patient ambiguity first (multiple candidate patients matched)
    if (state.candidatePatients.length > 1) {
      return FollowUpQuestion(
        id: 'disambiguate_patient',
        targetField: 'patientId',
        promptText: 'Multiple patients match your request. Please select the intended patient:',
        questionType: GenUiQuestionType.patientSelection,
        options: state.candidatePatients.map((p) {
          return FollowUpOption(
            label: p.name,
            value: p.id,
            subtitle: 'ID: ${p.remoteId} • DOB: ${_formatDob(p.dateOfBirth)} • ${p.phone ?? p.emergencyContact}',
            icon: Icons.person_rounded,
            metadata: {'patient': p},
          );
        }).toList(),
      );
    }

    // 2. Resolve based on the active intent
    switch (state.intent) {
      case ConversationIntent.recordVitals:
        return _resolveVitalsQuestion(state, existingPatients);

      case ConversationIntent.compareVitals:
        return _resolveCompareVitalsQuestion(state, existingPatients);

      case ConversationIntent.createPatient:
        return _resolveCreatePatientQuestion(state);

      case ConversationIntent.draftClinicalNote:
        return _resolveDraftNoteQuestion(state, existingPatients);

      case ConversationIntent.manageAppointments:
        return _resolveAppointmentQuestion(state, existingPatients);

      case ConversationIntent.queryPatientHistory:
        return _resolveHistoryQuestion(state, existingPatients);

      case ConversationIntent.updatePatientInfo:
        return _resolveUpdatePatientQuestion(state, existingPatients);

      case ConversationIntent.openPatientDetails:
      case ConversationIntent.findPatient:
        return _resolvePatientLookupQuestion(state, existingPatients);

      default:
        return null;
    }
  }

  FollowUpQuestion? _resolveVitalsQuestion(
    ConversationWorkflowState state,
    List<PatientModel> existingPatients,
  ) {
    // Patient required
    if (state.activePatient == null && !state.parameters.containsKey('patientId')) {
      return _buildPatientSelectionQuestion(
        'Which patient are you recording vitals for?',
        existingPatients,
      );
    }

    // Systolic required
    if (!state.parameters.containsKey('systolic') || state.parameters['systolic'] == null) {
      return const FollowUpQuestion(
        id: 'bp_systolic',
        targetField: 'systolic',
        promptText: 'What is the systolic reading (mmHg)?',
        questionType: GenUiQuestionType.numericInput,
        unit: 'mmHg',
        minValue: 60,
        maxValue: 300,
        initialValue: 120,
        helpText: 'Normal resting range: 90 - 120 mmHg',
      );
    }

    // Diastolic required
    if (!state.parameters.containsKey('diastolic') || state.parameters['diastolic'] == null) {
      return const FollowUpQuestion(
        id: 'bp_diastolic',
        targetField: 'diastolic',
        promptText: 'What is the diastolic reading (mmHg)?',
        questionType: GenUiQuestionType.numericInput,
        unit: 'mmHg',
        minValue: 30,
        maxValue: 200,
        initialValue: 80,
        helpText: 'Normal resting range: 60 - 80 mmHg',
      );
    }

    // If all required fields are present and valid, show explicit confirmation card!
    if (state.hasAllRequiredParameters && !state.isConfirmed) {
      final patientName = state.activePatient?.name ?? state.parameters['patientName'] ?? 'Patient';
      final sys = (state.parameters['systolic'] as num).toInt();
      final dia = (state.parameters['diastolic'] as num).toInt();

      return FollowUpQuestion(
        id: 'vitals_confirmation',
        targetField: 'confirmed',
        promptText: 'Ready to record $sys/$dia mmHg for $patientName. Please confirm:',
        questionType: GenUiQuestionType.confirmationCard,
        metadata: {
          'systolic': sys,
          'diastolic': dia,
          'pulseRate': state.parameters['pulseRate'],
          'bodyTemperature': state.parameters['bodyTemperature'],
          'patientName': patientName,
          'date': state.parameters['date'] ?? DateTime.now(),
        },
      );
    }

    return null;
  }

  FollowUpQuestion? _resolveCompareVitalsQuestion(
    ConversationWorkflowState state,
    List<PatientModel> existingPatients,
  ) {
    if (state.activePatient == null && !state.parameters.containsKey('patientId')) {
      return _buildPatientSelectionQuestion(
        'Which patient\'s vital trends would you like to compare?',
        existingPatients,
      );
    }

    if (!state.parameters.containsKey('dateRange')) {
      return const FollowUpQuestion(
        id: 'compare_range',
        targetField: 'dateRange',
        promptText: 'Select comparison time frame:',
        questionType: GenUiQuestionType.singleChoice,
        options: [
          FollowUpOption(
            label: 'Last 7 Days vs Previous 7 Days',
            value: '7_days',
            subtitle: 'Week-over-week systolic/diastolic variance',
            icon: Icons.calendar_view_week_rounded,
            isRecommended: true,
          ),
          FollowUpOption(
            label: 'Last 30 Days',
            value: '30_days',
            subtitle: 'Monthly longitudinal progression',
            icon: Icons.calendar_month_rounded,
          ),
          FollowUpOption(
            label: 'All Historical Readings',
            value: 'all_time',
            subtitle: 'Full patient monitoring timeline',
            icon: Icons.history_rounded,
          ),
        ],
      );
    }

    return null;
  }

  FollowUpQuestion? _resolveCreatePatientQuestion(ConversationWorkflowState state) {
    // 1. Full legal name (Required)
    if (!state.parameters.containsKey('name') ||
        state.parameters['name']?.toString().trim().isEmpty == true) {
      return const FollowUpQuestion(
        id: 'patient_name',
        targetField: 'name',
        promptText: 'What is the patient\'s full legal name?',
        questionType: GenUiQuestionType.textInput,
        helpText: 'e.g. Chika Okafor, Tunde Bello',
      );
    }

    // 2. Date of birth (Optional)
    if (!state.parameters.containsKey('dateOfBirth') &&
        !state.parameters.containsKey('skip_dateOfBirth')) {
      return const FollowUpQuestion(
        id: 'patient_dob',
        targetField: 'dateOfBirth',
        promptText: 'What is their date of birth? (Optional)',
        questionType: GenUiQuestionType.datePicker,
        isOptional: true,
        helpText: 'Format: 12 March 1998 or tap date picker',
      );
    }

    // 3. Contact phone (Optional)
    if (!state.parameters.containsKey('phone') &&
        !state.parameters.containsKey('skip_phone')) {
      return const FollowUpQuestion(
        id: 'patient_phone',
        targetField: 'phone',
        promptText: 'What is their contact phone number? (Optional)',
        questionType: GenUiQuestionType.textInput,
        isOptional: true,
        helpText: 'e.g. +234 803 123 4567',
      );
    }

    // 4. Biological sex (Optional)
    if (!state.parameters.containsKey('gender') &&
        !state.parameters.containsKey('skip_gender')) {
      return const FollowUpQuestion(
        id: 'patient_gender',
        targetField: 'gender',
        promptText: 'Select biological sex for clinical baselines: (Optional)',
        questionType: GenUiQuestionType.singleChoice,
        isOptional: true,
        options: [
          FollowUpOption(label: 'Female', value: 'Female', icon: Icons.female_rounded),
          FollowUpOption(label: 'Male', value: 'Male', icon: Icons.male_rounded),
          FollowUpOption(label: 'Other / Prefer not to say', value: 'Other', icon: Icons.person_rounded),
        ],
      );
    }

    // Ready for confirmation
    if (!state.isConfirmed) {
      return FollowUpQuestion(
        id: 'patient_creation_confirmation',
        targetField: 'confirmed',
        promptText: 'Ready to register ${state.parameters['name']}. Please confirm:',
        questionType: GenUiQuestionType.confirmationCard,
        metadata: Map<String, dynamic>.from(state.parameters),
      );
    }

    return null;
  }

  FollowUpQuestion? _resolveDraftNoteQuestion(
    ConversationWorkflowState state,
    List<PatientModel> existingPatients,
  ) {
    if (state.activePatient == null && !state.parameters.containsKey('patientId')) {
      return _buildPatientSelectionQuestion(
        'Which patient is this encounter note for?',
        existingPatients,
      );
    }

    if (!state.parameters.containsKey('visitType')) {
      return const FollowUpQuestion(
        id: 'note_type',
        targetField: 'visitType',
        promptText: 'Select the clinical note encounter classification:',
        questionType: GenUiQuestionType.singleChoice,
        options: [
          FollowUpOption(
            label: 'General Consultation',
            value: 'General Consultation',
            subtitle: 'Routine clinical consultation & review',
            icon: Icons.medical_services_rounded,
            isRecommended: true,
          ),
          FollowUpOption(
            label: 'Follow-up Consultation',
            value: 'Follow-up Consultation',
            subtitle: 'Progress evaluation after initial diagnosis',
            icon: Icons.event_repeat_rounded,
          ),
          FollowUpOption(
            label: 'SOAP Note',
            value: 'SOAP Note',
            subtitle: 'Subjective, Objective, Assessment, Plan structured note',
            icon: Icons.article_rounded,
          ),
          FollowUpOption(
            label: 'Urgent Care / Acute',
            value: 'Urgent Care',
            subtitle: 'Acute clinical symptoms & immediate intervention',
            icon: Icons.warning_amber_rounded,
          ),
        ],
      );
    }

    if (!state.parameters.containsKey('content') ||
        state.parameters['content']?.toString().trim().isEmpty == true) {
      return const FollowUpQuestion(
        id: 'note_content',
        targetField: 'content',
        promptText: 'Please dictate or type the visit observations and assessment:',
        questionType: GenUiQuestionType.textInput,
        helpText: 'e.g. Patient reports improved headache control. Blood pressure stabilized on Amlodipine.',
      );
    }

    // Ready for confirmation & preview
    if (!state.isConfirmed) {
      final patientName = state.activePatient?.name ?? state.parameters['patientName'] ?? 'Patient';
      return FollowUpQuestion(
        id: 'note_confirmation',
        targetField: 'confirmed',
        promptText: 'Review drafted encounter note for $patientName:',
        questionType: GenUiQuestionType.previewCard,
        metadata: {
          'patientName': patientName,
          'visitType': state.parameters['visitType'] ?? 'General Consultation',
          'content': state.parameters['content'] ?? '',
          'authorName': 'Dr. Adeyemi',
          'date': DateTime.now(),
        },
      );
    }

    return null;
  }

  FollowUpQuestion? _resolveAppointmentQuestion(
    ConversationWorkflowState state,
    List<PatientModel> existingPatients,
  ) {
    if (state.activePatient == null && !state.parameters.containsKey('patientId')) {
      return _buildPatientSelectionQuestion(
        'Which patient is this appointment or follow-up for?',
        existingPatients,
      );
    }

    if (!state.parameters.containsKey('title')) {
      return const FollowUpQuestion(
        id: 'appointment_title',
        targetField: 'title',
        promptText: 'Select appointment reason:',
        questionType: GenUiQuestionType.singleChoice,
        options: [
          FollowUpOption(
            label: 'Blood Pressure Check',
            value: 'Blood Pressure Check',
            subtitle: 'Routine BP re-evaluation',
            icon: Icons.favorite_rounded,
            isRecommended: true,
          ),
          FollowUpOption(
            label: 'Medication Review',
            value: 'Medication Review',
            subtitle: 'Refill and tolerance check',
            icon: Icons.medication_rounded,
          ),
          FollowUpOption(
            label: 'Lab Results Follow-up',
            value: 'Lab Results Review',
            subtitle: 'Review blood work & biomarkers',
            icon: Icons.biotech_rounded,
          ),
          FollowUpOption(
            label: 'Routine Consultation',
            value: 'Routine Consultation',
            subtitle: 'General wellness check',
            icon: Icons.health_and_safety_rounded,
          ),
        ],
      );
    }

    if (!state.parameters.containsKey('time')) {
      return const FollowUpQuestion(
        id: 'appointment_time',
        targetField: 'time',
        promptText: 'Select preferred appointment time:',
        questionType: GenUiQuestionType.singleChoice,
        options: [
          FollowUpOption(label: '08:00 AM', value: '08:00 AM', subtitle: 'Morning slot', icon: Icons.wb_sunny_rounded),
          FollowUpOption(label: '10:30 AM', value: '10:30 AM', subtitle: 'Mid-morning slot', icon: Icons.wb_sunny_outlined),
          FollowUpOption(label: '02:00 PM', value: '02:00 PM', subtitle: 'Afternoon slot', icon: Icons.wb_twilight_rounded),
          FollowUpOption(label: '04:30 PM', value: '04:30 PM', subtitle: 'Late afternoon slot', icon: Icons.bedtime_outlined),
        ],
      );
    }

    // Confirmation
    if (!state.isConfirmed) {
      final patientName = state.activePatient?.name ?? state.parameters['patientName'] ?? 'Patient';
      return FollowUpQuestion(
        id: 'appointment_confirmation',
        targetField: 'confirmed',
        promptText: 'Confirm appointment for $patientName at ${state.parameters['time']} (${state.parameters['title']}):',
        questionType: GenUiQuestionType.confirmationCard,
        metadata: {
          'patientName': patientName,
          'title': state.parameters['title'],
          'time': state.parameters['time'],
          'date': state.parameters['date'] ?? DateTime.now().add(const Duration(days: 7)),
        },
      );
    }

    return null;
  }

  FollowUpQuestion? _resolveHistoryQuestion(
    ConversationWorkflowState state,
    List<PatientModel> existingPatients,
  ) {
    if (state.activePatient == null && !state.parameters.containsKey('patientId')) {
      return _buildPatientSelectionQuestion(
        'Which patient\'s clinical history would you like to review?',
        existingPatients,
      );
    }

    if (!state.parameters.containsKey('categories')) {
      return const FollowUpQuestion(
        id: 'history_categories',
        targetField: 'categories',
        promptText: 'Select record categories to review:',
        questionType: GenUiQuestionType.multiSelect,
        options: [
          FollowUpOption(label: 'Vital Signs', value: 'vitals', icon: Icons.favorite_rounded, isRecommended: true),
          FollowUpOption(label: 'Clinical Notes', value: 'notes', icon: Icons.description_rounded, isRecommended: true),
          FollowUpOption(label: 'Encounter Visits', value: 'visits', icon: Icons.calendar_month_rounded),
          FollowUpOption(label: 'Medications', value: 'medications', icon: Icons.medication_rounded),
        ],
      );
    }

    return null;
  }

  FollowUpQuestion? _resolveUpdatePatientQuestion(
    ConversationWorkflowState state,
    List<PatientModel> existingPatients,
  ) {
    if (state.activePatient == null && !state.parameters.containsKey('patientId')) {
      return _buildPatientSelectionQuestion(
        'Which patient\'s record are you updating?',
        existingPatients,
      );
    }

    if (!state.parameters.containsKey('updatedField')) {
      return const FollowUpQuestion(
        id: 'update_field',
        targetField: 'updatedField',
        promptText: 'Select field to update:',
        questionType: GenUiQuestionType.singleChoice,
        options: [
          FollowUpOption(label: 'Phone Number', value: 'phone', icon: Icons.phone_rounded),
          FollowUpOption(label: 'Email Address', value: 'email', icon: Icons.email_rounded),
          FollowUpOption(label: 'Emergency Contact', value: 'emergencyContact', icon: Icons.contact_phone_rounded),
          FollowUpOption(label: 'Clinical Notes', value: 'notes', icon: Icons.edit_note_rounded),
        ],
      );
    }

    if (!state.parameters.containsKey('newValue') ||
        state.parameters['newValue']?.toString().trim().isEmpty == true) {
      final fieldName = state.parameters['updatedField'];
      return FollowUpQuestion(
        id: 'update_value',
        targetField: 'newValue',
        promptText: 'Enter new value for $fieldName:',
        questionType: GenUiQuestionType.textInput,
      );
    }

    if (!state.isConfirmed) {
      final patientName = state.activePatient?.name ?? 'Patient';
      return FollowUpQuestion(
        id: 'update_confirmation',
        targetField: 'confirmed',
        promptText: 'Confirm updating ${state.parameters['updatedField']} to "${state.parameters['newValue']}" for $patientName:',
        questionType: GenUiQuestionType.confirmationCard,
        metadata: {
          'patientName': patientName,
          'field': state.parameters['updatedField'],
          'newValue': state.parameters['newValue'],
        },
      );
    }

    return null;
  }

  FollowUpQuestion? _resolvePatientLookupQuestion(
    ConversationWorkflowState state,
    List<PatientModel> existingPatients,
  ) {
    if (state.activePatient == null && !state.parameters.containsKey('patientId')) {
      return _buildPatientSelectionQuestion(
        'Select patient chart to open:',
        existingPatients,
      );
    }
    return null;
  }

  FollowUpQuestion _buildPatientSelectionQuestion(
    String prompt,
    List<PatientModel> existingPatients,
  ) {
    return FollowUpQuestion(
      id: 'select_patient',
      targetField: 'patientId',
      promptText: prompt,
      questionType: GenUiQuestionType.patientSelection,
      options: existingPatients.map((p) {
        return FollowUpOption(
          label: p.name,
          value: p.id,
          subtitle: 'ID: ${p.remoteId} • DOB: ${_formatDob(p.dateOfBirth)} • ${p.phone ?? p.emergencyContact}',
          icon: Icons.person_rounded,
          metadata: {'patient': p},
        );
      }).toList(),
    );
  }

  static String _formatDob(DateTime dob) {
    return '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
  }
}
