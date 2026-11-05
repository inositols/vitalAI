import 'package:uuid/uuid.dart';
import '../../../../features/activity/data/models/activity_item.dart';
import '../../../../features/activity/domain/repositories/activity_repository.dart';
import '../../../../features/patients/data/models/clinical_note.dart';
import '../../../../features/patients/data/models/patient_model.dart';
import '../../../../features/patients/domain/repositories/patient_repository.dart';
import '../../../../features/reminders/data/models/reminder_model.dart';
import '../../../../features/reminders/domain/repositories/reminder_repository.dart';
import '../../../../features/vitals/data/models/vital_record.dart';
import '../../../../features/vitals/domain/repositories/vitals_repository.dart';
import '../../di/injection.dart';
import '../../database/db_service.dart';
import '../../services/clinical_data_seeder.dart';
import '../../../../features/patients/presentation/bloc/patient_bloc.dart';
import '../../../../features/patients/presentation/bloc/patient_event.dart';
import '../../../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../../../features/settings/presentation/bloc/settings_event.dart';
import '../../services/ai_service.dart';
import '../models/conversation_intent.dart';
import '../models/conversation_workflow_state.dart';

/// Allowlisted application action types.
enum AppActionType {
  saveVitalRecord,
  createPatient,
  updatePatientInfo,
  saveClinicalNote,
  createReminder,
  cancelReminder,
  queryPatientHistory,
  compareVitals,
  openPatientDetails,
  generalQuery,
}

/// Execution outcome returned by ActionExecutor.
class ActionExecutionResult {
  final bool isSuccess;
  final String summaryText;
  final dynamic data;
  final String? errorMessage;
  final AppActionType actionType;

  const ActionExecutionResult({
    required this.isSuccess,
    required this.summaryText,
    required this.actionType,
    this.data,
    this.errorMessage,
  });

  factory ActionExecutionResult.success({
    required String summaryText,
    required AppActionType actionType,
    dynamic data,
  }) =>
      ActionExecutionResult(
        isSuccess: true,
        summaryText: summaryText,
        actionType: actionType,
        data: data,
      );

  factory ActionExecutionResult.failure({
    required String errorMessage,
    required AppActionType actionType,
  }) =>
      ActionExecutionResult(
        isSuccess: false,
        summaryText: 'Action failed: $errorMessage',
        actionType: actionType,
        errorMessage: errorMessage,
      );
}

/// Authorized Application Execution Layer controlling all database reads and writes.
class ActionExecutor {
  final PatientRepository patientRepository;
  final VitalsRepository vitalsRepository;
  final ReminderRepository reminderRepository;
  final ActivityRepository? activityRepository;
  final AiService? aiService;

  // Authorization flag - can check provider authentication credentials
  final bool isAuthorizedProvider;

  ActionExecutor({
    required this.patientRepository,
    required this.vitalsRepository,
    required this.reminderRepository,
    this.activityRepository,
    this.aiService,
    this.isAuthorizedProvider = true,
  });

  /// Executes an authorized action based on the active workflow state.
  Future<ActionExecutionResult> executeWorkflowAction(ConversationWorkflowState state) async {
    // 1. Strict Authorization Guard
    if (!isAuthorizedProvider) {
      return ActionExecutionResult.failure(
        errorMessage: 'Unauthorized access. Valid healthcare provider credentials are required.',
        actionType: _mapIntentToAction(state.intent),
      );
    }

    // 2. Strict Confirmation Requirement for Consequential Actions
    if (state.intent.isConsequentialWrite && !state.isConfirmed) {
      return ActionExecutionResult.failure(
        errorMessage: 'Consequential action requires explicit confirmation before execution.',
        actionType: _mapIntentToAction(state.intent),
      );
    }

    // 3. Dispatch to authorized execution routine
    try {
      switch (state.intent) {
        case ConversationIntent.recordVitals:
          return await _executeRecordVitals(state);

        case ConversationIntent.createPatient:
          return await _executeCreatePatient(state);

        case ConversationIntent.updatePatientInfo:
          return await _executeUpdatePatient(state);

        case ConversationIntent.draftClinicalNote:
          return await _executeSaveNote(state);

        case ConversationIntent.manageAppointments:
          return await _executeManageAppointment(state);

        case ConversationIntent.compareVitals:
          return await _executeCompareVitals(state);

        case ConversationIntent.queryPatientHistory:
          return await _executeQueryHistory(state);

        case ConversationIntent.openPatientDetails:
        case ConversationIntent.findPatient:
          return await _executeOpenPatient(state);

        case ConversationIntent.generalQuery:
          return await _executeGeneralQuery(state);
      }
    } catch (e) {
      return ActionExecutionResult.failure(
        errorMessage: 'Database operation failed: ${e.toString()}',
        actionType: _mapIntentToAction(state.intent),
      );
    }
  }

