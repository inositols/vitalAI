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

  // Authorization flag - can check provider authentication credentials
  final bool isAuthorizedProvider;

  ActionExecutor({
    required this.patientRepository,
    required this.vitalsRepository,
    required this.reminderRepository,
    this.activityRepository,
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

        default:
          return ActionExecutionResult.failure(
            errorMessage: 'Unsupported action for intent ${state.intent}.',
            actionType: _mapIntentToAction(state.intent),
          );
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

    await patientRepository.savePatient(patient);

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
