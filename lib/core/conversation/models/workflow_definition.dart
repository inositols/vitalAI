import 'package:equatable/equatable.dart';
import 'conversation_intent.dart';
import 'genui_question_type.dart';
import 'workflow_step.dart';

/// Declarative schema defining requirements, validation, steps and confirmation rules for an intent.
class WorkflowDefinition extends Equatable {
  final ConversationIntent intent;
  final String title;
  final String description;
  final List<WorkflowStep> steps;
  final List<String> requiredFields;
  final List<String> optionalFields;
  final bool requiresConfirmation;
  final bool isConsequential;

  const WorkflowDefinition({
    required this.intent,
    required this.title,
    required this.description,
    required this.steps,
    required this.requiredFields,
    this.optionalFields = const [],
    this.requiresConfirmation = true,
    this.isConsequential = true,
  });

  @override
  List<Object?> get props => [
        intent,
        title,
        description,
        steps,
        requiredFields,
        optionalFields,
        requiresConfirmation,
        isConsequential,
      ];

  /// Standard definitions for all supported intents in VoiceVitals.
  static final Map<ConversationIntent, WorkflowDefinition> registry = {
    // 1. Record Vital Signs (BP, Heart Rate, Temp, Glucose, etc.)
    ConversationIntent.recordVitals: const WorkflowDefinition(
      intent: ConversationIntent.recordVitals,
      title: 'Record Vital Signs',
      description: 'Record physiological vital signs observations for a patient.',
      requiredFields: ['patientId', 'systolic', 'diastolic'],
      optionalFields: ['pulseRate', 'bodyTemperature', 'tempUnit', 'date', 'note'],
      requiresConfirmation: true,
      isConsequential: true,
      steps: [
        WorkflowStep(
          key: 'patientId',
          label: 'Patient',
          questionPrompt: 'Which patient are you recording these vitals for?',
          uiType: GenUiQuestionType.patientSelection,
          isRequired: true,
        ),
        WorkflowStep(
          key: 'systolic',
          label: 'Systolic Blood Pressure',
          questionPrompt: 'What is the systolic reading in mmHg?',
          uiType: GenUiQuestionType.numericInput,
          unit: 'mmHg',
          isRequired: true,
        ),
        WorkflowStep(
          key: 'diastolic',
          label: 'Diastolic Blood Pressure',
          questionPrompt: 'What is the diastolic reading in mmHg?',
          uiType: GenUiQuestionType.numericInput,
          unit: 'mmHg',
          isRequired: true,
        ),
        WorkflowStep(
          key: 'pulseRate',
          label: 'Heart Rate',
          questionPrompt: 'Would you like to log the pulse rate (bpm)?',
          uiType: GenUiQuestionType.numericInput,
          unit: 'bpm',
          isRequired: false,
        ),
        WorkflowStep(
          key: 'date',
          label: 'Observation Date',
          questionPrompt: 'When was this reading taken?',
          uiType: GenUiQuestionType.datePicker,
          isRequired: false,
        ),
      ],
    ),

    // 2. Compare Vital Readings across dates
    ConversationIntent.compareVitals: const WorkflowDefinition(
      intent: ConversationIntent.compareVitals,
      title: 'Compare Vital Readings',
      description: 'Trend analysis comparing vital signs across selected date ranges.',
      requiredFields: ['patientId'],
      optionalFields: ['dateRange', 'metricType'],
      requiresConfirmation: false,
      isConsequential: false,
      steps: [
        WorkflowStep(
          key: 'patientId',
          label: 'Patient',
          questionPrompt: 'Which patient would you like to review vital trends for?',
          uiType: GenUiQuestionType.patientSelection,
          isRequired: true,
        ),
        WorkflowStep(
          key: 'dateRange',
          label: 'Comparison Period',
          questionPrompt: 'Select the comparison timeframe:',
          uiType: GenUiQuestionType.singleChoice,
          isRequired: false,
        ),
      ],
    ),

    // 3. Create Patient
    ConversationIntent.createPatient: const WorkflowDefinition(
      intent: ConversationIntent.createPatient,
      title: 'Create Patient Profile',
      description: 'Register a new clinical patient record with demographic and contact info.',
      requiredFields: ['name'],
      optionalFields: ['dateOfBirth', 'phone', 'email', 'gender'],
      requiresConfirmation: true,
      isConsequential: true,
      steps: [
        WorkflowStep(
          key: 'name',
          label: 'Patient Full Name',
          questionPrompt: 'What is the patient\'s full legal name?',
          uiType: GenUiQuestionType.textInput,
          isRequired: true,
        ),
        WorkflowStep(
          key: 'dateOfBirth',
          label: 'Date of Birth',
          questionPrompt: 'What is their date of birth?',
          uiType: GenUiQuestionType.datePicker,
          isRequired: false,
        ),
        WorkflowStep(
          key: 'phone',
          label: 'Phone Number',
          questionPrompt: 'What is their contact phone number?',
          uiType: GenUiQuestionType.textInput,
          isRequired: false,
        ),
        WorkflowStep(
          key: 'email',
          label: 'Email Address',
          questionPrompt: 'What is their email address?',
          uiType: GenUiQuestionType.textInput,
          isRequired: false,
        ),
        WorkflowStep(
          key: 'gender',
          label: 'Biological Sex',
          questionPrompt: 'Select biological sex for clinical baselines:',
          uiType: GenUiQuestionType.singleChoice,
          isRequired: false,
        ),
      ],
    ),

    // 4. Find Patient (Resolves ambiguous patient searches)
    ConversationIntent.findPatient: const WorkflowDefinition(
      intent: ConversationIntent.findPatient,
      title: 'Find Patient',
      description: 'Search and disambiguate patient identities across database.',
      requiredFields: ['query'],
      optionalFields: [],
      requiresConfirmation: false,
      isConsequential: false,
      steps: [
        WorkflowStep(
          key: 'patientId',
          label: 'Select Patient',
          questionPrompt: 'Multiple patients match your query. Please select one:',
          uiType: GenUiQuestionType.patientSelection,
          isRequired: true,
        ),
      ],
    ),

    // 5. Open Patient Details
    ConversationIntent.openPatientDetails: const WorkflowDefinition(
      intent: ConversationIntent.openPatientDetails,
      title: 'Open Patient Details',
      description: 'Open full patient clinical chart, medical history, and records.',
      requiredFields: ['patientId'],
      optionalFields: [],
      requiresConfirmation: false,
      isConsequential: false,
      steps: [
        WorkflowStep(
          key: 'patientId',
          label: 'Patient',
          questionPrompt: 'Which patient\'s chart would you like to open?',
          uiType: GenUiQuestionType.patientSelection,
          isRequired: true,
        ),
      ],
    ),

    // 6. Update Patient Info
    ConversationIntent.updatePatientInfo: const WorkflowDefinition(
      intent: ConversationIntent.updatePatientInfo,
      title: 'Update Patient Information',
      description: 'Update existing patient phone, emergency contact, or medical notes.',
      requiredFields: ['patientId', 'updatedField', 'newValue'],
      optionalFields: [],
      requiresConfirmation: true,
      isConsequential: true,
      steps: [
        WorkflowStep(
          key: 'patientId',
          label: 'Patient',
          questionPrompt: 'Which patient\'s record are you updating?',
          uiType: GenUiQuestionType.patientSelection,
          isRequired: true,
        ),
        WorkflowStep(
          key: 'updatedField',
          label: 'Field to Update',
          questionPrompt: 'Which detail would you like to update?',
          uiType: GenUiQuestionType.singleChoice,
          isRequired: true,
        ),
        WorkflowStep(
          key: 'newValue',
          label: 'New Value',
          questionPrompt: 'Enter the updated value:',
          uiType: GenUiQuestionType.textInput,
          isRequired: true,
        ),
      ],
    ),

    // 7. Draft Clinical Note
    ConversationIntent.draftClinicalNote: const WorkflowDefinition(
      intent: ConversationIntent.draftClinicalNote,
      title: 'Draft Clinical Note',
      description: 'Create and persist structured clinical encounter note or SOAP summary.',
      requiredFields: ['patientId', 'content'],
      optionalFields: ['visitType', 'date'],
      requiresConfirmation: true,
      isConsequential: true,
      steps: [
        WorkflowStep(
          key: 'patientId',
          label: 'Patient',
          questionPrompt: 'Which patient was this clinical encounter with?',
          uiType: GenUiQuestionType.patientSelection,
          isRequired: true,
        ),
        WorkflowStep(
          key: 'visitType',
          label: 'Encounter Type',
          questionPrompt: 'Select encounter note classification:',
          uiType: GenUiQuestionType.singleChoice,
          isRequired: false,
        ),
        WorkflowStep(
          key: 'content',
          label: 'Clinical Assessment & Plan',
          questionPrompt: 'Provide the visit assessment, observations, and recommendations:',
          uiType: GenUiQuestionType.textInput,
          isRequired: true,
        ),
      ],
    ),

    // 8. Follow-ups & Appointments / Reminders
    ConversationIntent.manageAppointments: const WorkflowDefinition(
      intent: ConversationIntent.manageAppointments,
      title: 'Follow-ups & Appointments',
      description: 'Create, modify or reschedule follow-up reminders and appointments.',
      requiredFields: ['patientId', 'title', 'time'],
      optionalFields: ['date', 'actionType'],
      requiresConfirmation: true,
      isConsequential: true,
      steps: [
        WorkflowStep(
          key: 'patientId',
          label: 'Patient',
          questionPrompt: 'Which patient is this appointment or reminder for?',
          uiType: GenUiQuestionType.patientSelection,
          isRequired: true,
        ),
        WorkflowStep(
          key: 'title',
          label: 'Appointment Purpose',
          questionPrompt: 'What is the purpose of this follow-up (e.g. BP Check, Medication Review)?',
          uiType: GenUiQuestionType.singleChoice,
          isRequired: true,
        ),
        WorkflowStep(
          key: 'time',
          label: 'Scheduled Time',
          questionPrompt: 'Select or enter the intended scheduled time:',
          uiType: GenUiQuestionType.singleChoice,
          isRequired: true,
        ),
      ],
    ),

    // 9. Query Patient History & Summaries
    ConversationIntent.queryPatientHistory: const WorkflowDefinition(
      intent: ConversationIntent.queryPatientHistory,
      title: 'Patient History & Summaries',
      description: 'Query and review patient longitudinal medical history, vitals, visits, and notes.',
      requiredFields: ['patientId'],
      optionalFields: ['category', 'timeframe'],
      requiresConfirmation: false,
      isConsequential: false,
      steps: [
        WorkflowStep(
          key: 'patientId',
          label: 'Patient',
          questionPrompt: 'Which patient\'s history would you like to review?',
          uiType: GenUiQuestionType.patientSelection,
          isRequired: true,
        ),
        WorkflowStep(
          key: 'category',
          label: 'Filter Categories',
          questionPrompt: 'Select records to include:',
          uiType: GenUiQuestionType.multiSelect,
          isRequired: false,
        ),
        WorkflowStep(
          key: 'timeframe',
          label: 'Time Range',
          questionPrompt: 'Select time range:',
          uiType: GenUiQuestionType.singleChoice,
          isRequired: false,
        ),
      ],
    ),
  };
}