  Future<ActionExecutionResult> _executeRecordVitals(ConversationWorkflowState state) async {
    final patientId = state.activePatient?.id ?? (state.parameters['patientId'] as int);
    final patientName = state.activePatient?.name ?? state.parameters['patientName'] ?? 'Patient';

    final systolic = (state.parameters['systolic'] as num).toDouble();
    final diastolic = (state.parameters['diastolic'] as num).toDouble();
    final pulse = (state.parameters['pulseRate'] as num?)?.toDouble();
    final temp = (state.parameters['bodyTemperature'] as num?)?.toDouble();
    final obsDate = state.parameters['date'] as DateTime? ?? DateTime.now();

    final record = VitalRecord()
      ..patientId = patientId
      ..systolic = systolic
      ..diastolic = diastolic
      ..pulseRate = pulse
      ..bodyTemperature = bodyTemperatureInCelsius(temp, state.parameters['tempUnit'])
      ..dateTime = obsDate
      ..updatedAt = DateTime.now();

    await vitalsRepository.saveVitalRecord(record);

    // Audit log
    await activityRepository?.logActivity(
      ActivityItem(
        patientId: patientId,
        patientName: patientName,
        title: 'Blood Pressure Recorded',
        subtitle: '$systolic/$diastolic mmHg for $patientName',
        category: ActivityCategory.vitals,
        timestamp: DateTime.now(),
      ),
    );

    return ActionExecutionResult.success(
      summaryText: 'Successfully recorded $systolic/$diastolic mmHg for $patientName.',
      actionType: AppActionType.saveVitalRecord,
      data: record,
    );
  }

  Future<ActionExecutionResult> _executeCreatePatient(ConversationWorkflowState state) async {
    final name = state.parameters['name']?.toString().trim() ?? '';
    final dob = state.parameters['dateOfBirth'] as DateTime? ??
        DateTime.now().subtract(const Duration(days: 365 * 30));
    final phone = state.parameters['phone']?.toString();
    final email = state.parameters['email']?.toString();
    final gender = state.parameters['gender']?.toString() ?? 'Male';

    final patient = PatientModel()
      ..name = name
      ..dateOfBirth = dob
      ..phone = phone
      ..email = email
      ..gender = gender
      ..emergencyContact = phone ?? ''
      ..updatedAt = DateTime.now();

    final complaint = state.parameters['complaint']?.toString();
    if (complaint != null && complaint.isNotEmpty) {
      patient.notes = complaint;
    }

    await patientRepository.savePatient(patient);

    // Save initial vitals if provided during creation
    final systolic = (state.parameters['systolic'] as num?)?.toDouble();
    final diastolic = (state.parameters['diastolic'] as num?)?.toDouble();
    if (systolic != null && diastolic != null) {
      final initialRecord = VitalRecord()
        ..patientId = patient.id
        ..systolic = systolic
        ..diastolic = diastolic
        ..dateTime = DateTime.now()
        ..updatedAt = DateTime.now();
      await vitalsRepository.saveVitalRecord(initialRecord);
    }

    await activityRepository?.logActivity(
      ActivityItem(
        patientId: patient.id,
        patientName: patient.name,
        title: 'New Patient Registered',
        subtitle: 'Profile created for ${patient.name}',
        category: ActivityCategory.patients,
        timestamp: DateTime.now(),
      ),
    );

    return ActionExecutionResult.success(
      summaryText: 'Successfully created patient profile for ${patient.name}.',
      actionType: AppActionType.createPatient,
      data: patient,
    );
  }

  Future<ActionExecutionResult> _executeUpdatePatient(ConversationWorkflowState state) async {
    final patientId = state.activePatient?.id ?? (state.parameters['patientId'] as int);
    final patient = await patientRepository.getPatientById(patientId);
    if (patient == null) {
      return ActionExecutionResult.failure(
        errorMessage: 'Patient ID $patientId not found.',
        actionType: AppActionType.updatePatientInfo,
      );
    }

    final field = state.parameters['updatedField']?.toString();
    final newValue = state.parameters['newValue']?.toString() ?? '';

    if (field == 'phone') {
      patient.phone = newValue;
    } else if (field == 'email') {
      patient.email = newValue;
    } else if (field == 'emergencyContact') {
      patient.emergencyContact = newValue;
    } else if (field == 'notes') {
      patient.notes = newValue;
    }
    patient.updatedAt = DateTime.now();

    await patientRepository.savePatient(patient);

    await activityRepository?.logActivity(
      ActivityItem(
        patientId: patient.id,
        patientName: patient.name,
        title: 'Patient Record Updated',
        subtitle: 'Updated $field for ${patient.name}',
        category: ActivityCategory.patients,
        timestamp: DateTime.now(),
      ),
    );

    return ActionExecutionResult.success(
      summaryText: 'Updated $field for ${patient.name}.',
      actionType: AppActionType.updatePatientInfo,
      data: patient,
    );
  }

