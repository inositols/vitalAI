import 'package:equatable/equatable.dart';

abstract class AiAssistantEvent extends Equatable {
  const AiAssistantEvent();

  @override
  List<Object?> get props => [];
}

class AiAssistantInit extends AiAssistantEvent {
  final int patientId;

  const AiAssistantInit(this.patientId);

  @override
  List<Object?> get props => [patientId];
}

class AiAssistantSelectConversation extends AiAssistantEvent {
  final String conversationId;

  const AiAssistantSelectConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class AiAssistantNewChat extends AiAssistantEvent {
  const AiAssistantNewChat();

  @override
  List<Object?> get props => [];
}

class AiAssistantSendMessage extends AiAssistantEvent {
  final String content;

  const AiAssistantSendMessage(this.content);

  @override
  List<Object?> get props => [content];
}

class AiAssistantRetryMessage extends AiAssistantEvent {
  final String messageId;

  const AiAssistantRetryMessage(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class AiAssistantDeleteConversation extends AiAssistantEvent {
  final String conversationId;

  const AiAssistantDeleteConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class AiAssistantClearAll extends AiAssistantEvent {
  const AiAssistantClearAll();

  @override
  List<Object?> get props => [];
}

class AiAssistantTriggerQuickAction extends AiAssistantEvent {
  final String actionType; // 'health_summary', 'vital_analysis', 'doctor_prep', 'report_explanation'
  final String? reportContent;

  const AiAssistantTriggerQuickAction(this.actionType, {this.reportContent});

  @override
  List<Object?> get props => [actionType, reportContent];
}

class AiAssistantSyncPending extends AiAssistantEvent {
  const AiAssistantSyncPending();

  @override
  List<Object?> get props => [];
}
