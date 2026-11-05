import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/voice_vitals_top_bar.dart';
import '../../../../core/services/ai_audio_service.dart';
import '../../../../core/services/clinical_function_router.dart';
import '../../../../core/di/injection.dart';
import '../../../patients/presentation/bloc/patient_bloc.dart';
import '../../../patients/presentation/bloc/patient_event.dart';
import '../../../patients/presentation/bloc/patient_state.dart';
import '../../../patients/data/models/patient_model.dart';
import '../../../patients/data/models/clinical_note.dart';
import '../../../patients/domain/models/patient_draft.dart';
import '../../../patients/domain/services/patient_creation_service.dart';
import '../../../patients/presentation/widgets/conversational_patient_creation_card.dart';
import '../../../patients/domain/repositories/patient_repository.dart';
import '../../../patients/presentation/pages/patient_details_page.dart';
import '../../../vitals/presentation/pages/confirm_vital_page.dart';
import '../../../activity/data/models/activity_item.dart';
import '../../../activity/presentation/bloc/activity_bloc.dart';
import '../../../activity/presentation/bloc/activity_event.dart';
import '../../../activity/presentation/bloc/activity_state.dart';
import 'dart:async';
import '../widgets/voice_listening_view.dart';
import '../widgets/clinical_comparison_chart_card.dart';
import '../../../../core/conversation/bloc/conversation_workflow_bloc.dart';
import '../../../../core/conversation/bloc/conversation_workflow_event.dart';
import '../../../../core/conversation/models/conversation_intent.dart';
import '../../../../core/conversation/models/conversation_workflow_state.dart';
import '../../../../core/conversation/models/workflow_status.dart';
import '../../../../core/conversation/widgets/adaptive_genui_follow_up_card.dart';
import '../../../vitals/data/models/vital_record.dart';
import '../../../../core/genui/models/genui_action.dart';
import '../../../../core/genui/models/genui_component.dart';
import '../../../../core/genui/components/suggestion_card.dart';
import '../../../../core/genui/services/suggestion_service.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_event.dart';

