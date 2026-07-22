import 'package:equatable/equatable.dart';
import '../../data/models/chat_conversation.dart';
import '../../data/models/health_context.dart';

abstract class AiAssistantState extends Equatable {
  const AiAssistantState();

  @override
  List<Object?> get props => [];
}

class AiAssistantInitial extends AiAssistantState {}

class AiAssistantLoading extends AiAssistantState {}

class AiAssistantLoaded extends AiAssistantState {
  final ChatConversation activeConversation;
  final List<ChatConversation> conversations;
  final List<String> smartSuggestions;
  final HealthContext? healthContext;
  final bool isGenerating;
  final String syncStatus; // 'Synced', 'Pending', 'Offline'
  final String? errorMessage;

  const AiAssistantLoaded({
    required this.activeConversation,
    required this.conversations,
    required this.smartSuggestions,
    this.healthContext,
    this.isGenerating = false,
    this.syncStatus = 'Synced',
    this.errorMessage,
  });

  AiAssistantLoaded copyWith({
    ChatConversation? activeConversation,
    List<ChatConversation>? conversations,
    List<String>? smartSuggestions,
    HealthContext? healthContext,
    bool? isGenerating,
    String? syncStatus,
    String? errorMessage,
  }) {
    return AiAssistantLoaded(
      activeConversation: activeConversation ?? this.activeConversation,
      conversations: conversations ?? this.conversations,
      smartSuggestions: smartSuggestions ?? this.smartSuggestions,
      healthContext: healthContext ?? this.healthContext,
      isGenerating: isGenerating ?? this.isGenerating,
      syncStatus: syncStatus ?? this.syncStatus,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        activeConversation,
        conversations,
        smartSuggestions,
        healthContext,
        isGenerating,
        syncStatus,
        errorMessage,
      ];
}

class AiAssistantError extends AiAssistantState {
  final String message;

  const AiAssistantError(this.message);

  @override
  List<Object?> get props => [message];
}
