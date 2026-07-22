import '../../data/models/chat_conversation.dart';
import '../../data/models/chat_message.dart';

/// Contract for AI assistant chat history and sync repository.
abstract class AiAssistantRepository {
  Future<List<ChatConversation>> getConversations(int patientId);
  Future<ChatConversation?> getConversationById(int patientId, String conversationId);
  Future<void> saveConversation(ChatConversation conversation);
  Future<void> deleteConversation(int patientId, String conversationId);
  Future<void> clearAllConversations(int patientId);
  Future<List<ChatMessage>> getPendingMessages(int patientId);
}
