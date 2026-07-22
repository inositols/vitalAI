import 'package:vitalai/core/database/db_service.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';

/// Local-first repository for AI chat conversations persistence.
class AiAssistantRepositoryImpl implements AiAssistantRepository {
  final DbService _dbService;

  AiAssistantRepositoryImpl(this._dbService);

  @override
  Future<List<ChatConversation>> getConversations(int patientId) async {
    final list = await _dbService.getConversations(patientId);
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<ChatConversation?> getConversationById(int patientId, String conversationId) async {
    final conversations = await getConversations(patientId);
    try {
      return conversations.firstWhere((c) => c.id == conversationId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveConversation(ChatConversation conversation) async {
    final conversations = await _dbService.getConversations(conversation.patientId);
    final index = conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      conversations[index] = conversation;
    } else {
      conversations.add(conversation);
    }
    await _dbService.saveConversations(conversation.patientId, conversations);
  }

  @override
  Future<void> deleteConversation(int patientId, String conversationId) async {
    final conversations = await _dbService.getConversations(patientId);
    conversations.removeWhere((c) => c.id == conversationId);
    await _dbService.saveConversations(patientId, conversations);
  }

  @override
  Future<void> clearAllConversations(int patientId) async {
    await _dbService.clearConversations(patientId);
  }

  @override
  Future<List<ChatMessage>> getPendingMessages(int patientId) async {
    final conversations = await getConversations(patientId);
    final pending = <ChatMessage>[];
    for (var c in conversations) {
      for (var m in c.messages) {
        if (m.status == 'pending' || m.status == 'failed') {
          pending.add(m);
        }
      }
    }
    return pending;
  }
}