enum AssistantUiState {
  idle,
  listening,
  processing,
  responding,
  error,
  permissionRequired,
}

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage>
    with SingleTickerProviderStateMixin {
  AssistantUiState _uiState = AssistantUiState.idle;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Speech-to-text
  stt.SpeechToText? _speech;
  bool _speechAvailable = false;
  String _currentTranscript = '';

  // Conversational state
  final List<Map<String, dynamic>> _messages = [];
  bool _isTtsPlaying = false;

  // Universal Conversational Workflow BLoC
  late final ConversationWorkflowBloc _workflowBloc;
  StreamSubscription<ConversationWorkflowState>? _workflowSubscription;

  // Conversational patient creation
  final PatientCreationService _patientCreationService =
      PatientCreationService();
  PatientDraft? _activePatientDraft;

  final List<String> _suggestedPrompts = [
    'Show me my patients with high blood pressure.',
    "Open Chika's latest vitals.",
    'Draft a note for my current visit.',
    'Create a new patient.',
    "Compare Chika's blood pressure from last week to this week.",
  ];

  @override
  void initState() {
    super.initState();
    _workflowBloc = locator<ConversationWorkflowBloc>();
    _workflowSubscription = _workflowBloc.stream.listen(
      _handleWorkflowStateChange,
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speech = stt.SpeechToText();
      bool available = await _speech!.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_uiState == AssistantUiState.listening &&
                _currentTranscript.isNotEmpty) {
              _processTranscript(_currentTranscript);
            }
          }
        },
        onError: (err) {
          debugPrint('Speech engine notification: $err');
        },
      );
      if (mounted) {
        setState(() {
          _speechAvailable = available;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _speechAvailable = false);
      }
    }
  }

  @override
  void dispose() {
    _speech?.stop();
    _workflowSubscription?.cancel();
    _workflowBloc.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _startVoiceListening() async {
    setState(() {
      _currentTranscript = '';
      _uiState = AssistantUiState.listening;
    });

    if (!_speechAvailable) {
      // Simulate real-time voice speech for desktop/emulator or when mic uninitialized
      _simulateVoiceTyping(
        "I want to record my blood pressure. It's 118 over 76.",
      );
      return;
    }

    try {
      await _speech!.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _currentTranscript = result.recognizedWords;
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          partialResults: true,
        ),
      );
    } catch (e) {
      // Graceful fallback to voice simulation
      _simulateVoiceTyping(
        "I want to record my blood pressure. It's 118 over 76.",
      );
    }
  }

  void _simulateVoiceTyping(String sample) async {
    final words = sample.split(' ');
    String buffer = '';
    for (int i = 0; i < words.length; i++) {
      if (_uiState != AssistantUiState.listening) return;
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted || _uiState != AssistantUiState.listening) return;
      buffer = words.sublist(0, i + 1).join(' ');
      setState(() {
        _currentTranscript = buffer;
      });
    }
  }

  void _stopVoiceListening() {
    try {
      _speech?.stop();
    } catch (_) {}

    if (_currentTranscript.trim().isNotEmpty) {
      _processTranscript(_currentTranscript.trim());
    } else {
      setState(() => _uiState = AssistantUiState.idle);
    }
  }

  void _cancelVoiceListening() {
    try {
      _speech?.stop();
    } catch (_) {}
    setState(() {
      _currentTranscript = '';
      _uiState = AssistantUiState.idle;
    });
  }

  void _processTranscript(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;

    // 0. If legacy patient draft is currently active, route the input to it
    if (_activePatientDraft != null &&
        _activePatientDraft!.currentStep != PatientCreationStep.completed &&
        _activePatientDraft!.currentStep != PatientCreationStep.cancelled) {
      _handlePatientCreationStep(trimmed);
      return;
    }

    setState(() {
      _uiState = AssistantUiState.processing;
      _messages.add({'sender': 'user', 'text': trimmed});
    });

    _scrollToBottom();

    final existingPatients = _getExistingPatients();
    _workflowBloc.add(
      ConversationUtteranceSubmitted(
        trimmed,
        existingPatients: existingPatients,
      ),
    );
  }

  void _handleWorkflowStateChange(ConversationWorkflowState state) {
    if (!mounted) return;

    if (state.status == WorkflowStatus.idle) {
      setState(() => _uiState = AssistantUiState.idle);
      return;
    }

    if (state.status == WorkflowStatus.interpretingRequest ||
        state.status == WorkflowStatus.executingAction) {
      setState(() => _uiState = AssistantUiState.processing);
      return;
    }

    if (state.status.isInteractive && state.currentQuestion != null) {
      final question = state.currentQuestion!;
      final questionText = question.promptText;

      final followUpWidget = AdaptiveGenUiFollowUpCard(
        question: question,
        state: state,
        onAnswer: (val) {
          final patients = _getExistingPatients();
          _workflowBloc.add(
            ConversationOptionSelected(
              question.targetField,
              val,
              existingPatients: patients,
            ),
          );
        },
        onConfirm: () {
          _workflowBloc.add(const ConversationWorkflowConfirmed());
        },
        onCancel: () {
          _workflowBloc.add(const ConversationWorkflowCancelled());
        },
        onSkip: () {
          final patients = _getExistingPatients();
          _workflowBloc.add(
            ConversationOptionSelected(
              'skip_${question.targetField}',
              true,
              existingPatients: patients,
            ),
          );
        },
        onBack: () {
          _workflowBloc.add(const ConversationStepBackRequested());
        },
      );

      setState(() {
        _updateOrAddAiMessage(questionText, followUpWidget);
        _uiState = AssistantUiState.responding;
      });

      _speakText(questionText);
      _scrollToBottom();
      return;
    }

    if (state.status == WorkflowStatus.completed) {
      String responseText = '';
      Widget? resultWidget;

      switch (state.intent) {
        case ConversationIntent.recordVitals:
          final vitals = state.executionResult as VitalRecord?;
          final sys =
              vitals?.systolic?.toInt() ??
              (state.parameters['systolic'] as num?)?.toInt() ??
              120;
          final dia =
              vitals?.diastolic?.toInt() ??
              (state.parameters['diastolic'] as num?)?.toInt() ??
              80;
          final name =
              state.activePatient?.name ??
              state.parameters['patientName'] ??
              'patient';
          responseText =
              "Blood pressure reading ($sys/$dia mmHg) recorded successfully for $name.";
          resultWidget = _buildGenUiVitalSummary();
          break;

        case ConversationIntent.createPatient:
          final p = state.executionResult as PatientModel?;
          final name = p?.name ?? state.parameters['name'] ?? 'new patient';
          responseText = "Patient $name has been registered successfully.";
          resultWidget = _buildGenUiPatientList();
          break;

        case ConversationIntent.draftClinicalNote:
          final name =
              state.activePatient?.name ??
              state.parameters['patientName'] ??
              'patient';
          responseText =
              "Clinical note has been saved to $name's medical record.";
          resultWidget = _buildGenUiNoteDraft();
          break;

        case ConversationIntent.manageAppointments:
          final name =
              state.activePatient?.name ??
              state.parameters['patientName'] ??
              'patient';
          responseText = "Follow-up appointment for $name has been scheduled.";
          break;

        case ConversationIntent.compareVitals:
          final name = state.activePatient?.name ?? 'Chika Okafor';
          responseText =
              "Here's $name's blood pressure trend for the last 7 days, compared to the previous 7 days.";
          resultWidget = ClinicalComparisonChartCard(
            patientName: name,
            latestReading: '118/76 mmHg',
            latestTimestamp: 'Apr 26, 2025 • 09:41 AM',
          );
          break;

        case ConversationIntent.queryPatientHistory:
          final name = state.activePatient?.name ?? 'Chika Okafor';
          responseText = "Here is the clinical history summary for $name:";
          resultWidget = _buildGenUiRecentActivity();
          break;

        case ConversationIntent.openPatientDetails:
        case ConversationIntent.findPatient:
          final name = state.activePatient?.name ?? 'Chika Okafor';
          responseText = "Opening clinical profile and chart for $name:";
          resultWidget = _buildGenUiPatientList();
          break;

        case ConversationIntent.generalQuery:
          if (state.executionResult is List<PatientModel>) {
            final list = state.executionResult as List<PatientModel>;
            responseText =
                "Found ${list.length} patient${list.length == 1 ? '' : 's'} with high blood pressure:";
            resultWidget = _buildGenUiPatientList();
          } else if (state.executionResult is String) {
            responseText = state.executionResult as String;
          } else {
            responseText = "I'm ready to assist with your clinical workflow.";
          }
          break;

        default:
          if (state.executionResult is String) {
            responseText = state.executionResult as String;
          } else {
            responseText = "Operation completed successfully.";
          }
          break;
      }

      // Refresh patients list in context
      try {
        context.read<PatientBloc>().add(PatientListRequested());
      } catch (_) {}

      final suggestions = locator<SuggestionService>().resolveSuggestions(
        intent: state.intent.name,
        workflowStatus: state.status.name,
        patientId: state.activePatient?.id.toString(),
        patientName: state.activePatient?.name,
        hasCompletedAction: true,
        hasAiConsent: _hasAiConsent(),
      );

      setState(() {
        _updateOrAddAiMessage(
          responseText,
          resultWidget,
          suggestions: suggestions,
        );
        _uiState = AssistantUiState.responding;
      });

      _speakText(responseText);
      _scrollToBottom();
      return;
    }

    if (state.status == WorkflowStatus.failed) {
      final err =
          state.errorMessage ??
          'An error occurred while executing the request.';
      setState(() {
        _updateOrAddAiMessage('Unable to complete request: $err', null);
        _uiState = AssistantUiState.responding;
      });
      _speakText('Unable to complete request: $err');
      _scrollToBottom();
      return;
    }

    if (state.status == WorkflowStatus.cancelled) {
      setState(() {
        _updateOrAddAiMessage('Workflow was cancelled.', null);
        _uiState = AssistantUiState.responding;
      });
      _speakText('Workflow cancelled.');
      _scrollToBottom();
      return;
    }
  }

  void _updateOrAddAiMessage(
    String text,
    Widget? widget, {
    List<GenUiAction>? suggestions,
  }) {
    if (_messages.isNotEmpty &&
        _messages.last['sender'] == 'ai' &&
        _messages.last['isWorkflow'] == true) {
      _messages.last['text'] = text;
      _messages.last['widget'] = widget;
      _messages.last['suggestions'] = suggestions;
    } else {
      _messages.add({
        'sender': 'ai',
        'text': text,
        'widget': widget,
        'suggestions': suggestions,
        'isWorkflow': true,
      });
    }
  }

  void _handleGenUiAction(GenUiAction action) {
    switch (action.type) {
      case GenUiActionType.compareVitals:
        final name = action.payload['patientName'] ?? 'Chika Okafor';
        _processTranscript(
          "Compare $name's blood pressure from last week to this week.",
        );
        break;
      case GenUiActionType.viewVitalHistory:
        final name = action.payload['patientName'] ?? 'Chika';
        _processTranscript("Show $name's vital signs.");
        break;
      case GenUiActionType.generateSummary:
        final name = action.payload['patientName'] ?? 'Chika';
        _processTranscript("Summarise $name's patient history.");
        break;
      case GenUiActionType.recordVitals:
        final name = action.payload['patientName'] ?? 'Chika';
        _processTranscript("Record a new blood pressure reading for $name.");
        break;
      case GenUiActionType.viewPatient:
        final name = action.payload['patientName'] ?? 'Chika';
        _processTranscript("Open $name's latest vitals.");
        break;
      case GenUiActionType.confirmSave:
        _workflowBloc.add(const ConversationWorkflowConfirmed());
        break;
      case GenUiActionType.cancelWorkflow:
        _workflowBloc.add(const ConversationWorkflowCancelled());
        break;
      case GenUiActionType.custom:
        if (action.id == 'enable_ai_sharing' ||
            action.id == 'enable_ai_consent' ||
            action.id == 'grant_consent') {
          try {
            if (locator.isRegistered<SettingsBloc>()) {
              locator<SettingsBloc>().add(const AiConsentToggled(true));
            } else {
              context.read<SettingsBloc>().add(const AiConsentToggled(true));
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ AI Data Sharing enabled. Live Gemini AI assistant is active.'),
                backgroundColor: AppColors.primary,
                duration: Duration(seconds: 3),
              ),
            );
            _updateOrAddAiMessage(
              '✓ AI Data Sharing has been successfully enabled! Live Gemini AI clinical analysis is now active.',
              null,
            );
          } catch (_) {}
          return;
        }
        _processTranscript(action.label);
        break;
      default:
        _processTranscript(action.label);
        break;
    }
  }

  bool _hasAiConsent() {
    try {
      if (locator.isRegistered<SettingsBloc>()) {
        return locator<SettingsBloc>().state.aiConsent;
      }
      return context.read<SettingsBloc>().state.aiConsent;
    } catch (_) {
      return true;
    }
  }

  List<PatientModel> _getExistingPatients() {
    try {
      final patientBloc = context.read<PatientBloc>();
      if (patientBloc.state is PatientLoadSuccess) {
        return (patientBloc.state as PatientLoadSuccess).patients;
      }
    } catch (_) {}
    return <PatientModel>[];
  }

  // ignore: unused_element
  void _startPatientCreationWorkflow(String prompt) {
    final patientBloc = context.read<PatientBloc>();
    final existingPatients = patientBloc.state is PatientLoadSuccess
        ? (patientBloc.state as PatientLoadSuccess).patients
        : <PatientModel>[];

    final draft = _patientCreationService.startPatientCreation(
      prompt,
      existingPatients,
    );
    _activePatientDraft = draft;

    setState(() {
      _messages.add({'sender': 'user', 'text': prompt});
      _messages.add({
        'sender': 'ai',
        'text': draft.questionForCurrentStep,
        'widget': _buildPatientCreationCard(draft),
      });
      _uiState = AssistantUiState.responding;
    });

    _speakText(draft.questionForCurrentStep);
    _scrollToBottom();
  }

  void _handlePatientCreationStep(String utterance) async {
    if (_activePatientDraft == null) return;
    final patientBloc = context.read<PatientBloc>();
    final existingPatients = patientBloc.state is PatientLoadSuccess
        ? (patientBloc.state as PatientLoadSuccess).patients
        : <PatientModel>[];

    final updatedDraft = _patientCreationService.processUtterance(
      utterance,
      _activePatientDraft!,
      existingPatients,
    );
    _activePatientDraft = updatedDraft;

    if (updatedDraft.isConfirmed &&
        !updatedDraft.isSaving &&
        updatedDraft.currentStep != PatientCreationStep.completed) {
      await _confirmAndSavePatient();
      return;
    }

    setState(() {
      _messages.add({'sender': 'user', 'text': utterance});
      _messages.add({
        'sender': 'ai',
        'text': updatedDraft.questionForCurrentStep,
        'widget': _buildPatientCreationCard(updatedDraft),
      });
      _uiState = AssistantUiState.responding;
    });

    _speakText(updatedDraft.questionForCurrentStep);
    _scrollToBottom();
  }

  Future<void> _confirmAndSavePatient() async {
    if (_activePatientDraft == null || _activePatientDraft!.isSaving) return;

    setState(() {
      _activePatientDraft = _activePatientDraft!.copyWith(isSaving: true);
      if (_messages.isNotEmpty && _messages.last['sender'] == 'ai') {
        _messages.last['widget'] = _buildPatientCreationCard(
          _activePatientDraft!,
        );
      }
    });

    final repo = locator<PatientRepository>();
    final activityBloc = context.read<ActivityBloc>();

    final savedDraft = await _patientCreationService.confirmAndSavePatient(
      _activePatientDraft!,
      repo,
      activityBloc: activityBloc,
    );

    if (!mounted) return;

    setState(() {
      _activePatientDraft = savedDraft;
      if (_messages.isNotEmpty && _messages.last['sender'] == 'ai') {
        _messages.last['widget'] = _buildPatientCreationCard(savedDraft);
        _messages.last['text'] = savedDraft.questionForCurrentStep;
      }
      _uiState = AssistantUiState.responding;
    });

    // Refresh patient list in PatientBloc
    context.read<PatientBloc>().add(PatientListRequested());

    if (savedDraft.createdPatient != null) {
      _speakText(
        "Patient ${savedDraft.createdPatient!.name} has been registered successfully.",
      );
    }
    _scrollToBottom();
  }

  Widget _buildPatientCreationCard(PatientDraft draft) {
    return ConversationalPatientCreationCard(
      draft: draft,
      onSubmitUtterance: (text) => _handlePatientCreationStep(text),
      onSkip: () => _handlePatientCreationStep('skip'),
      onCancel: () {
        setState(() {
          _activePatientDraft = draft.copyWith(
            currentStep: PatientCreationStep.cancelled,
          );
          if (_messages.isNotEmpty && _messages.last['sender'] == 'ai') {
            _messages.last['widget'] = _buildPatientCreationCard(
              _activePatientDraft!,
            );
            _messages.last['text'] = 'Patient registration cancelled.';
          }
        });
        _speakText('Registration cancelled.');
      },
      onEdit: () {
        setState(() {
          _activePatientDraft = draft.copyWith(
            currentStep: PatientCreationStep.name,
          );
          if (_messages.isNotEmpty && _messages.last['sender'] == 'ai') {
            _messages.last['widget'] = _buildPatientCreationCard(
              _activePatientDraft!,
            );
            _messages.last['text'] =
                _activePatientDraft!.questionForCurrentStep;
          }
        });
      },
      onConfirm: _confirmAndSavePatient,
      onProceedAnyway: () {
        setState(() {
          _activePatientDraft = draft.copyWith(
            currentStep: PatientCreationStep.review,
          );
          if (_messages.isNotEmpty && _messages.last['sender'] == 'ai') {
            _messages.last['widget'] = _buildPatientCreationCard(
              _activePatientDraft!,
            );
            _messages.last['text'] =
                _activePatientDraft!.questionForCurrentStep;
          }
        });
      },
      onOpenPatient: (patient) {
        context.read<PatientBloc>().add(PatientSelected(patient));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDetailsPage(patient: patient),
          ),
        );
      },
      onRecordVitals: (patient) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmVitalPage(
              initialSystolic: 120,
              initialDiastolic: 80,
              initialPatientId: patient.id,
              voiceTranscript: 'Record vitals for new patient ${patient.name}',
            ),
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ignore: unused_element
  void _addAssistantResponse(String userPrompt, ClinicalIntent intent) {
    String responseText = '';
    Widget? genUiWidget;

    switch (intent) {
      case ClinicalIntent.compareVitalReadings:
        responseText =
            "Here's Chika's blood pressure trend for the last 7 days, compared to the previous 7 days.";
        genUiWidget = const ClinicalComparisonChartCard(
          patientName: 'Chika Okafor',
          latestReading: '118/76 mmHg',
          latestTimestamp: 'Apr 26, 2025 • 09:41 AM',
        );
        break;

      case ClinicalIntent.listPatients:
        responseText =
            "Here are your patients matching your follow-up criteria:";
        genUiWidget = _buildGenUiPatientList();
        break;

      case ClinicalIntent.getPatientVitals:
        responseText = "Opening Chika Okafor's latest recorded vital signs:";
        genUiWidget = _buildGenUiVitalSummary();
        break;

      case ClinicalIntent.draftClinicalNote:
        responseText =
            "I've drafted a clinical visit note for your encounter with Chika Okafor. You can review and edit below:";
        genUiWidget = _buildGenUiNoteDraft();
        break;

      case ClinicalIntent.getRecentActivity:
        responseText = "Here is your recent clinical activity summary:";
        genUiWidget = _buildGenUiRecentActivity();
        break;

      default:
        responseText =
            "I can assist you with reviewing patient charts, comparing vital signs over time, drafting clinical encounter notes, and recording new measurements.";
        break;
    }

    setState(() {
      _messages.add({'sender': 'user', 'text': userPrompt});
      _messages.add({
        'sender': 'ai',
        'text': responseText,
        'widget': genUiWidget,
      });
      _uiState = AssistantUiState.responding;
    });

    _speakText(responseText);

    _scrollToBottom();
  }

  void _speakText(String text) async {
    try {
      final audioService = locator<AiAudioService>();
      setState(() => _isTtsPlaying = true);
      await audioService.playMessage(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        rawText: text,
      );
      setState(() => _isTtsPlaying = false);
    } catch (_) {
      setState(() => _isTtsPlaying = false);
    }
  }

  void _stopSpeaking() async {
    try {
      final audioService = locator<AiAudioService>();
      await audioService.stop();
      setState(() => _isTtsPlaying = false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Listening State (Screen 3)
    if (_uiState == AssistantUiState.listening) {
      return VoiceListeningView(
        transcript: _currentTranscript,
        isListening: true,
        onStop: _stopVoiceListening,
        onCancel: _cancelVoiceListening,
        onTranscriptChanged: (newText) {
          setState(() => _currentTranscript = newText);
        },
      );
    }

    // 2. Processing State
    if (_uiState == AssistantUiState.processing) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: const VoiceVitalsTopBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Interpreting clinical request...',
                style: AppTypography.titleMedium(
                  color: isDark ? Colors.white : AppColors.secondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Accessing authorized patient records',
                style: AppTypography.bodySmall(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Conversational GenUI Mode (Responding / Chat)
    if (_uiState == AssistantUiState.responding) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : AppColors.secondary,
            ),
            onPressed: () => setState(() => _uiState = AssistantUiState.idle),
          ),
          title: Text(
            'VoiceVitals',
            style: AppTypography.titleLarge(
              color: isDark ? Colors.white : AppColors.secondary,
            ),
          ),
          actions: [
            if (_isTtsPlaying)
              IconButton(
                icon: const Icon(
                  Icons.volume_off_rounded,
                  color: AppColors.primary,
                ),
                tooltip: 'Stop Audio',
                onPressed: _stopSpeaking,
              ),
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: 'New Request',
              onPressed: () => setState(() => _uiState = AssistantUiState.idle),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _messages.length,
                itemBuilder: (ctx, idx) {
                  final msg = _messages[idx];
                  final isUser = msg['sender'] == 'user';
                  final widgetComponent = msg['widget'] as Widget?;

                  if (isUser) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12, left: 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.subtleTealSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.subtleTealBorder),
                        ),
                        child: Text(
                          msg['text'] as String,
                          style: AppTypography.bodyMedium(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              msg['text'] as String,
                              style: AppTypography.bodyMedium(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widgetComponent != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 38),
                          child: widgetComponent,
                        ),
                      ],
                      if (msg['suggestions'] is List<GenUiAction> &&
                          (msg['suggestions'] as List<GenUiAction>)
                              .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 38),
                          child: SuggestionCard(
                            component: const GenUiComponent(
                              id: 'msg_suggestions',
                              type: GenUiComponentTypes.suggestionCard,
                            ),
                            overrideActions:
                                msg['suggestions'] as List<GenUiAction>,
                            onActionSelected: _handleGenUiAction,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),

            // Bottom Input Bar in Responding Mode (Screen 7 bottom)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Mic button on left
                    GestureDetector(
                      onTap: _startVoiceListening,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // TextField in center
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (val) {
                          final text = val.trim();
                          if (text.isNotEmpty) {
                            _textController.clear();
                            _processTranscript(text);
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'Ask another question...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        final text = _textController.text.trim();
                        if (text.isNotEmpty) {
                          _textController.clear();
                          _processTranscript(text);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 4. Hero Home Assistant Idle Screen (Screen 2)
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: const VoiceVitalsTopBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting & Doctor Title
                    Row(
                      children: [
                        Text(
                          '${_getGreeting()},',
                          style: AppTypography.headlineLarge(
                            color: isDark ? Colors.white : AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Dr. Adeyemi',
                          style: AppTypography.headlineLarge(
                            color: isDark ? Colors.white : AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('☀️', style: TextStyle(fontSize: 22)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What would you like to do today?',
                      style: AppTypography.bodyMedium(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!_hasAiConsent()) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F2942) : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBAE6FD),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 22,
                              color: Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'AI Data Sharing is off. Enable it to unlock live Gemini clinical intelligence.',
                                style: AppTypography.bodySmall(
                                  color: isDark ? Colors.white70 : const Color(0xFF0369A1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                if (locator.isRegistered<SettingsBloc>()) {
                                  locator<SettingsBloc>().add(const AiConsentToggled(true));
                                } else {
                                  context.read<SettingsBloc>().add(const AiConsentToggled(true));
                                }
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ AI Data Sharing enabled. Live Gemini AI assistant is active.'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
                              child: const Text(
                                'Enable',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // "Try saying" Suggestions Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Try saying',
                            style: AppTypography.labelMedium(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._suggestedPrompts.map((prompt) {
                            return InkWell(
                              onTap: () => _processTranscript(prompt),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.mic_none_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '"$prompt"',
                                        style: AppTypography.bodySmall(
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Central Prominent Microphone Interaction Centerpiece
                    Center(
                      child: Column(
                        children: [
                          // Mic with Left and Right Soundwave Visualizer Bars
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Left Soundwave Lines
                              _buildStaticWaveLines(reversed: true),
                              const SizedBox(width: 16),

                              // Central Mic Circular Button (Teal Treatment)
                              GestureDetector(
                                onTap: _startVoiceListening,
                                child: Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.mic_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),
                              // Right Soundwave Lines
                              _buildStaticWaveLines(reversed: false),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'Tap to speak',
                            style: AppTypography.titleMedium(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'or type a request',
                            style: AppTypography.bodySmall(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Subtle Text Input at the Bottom (Screen 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkContainer
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.keyboard_outlined,
                        color: AppColors.lightTextSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          onSubmitted: (val) {
                            final text = val.trim();
                            if (text.isNotEmpty) {
                              _textController.clear();
                              _processTranscript(text);
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final text = _textController.text.trim();
                          if (text.isNotEmpty) {
                            _textController.clear();
                            _processTranscript(text);
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticWaveLines({required bool reversed}) {
    final heights = [10.0, 18.0, 26.0, 14.0, 8.0];
    final list = reversed ? heights.reversed.toList() : heights;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: list.map((h) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }

  // GenUI Component 1: Patient List Results
  Widget _buildGenUiPatientList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<PatientBloc, PatientState>(
      builder: (context, state) {
        final patients = state is PatientLoadSuccess
            ? state.patients
            : <PatientModel>[];
        if (patients.isEmpty) return const SizedBox();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patients Requiring Review',
                style: AppTypography.titleSmall(
                  color: isDark ? Colors.white : AppColors.secondary,
                ),
              ),
              const SizedBox(height: 10),
              ...patients.take(3).map((p) {
                return InkWell(
                  onTap: () {
                    context.read<PatientBloc>().add(PatientSelected(p));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientDetailsPage(patient: p),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.subtleTealSurface,
                          child: Text(
                            p.name.isNotEmpty ? p.name[0] : 'P',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: AppTypography.titleSmall(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.secondary,
                                ),
                              ),
                              Text(
                                p.medicalConditions.isNotEmpty
                                    ? p.medicalConditions.first
                                    : 'Routine Care',
                                style: AppTypography.bodySmall(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // GenUI Component 2: Vital Summary Card
  Widget _buildGenUiVitalSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chika Okafor (CV-10024)',
                style: AppTypography.titleSmall(
                  color: isDark ? Colors.white : AppColors.secondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Normal',
                  style: TextStyle(
                    color: AppColors.onSuccessContainer,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricPill('BP', '118/76', 'mmHg'),
              _buildMetricPill('HR', '72', 'bpm'),
              _buildMetricPill('Temp', '36.6', '°C'),
              _buildMetricPill('SpO₂', '98', '%'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              onPressed: () {
                final patientState = context.read<PatientBloc>().state;
                if (patientState is PatientLoadSuccess &&
                    patientState.patients.isNotEmpty) {
                  final chika = patientState.patients.first;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientDetailsPage(patient: chika),
                    ),
                  );
                }
              },
              child: const Text('Open Patient Record'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  // GenUI Component 3: Clinical Note Draft Form
  Widget _buildGenUiNoteDraft() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteController = TextEditingController(
      text:
          'Encounter Note:\nSubjective: Patient reports feeling well, adhering to low-sodium diet.\nObjective: Blood pressure sitting 118/76 mmHg, HR 72 bpm, SpO2 98%.\nAssessment: Well-controlled Stage 1 Essential Hypertension.\nPlan: Continue Amlodipine 5mg daily. Follow-up visit in 3 months.',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Clinical Visit Note Draft',
                style: AppTypography.titleSmall(
                  color: isDark ? Colors.white : AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteController,
            maxLines: 5,
            style: const TextStyle(fontSize: 13, height: 1.4),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? AppColors.darkContainer
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16, color: Colors.white),
              label: const Text(
                'Save Clinical Note',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                final repo = locator<PatientRepository>();
                await repo.saveClinicalNote(
                  ClinicalNote(
                    patientId: 1,
                    visitType: 'General Consultation',
                    content: noteController.text,
                    authorName: 'Dr. Adeyemi',
                    date: DateTime.now(),
                  ),
                );

                if (mounted) {
                  context.read<ActivityBloc>().add(
                    ActivityLogged(
                      ActivityItem(
                        title: 'Note added',
                        subtitle: 'General Consultation • Chika Okafor',
                        timestamp: DateTime.now(),
                        category: ActivityCategory.notes,
                        patientId: 1,
                        patientName: 'Chika Okafor',
                      ),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Clinical note successfully recorded for Chika Okafor.',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // GenUI Component 4: Recent Activity List
  Widget _buildGenUiRecentActivity() {
    return BlocBuilder<ActivityBloc, ActivityState>(
      builder: (context, state) {
        final items = state is ActivityLoadSuccess
            ? state.activities
            : <ActivityItem>[];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Actions',
                style: AppTypography.titleSmall(color: AppColors.secondary),
              ),
              const SizedBox(height: 8),
              ...items.take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.title}: ${item.subtitle}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