  Future<ActionExecutionResult> _executeSaveNote(ConversationWorkflowState state) async {
    final patientId = state.activePatient?.id ?? (state.parameters['patientId'] as int);
    final patientName = state.activePatient?.name ?? state.parameters['patientName'] ?? 'Patient';

    final note = ClinicalNote(
      patientId: patientId,
      visitType: state.parameters['visitType']?.toString() ?? 'General Consultation',
      content: state.parameters['content']?.toString() ?? '',
      authorName: 'Dr. Adeyemi',
      date: DateTime.now(),
      isDraft: false,
    );

    await patientRepository.saveClinicalNote(note);

    await activityRepository?.logActivity(
      ActivityItem(
        patientId: patientId,
        patientName: patientName,
        title: 'Clinical Note Saved',
        subtitle: '${note.visitType} for $patientName',
        category: ActivityCategory.notes,
        timestamp: DateTime.now(),
      ),
    );

    return ActionExecutionResult.success(
      summaryText: 'Saved clinical note for $patientName.',
      actionType: AppActionType.saveClinicalNote,
      data: note,
    );
  }

  Future<ActionExecutionResult> _executeManageAppointment(ConversationWorkflowState state) async {
    final patientId = state.activePatient?.id ?? (state.parameters['patientId'] as int);
    final patientName = state.activePatient?.name ?? state.parameters['patientName'] ?? 'Patient';

    final title = state.parameters['title']?.toString() ?? 'Follow-up Appointment';
    final timeStr = state.parameters['time']?.toString() ?? '09:00 AM';

    // Parse hour / minute
    int hour = 9;
    int minute = 0;
    final match = RegExp(r'(\d{1,2}):?(\d{2})?\s*(am|pm)?', caseSensitive: false).firstMatch(timeStr);
    if (match != null) {
      hour = int.tryParse(match.group(1)!) ?? 9;
      minute = int.tryParse(match.group(2) ?? '0') ?? 0;
      final amPm = match.group(3)?.toLowerCase();
      if (amPm == 'pm' && hour < 12) hour += 12;
      if (amPm == 'am' && hour == 12) hour = 0;
    }

    final reminder = ReminderModel(
      id: const Uuid().v4(),
      patientId: patientId,
      title: title,
      time: timeStr,
      hour: hour,
      minute: minute,
      createdAt: DateTime.now(),
    );

    await reminderRepository.addReminder(reminder);

    await activityRepository?.logActivity(
      ActivityItem(
        patientId: patientId,
        patientName: patientName,
        title: 'Follow-up Appointment Scheduled',
        subtitle: '$title at $timeStr for $patientName',
        category: ActivityCategory.patients,
        timestamp: DateTime.now(),
      ),
    );

    return ActionExecutionResult.success(
      summaryText: 'Scheduled $title for $patientName at $timeStr.',
      actionType: AppActionType.createReminder,
      data: reminder,
    );
  }

  Future<ActionExecutionResult> _executeCompareVitals(ConversationWorkflowState state) async {
    final patientId = state.activePatient?.id ?? (state.parameters['patientId'] as int);
    final vitals = await vitalsRepository.getVitals(patientId);

    return ActionExecutionResult.success(
      summaryText: 'Retrieved ${vitals.length} readings for comparison.',
      actionType: AppActionType.compareVitals,
      data: vitals,
    );
  }

  Future<ActionExecutionResult> _executeQueryHistory(ConversationWorkflowState state) async {
    final patientId = state.activePatient?.id ?? (state.parameters['patientId'] as int);
    final vitals = await vitalsRepository.getVitals(patientId);
    final notes = await patientRepository.getClinicalNotes(patientId);

    return ActionExecutionResult.success(
      summaryText: 'Found ${vitals.length} vitals readings and ${notes.length} clinical notes.',
      actionType: AppActionType.queryPatientHistory,
      data: {'vitals': vitals, 'notes': notes},
    );
  }

