import '../models/ai_conversation_memory.dart';

abstract class AIMemoryRepository {
  Future<void> saveMemory(AIConversationMemory memory);
  Future<List<AIConversationMemory>> getMemoriesForConversation(
    String conversationId,
  );
  Future<List<AIConversationMemory>> getAllMemories();
  Future<void> deleteMemory(int id);
  Future<void> clearAllMemories();
  Future<String> generateConversationSummary(List<String> messages);
}
