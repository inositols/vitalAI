import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:vitalai/core/services/ai_service.dart';
import '../../data/models/chat_conversation.dart';
import '../../data/models/chat_message.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../../domain/services/health_context_service.dart';
import 'ai_assistant_event.dart';
import 'ai_assistant_state.dart';

class AiAssistantBloc extends Bloc<AiAssistantEvent, AiAssistantState> {
  final AiAssistantRepository repository;
  final HealthContextService contextService;
  final AiService aiService;
  final Uuid _uuid = const Uuid();

  int? _currentPatientId;

  AiAssistantBloc({
    required this.repository,
    required this.contextService,
    required this.aiService,
  }) : super(AiAssistantInitial()) {
    on<AiAssistantInit>(_onInit);
    on<AiAssistantSelectConversation>(_onSelectConversation);
    on<AiAssistantNewChat>(_onNewChat);
    on<AiAssistantSendMessage>(_onSendMessage);
    on<AiAssistantRetryMessage>(_onRetryMessage);
    on<AiAssistantDeleteConversation>(_onDeleteConversation);
    on<AiAssistantClearAll>(_onClearAll);
    on<AiAssistantTriggerQuickAction>(_onTriggerQuickAction);
    on<AiAssistantSyncPending>(_onSyncPending);
  }

  Future<void> _onInit(AiAssistantInit event, Emitter<AiAssistantState> emit) async {
    _currentPatientId = event.patientId;
    emit(AiAssistantLoading());
    try {
      final conversations = await repository.getConversations(event.patientId);
      final healthContext = await contextService.buildHealthContext(event.patientId);
      final suggestions = contextService.generateSmartSuggestions(healthContext);

      ChatConversation activeConversation;
      if (conversations.isNotEmpty) {
        activeConversation = conversations.first;
      } else {
        activeConversation = _createWelcomeConversation(event.patientId, healthContext.patientName);
        await repository.saveConversation(activeConversation);
        conversations.add(activeConversation);
      }

      emit(AiAssistantLoaded(
        activeConversation: activeConversation,
        conversations: conversations,
        smartSuggestions: suggestions,
        healthContext: healthContext,
        isGenerating: false,
        syncStatus: aiService.isConfigured ? 'Synced' : 'Offline',
      ));
    } catch (e) {
      emit(AiAssistantError("Failed to initialize AI Assistant: $e"));
    }
  }

  Future<void> _onSelectConversation(AiAssistantSelectConversation event, Emitter<AiAssistantState> emit) async {
    if (state is! AiAssistantLoaded || _currentPatientId == null) return;
    final currentState = state as AiAssistantLoaded;
    final target = currentState.conversations.firstWhere((c) => c.id == event.conversationId, orElse: () => currentState.activeConversation);
    emit(currentState.copyWith(activeConversation: target));
  }

  Future<void> _onNewChat(AiAssistantNewChat event, Emitter<AiAssistantState> emit) async {
    if (state is! AiAssistantLoaded || _currentPatientId == null) return;
    final currentState = state as AiAssistantLoaded;
    final patientName = currentState.healthContext?.patientName ?? 'Patient';
    final newConv = _createWelcomeConversation(_currentPatientId!, patientName);
    final updatedList = List<ChatConversation>.from(currentState.conversations)..insert(0, newConv);
    await repository.saveConversation(newConv);
    emit(currentState.copyWith(activeConversation: newConv, conversations: updatedList));
  }

  Future<void> _onSendMessage(AiAssistantSendMessage event, Emitter<AiAssistantState> emit) async {
    if (state is! AiAssistantLoaded || _currentPatientId == null) return;
    final currentState = state as AiAssistantLoaded;
    if (event.content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      conversationId: currentState.activeConversation.id,
      sender: 'user',
      content: event.content.trim(),
      timestamp: DateTime.now(),
      status: 'synced',
    );

    var updatedMessages = List<ChatMessage>.from(currentState.activeConversation.messages)..add(userMessage);
    String title = currentState.activeConversation.title;
    if (currentState.activeConversation.messages.length <= 1) {
      title = event.content.length > 30 ? '${event.content.substring(0, 27)}...' : event.content;
    }

    var updatedConv = currentState.activeConversation.copyWith(title: title, messages: updatedMessages, updatedAt: DateTime.now());
    var updatedConversations = currentState.conversations.map((c) => c.id == updatedConv.id ? updatedConv : c).toList();
    await repository.saveConversation(updatedConv);

    final freshContext = await contextService.buildHealthContext(_currentPatientId!);
    final suggestions = contextService.generateSmartSuggestions(freshContext);

    emit(currentState.copyWith(
      activeConversation: updatedConv,
      conversations: updatedConversations,
      healthContext: freshContext,
      smartSuggestions: suggestions,
      isGenerating: true,
    ));

    final responseText = await aiService.askAssistant(
      event.content,
      healthContext: freshContext,
      history: updatedMessages,
    );
    final aiMessage = ChatMessage(
      id: _uuid.v4(),
      conversationId: updatedConv.id,
      sender: 'ai',
      content: responseText,
      timestamp: DateTime.now(),
      status: 'synced',
    );

    updatedMessages = List<ChatMessage>.from(updatedConv.messages)..add(aiMessage);
    updatedConv = updatedConv.copyWith(messages: updatedMessages, updatedAt: DateTime.now());
    updatedConversations = currentState.conversations.map((c) => c.id == updatedConv.id ? updatedConv : c).toList();
    await repository.saveConversation(updatedConv);

    emit(currentState.copyWith(
      activeConversation: updatedConv,
      conversations: updatedConversations,
      healthContext: freshContext,
      smartSuggestions: suggestions,
      isGenerating: false,
    ));
  }