  Future<ActionExecutionResult> _executeOpenPatient(ConversationWorkflowState state) async {
    final patientId = state.activePatient?.id ?? (state.parameters['patientId'] as int);
    final patient = await patientRepository.getPatientById(patientId);

    if (patient == null) {
      return ActionExecutionResult.failure(
        errorMessage: 'Patient ID $patientId not found.',
        actionType: AppActionType.openPatientDetails,
      );
    }

    return ActionExecutionResult.success(
      summaryText: 'Opened clinical chart for ${patient.name}.',
      actionType: AppActionType.openPatientDetails,
      data: patient,
    );
  }

  Future<ActionExecutionResult> _executeGeneralQuery(ConversationWorkflowState state) async {
    final utterance = state.lastUserUtterance;
    final lower = utterance.toLowerCase().trim();

    // 0. Enable AI Consent direct conversational command
    if (lower.contains('enable ai') ||
        lower.contains('grant consent') ||
        lower.contains('grant ai') ||
        lower.contains('allow ai') ||
        lower.contains('turn on ai') ||
        lower.contains('activate ai')) {
      if (locator.isRegistered<SettingsBloc>()) {
        locator<SettingsBloc>().add(const AiConsentToggled(true));
      }
      return ActionExecutionResult.success(
        summaryText:
            "✓ AI Data Sharing has been successfully enabled! Live Gemini AI clinical insights and assistant features are now active.",
        actionType: AppActionType.generalQuery,
        data: "ai_consent_enabled",
      );
    }

    // 0b. Remove unadded demo patients command
    if (lower.contains('remove all patients') ||
        lower.contains('clear demo') ||
        lower.contains('delete demo') ||
        lower.contains('remove demo') ||
        lower.contains('patients i didn\'t add') ||
        lower.contains('patients i didnt add') ||
        lower.contains('remove default patients') ||
        lower.contains('delete all patients')) {
      if (locator.isRegistered<DbService>()) {
        await ClinicalDataSeeder.purgeDemoPatients(locator<DbService>());
      }
      if (locator.isRegistered<PatientBloc>()) {
        locator<PatientBloc>().add(PatientListRequested());
      }
      return ActionExecutionResult.success(
        summaryText:
            "✓ All pre-seeded demo patients and sample records have been removed. Your patient list is now completely clean, and you can add your own patients through chat.",
        actionType: AppActionType.generalQuery,
        data: "purged_demo_patients",
      );
    }

    // 0c. List all patients query
    if (lower == 'show my patients' ||
        lower == 'list patients' ||
        lower == 'view patients' ||
        lower == 'show patients' ||
        lower == 'all patients' ||
        lower == 'my patients' ||
        lower.contains('how many patients')) {
      final allPatients = await patientRepository.getPatients();
      if (allPatients.isEmpty) {
        return ActionExecutionResult.success(
          summaryText:
              "You don't have any patients in your records yet. Would you like to add a new patient now? Simply tell me their details, e.g. 'Add Chika Okafor, 28 years old.'",
          actionType: AppActionType.generalQuery,
          data: allPatients,
        );
      }
      return ActionExecutionResult.success(
        summaryText:
            "You currently have ${allPatients.length} patient${allPatients.length == 1 ? '' : 's'} recorded:",
        actionType: AppActionType.generalQuery,
        data: allPatients,
      );
    }

    // 1. High blood pressure patients query
    if (lower.contains('high blood pressure') || lower.contains('hypertension') || lower.contains('high bp')) {
      final allPatients = await patientRepository.getPatients();
      final List<PatientModel> highBpPatients = [];
      for (final p in allPatients) {
        final vitals = await vitalsRepository.getVitals(p.id);
        if (vitals.isNotEmpty) {
          final latest = vitals.first;
          if ((latest.systolic != null && latest.systolic! >= 130) ||
              (latest.diastolic != null && latest.diastolic! >= 80)) {
            highBpPatients.add(p);
          }
        } else if (p.medicalConditions.any((c) => c.toLowerCase().contains('hypertension'))) {
          highBpPatients.add(p);
        }
      }

      final summary = highBpPatients.isNotEmpty
          ? 'Found ${highBpPatients.length} patient${highBpPatients.length == 1 ? '' : 's'} with elevated or high blood pressure readings:'
          : 'No patients currently have elevated blood pressure recorded in the system.';

      return ActionExecutionResult.success(
        summaryText: summary,
        actionType: AppActionType.generalQuery,
        data: highBpPatients.isNotEmpty ? highBpPatients : allPatients,
      );
    }

    // 2. Try AiService if configured AND consented
    if (aiService != null && aiService!.isConfigured && aiService!.hasConsent) {
      try {
        final aiAnswer = await aiService!.askAssistant(utterance);
        if (aiAnswer.trim().isNotEmpty &&
            !aiAnswer.toLowerCase().contains('consent required')) {
          return ActionExecutionResult.success(
            summaryText: aiAnswer,
            actionType: AppActionType.generalQuery,
            data: aiAnswer,
          );
        }
      } catch (_) {}
    }

    // 3. Clinical domain conversational responses (offline, PHI-safe)
    final answer = _generateClinicalGeneralAnswer(utterance);
    return ActionExecutionResult.success(
      summaryText: answer,
      actionType: AppActionType.generalQuery,
      data: answer,
    );
  }

