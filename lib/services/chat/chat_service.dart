import '../../models/chat/chat_model.dart';
import '../../repositories/chat_repository.dart';

class ChatService {
  final ChatRepository _chatRepository;

  ChatService(this._chatRepository);

  Future<ChatModel> getOrCreateChat(
      String currentUserId, String otherUserId, String? requestId) async {
    final participants = [currentUserId, otherUserId]..sort();
    final canonicalChatId = _buildCanonicalChatId(
      participants[0],
      participants[1],
      requestId,
    );

    final legacyForwardId = '${currentUserId}_$otherUserId';
    final legacyReverseId = '${otherUserId}_$currentUserId';

    final canonicalChat = await _chatRepository.getChatById(canonicalChatId);
    if (canonicalChat != null) {
      return canonicalChat;
    }

    final forwardChat = await _chatRepository.getChatById(legacyForwardId);
    final reverseChat = await _chatRepository.getChatById(legacyReverseId);
    final existingChat = _selectNewest(forwardChat, reverseChat);
    if (existingChat != null) {
      return existingChat;
    }

    final newChat = ChatModel(
      chatId: canonicalChatId,
      participants: participants,
      participantDetails: {}, // Should be populated
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      requestId: requestId,
    );
    return await _chatRepository.createChat(newChat);
  }

  String _buildCanonicalChatId(String userA, String userB, String? requestId) {
    if (requestId != null && requestId.isNotEmpty) {
      return '${requestId}_${userA}_$userB';
    }
    return '${userA}_$userB';
  }

  ChatModel? _selectNewest(ChatModel? first, ChatModel? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.updatedAt.isAfter(second.updatedAt) ? first : second;
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final message = MessageModel(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
    );
    await _chatRepository.sendMessage(chatId, message);
  }

  Stream<List<ChatModel>> getMyChats(String userId) {
    return _chatRepository.watchChats(userId);
  }

  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _chatRepository.watchMessages(chatId);
  }
}