  Future<void> _onRetryMessage(AiAssistantRetryMessage event, Emitter<AiAssistantState> emit) async {
    if (state is! AiAssistantLoaded || _currentPatientId == null) return;
    final currentState = state as AiAssistantLoaded;
    final targetIndex = currentState.activeConversation.messages.indexWhere((m) => m.id == event.messageId);
    if (targetIndex == -1) return;
    final targetMessage = currentState.activeConversation.messages[targetIndex];
    if (targetMessage.isUser) add(AiAssistantSendMessage(targetMessage.content));
  }

  Future<void> _onDeleteConversation(AiAssistantDeleteConversation event, Emitter<AiAssistantState> emit) async {
    if (state is! AiAssistantLoaded || _currentPatientId == null) return;
    final currentState = state as AiAssistantLoaded;
    await repository.deleteConversation(_currentPatientId!, event.conversationId);
    final updatedList = currentState.conversations.where((c) => c.id != event.conversationId).toList();

    ChatConversation newActive;
    if (updatedList.isNotEmpty) {
      newActive = updatedList.first;
    } else {
      newActive = _createWelcomeConversation(_currentPatientId!, currentState.healthContext?.patientName ?? 'Patient');
      await repository.saveConversation(newActive);
      updatedList.add(newActive);
    }
    emit(currentState.copyWith(activeConversation: newActive, conversations: updatedList));
  }

  Future<void> _onClearAll(AiAssistantClearAll event, Emitter<AiAssistantState> emit) async {
    if (state is! AiAssistantLoaded || _currentPatientId == null) return;
    final currentState = state as AiAssistantLoaded;
    await repository.clearAllConversations(_currentPatientId!);
    final freshConv = _createWelcomeConversation(_currentPatientId!, currentState.healthContext?.patientName ?? 'Patient');
    await repository.saveConversation(freshConv);
    emit(currentState.copyWith(activeConversation: freshConv, conversations: [freshConv]));
  }

  Future<void> _onTriggerQuickAction(AiAssistantTriggerQuickAction event, Emitter<AiAssistantState> emit) async {
    if (state is! AiAssistantLoaded || _currentPatientId == null) return;
    final currentState = state as AiAssistantLoaded;
    final context = currentState.healthContext;
    if (context == null) return;

    String promptTitle;
    Future<String> responseFuture;

    switch (event.actionType) {
      case 'health_summary':
        promptTitle = "Health Summary Action";
        responseFuture = aiService.generateHealthSummary(context);
        break;
      case 'vital_analysis':
        promptTitle = "Vital Analysis Action";
        responseFuture = aiService.generateVitalAnalysis(context);
        break;
      case 'doctor_prep':
        promptTitle = "Doctor Preparation Action";
        responseFuture = aiService.generateDoctorPrep(context);
        break;
      default:
        promptTitle = "Health Assistant Insight";
        responseFuture = aiService.askAssistant("Provide insights for my health vitals.", healthContext: context);
    }

    final userMsg = ChatMessage(id: _uuid.v4(), conversationId: currentState.activeConversation.id, sender: 'user', content: promptTitle, timestamp: DateTime.now(), status: 'synced', actionType: event.actionType);
    var updatedMessages = List<ChatMessage>.from(currentState.activeConversation.messages)..add(userMsg);
    var updatedConv = currentState.activeConversation.copyWith(messages: updatedMessages, updatedAt: DateTime.now());
    emit(currentState.copyWith(activeConversation: updatedConv, isGenerating: true));

    final aiResponseText = await responseFuture;
    final aiMsg = ChatMessage(id: _uuid.v4(), conversationId: updatedConv.id, sender: 'ai', content: aiResponseText, timestamp: DateTime.now(), status: 'synced', actionType: event.actionType);
    updatedMessages = List<ChatMessage>.from(updatedConv.messages)..add(aiMsg);
    updatedConv = updatedConv.copyWith(messages: updatedMessages, updatedAt: DateTime.now());
    final updatedConversations = currentState.conversations.map((c) => c.id == updatedConv.id ? updatedConv : c).toList();
    await repository.saveConversation(updatedConv);
    emit(currentState.copyWith(activeConversation: updatedConv, conversations: updatedConversations, isGenerating: false));
  }

  Future<void> _onSyncPending(AiAssistantSyncPending event, Emitter<AiAssistantState> emit) async {
    if (state is! AiAssistantLoaded || _currentPatientId == null) return;
    final currentState = state as AiAssistantLoaded;
    final pending = await repository.getPendingMessages(_currentPatientId!);
    if (pending.isEmpty) { emit(currentState.copyWith(syncStatus: 'Synced')); return; }
    emit(currentState.copyWith(syncStatus: 'Pending'));
    for (var msg in pending) { if (msg.isUser) add(AiAssistantSendMessage(msg.content)); }
  }

  ChatConversation _createWelcomeConversation(int patientId, String patientName) {
    final convId = _uuid.v4();
    final welcomeMsg = ChatMessage(
      id: _uuid.v4(),
      conversationId: convId,
      sender: 'ai',
      content: 'Hi $patientName! I am your personal VitalAI health companion. I analyze your blood pressure, glucose, pulse, SpO₂, temperature, and medications to answer questions, spot trends, and help you prepare for doctor visits. How can I support your health today?',
      timestamp: DateTime.now(),
      status: 'synced',
    );
    return ChatConversation(id: convId, patientId: patientId, title: 'New Conversation', createdAt: DateTime.now(), updatedAt: DateTime.now(), messages: [welcomeMsg]);
  }
}