  String _generateClinicalGeneralAnswer(String utterance) {
    final lower = utterance.toLowerCase().trim();

    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('good morning') ||
        lower.contains('good afternoon') ||
        lower.contains('good evening')) {
      return "Hello! I am VitalAI, your clinical assistant. How can I help you manage your patients, review vital signs, or draft notes today?";
    }

    if (lower.contains('consent') || lower.contains('ai sharing') || lower.contains('privacy')) {
      return "To safeguard patient confidentiality, VitalAI requires consent before sending health records to cloud AI services. You can toggle AI Data Sharing anytime in Profile > Settings or by saying 'Enable AI'.";
    }

    if (lower.contains('normal blood pressure') || lower.contains('normal bp') || lower.contains('target bp')) {
      return "Normal resting adult blood pressure is defined as systolic below 120 mmHg and diastolic below 80 mmHg. Elevated is 120–129/<80 mmHg, Stage 1 Hypertension is 130–139/80–89 mmHg, and Stage 2 Hypertension is ≥140/≥90 mmHg.";
    }

    if (lower.contains('heart rate') || lower.contains('pulse') || lower.contains('tachycardia') || lower.contains('bradycardia')) {
      return "Normal resting adult heart rate is 60–100 beats per minute (bpm). A resting rate consistently over 100 bpm is tachycardia, while below 60 bpm is bradycardia (which can be normal in endurance athletes).";
    }

    if (lower.contains('temperature') || lower.contains('fever')) {
      return "Normal core body temperature ranges from 36.5 °C to 37.5 °C (97.7 °F – 99.5 °F). A core reading of 38.0 °C (100.4 °F) or above is classified as a fever (pyrexia).";
    }

    if (lower.contains('oxygen') || lower.contains('spo2') || lower.contains('saturation')) {
      return "Normal peripheral blood oxygen saturation (SpO2) ranges between 95% and 100%. Readings consistently below 90% indicate hypoxemia requiring immediate clinical evaluation.";
    }

    if (lower.contains('vital signs') || lower.contains('vitals range') || lower.contains('normal vitals')) {
      return "Standard resting adult vitals reference ranges:\n• Blood Pressure: <120/80 mmHg\n• Heart Rate: 60–100 bpm\n• Body Temperature: 36.5–37.5 °C (97.7–99.5 °F)\n• Oxygen Saturation (SpO2): 95–100%\n• Respiratory Rate: 12–20 breaths/min.";
    }

    if (lower.contains('what can you do') || lower.contains('help') || lower.contains('features')) {
      return "I can assist you with:\n• Registering new patients and drafting records\n• Logging vital signs via speech or text\n• Analyzing vital trends and comparing 7-day readings\n• Drafting clinical encounter visit notes\n• Scheduling appointments and follow-up reminders.";
    }

    return "I've received your request. I can assist you with adding patients, recording vitals, tracking trends, and drafting clinical visit notes.";
  }

  AppActionType _mapIntentToAction(ConversationIntent intent) {
    switch (intent) {
      case ConversationIntent.recordVitals:
        return AppActionType.saveVitalRecord;
      case ConversationIntent.createPatient:
        return AppActionType.createPatient;
      case ConversationIntent.updatePatientInfo:
        return AppActionType.updatePatientInfo;
      case ConversationIntent.draftClinicalNote:
        return AppActionType.saveClinicalNote;
      case ConversationIntent.manageAppointments:
        return AppActionType.createReminder;
      case ConversationIntent.compareVitals:
        return AppActionType.compareVitals;
      case ConversationIntent.queryPatientHistory:
        return AppActionType.queryPatientHistory;
      case ConversationIntent.generalQuery:
        return AppActionType.generalQuery;
      default:
        return AppActionType.openPatientDetails;
    }
  }

  static double? bodyTemperatureInCelsius(double? temp, dynamic unit) {
    if (temp == null) return null;
    if (unit?.toString().toUpperCase() == 'F' || temp > 50) {
      return (temp - 32) * 5 / 9;
    }
    return temp;
  }
}
