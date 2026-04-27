import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat/chat_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository(this._firestore);

  CollectionReference get _chats => _firestore.collection('chats');

  Future<ChatModel?> getChatById(String chatId) async {
    final doc = await _chats.doc(chatId).get();
    if (doc.exists) {
      return ChatModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<ChatModel> createChat(ChatModel chat) async {
    await _chats.doc(chat.chatId).set(chat.toJson());
    return chat;
  }

  Future<void> updateChat(ChatModel chat) async {
    await _chats.doc(chat.chatId).update(chat.toJson());
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    final batch = _firestore.batch();

    // Add message to subcollection
    final messageRef =
        _chats.doc(chatId).collection('messages').doc(message.messageId);
    batch.set(messageRef, message.toJson());

    // Update chat last message
    batch.update(_chats.doc(chatId), {
      'lastMessage': {
        'text': message.text,
        'senderId': message.senderId,
        'timestamp': message.timestamp.toIso8601String(),
      },
      'updatedAt': message.timestamp.toIso8601String(),
    });

    await batch.commit();
  }

  Stream<List<ChatModel>> watchChats(String userId) {
    return _chats
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(
                (doc) => ChatModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data()))
            .toList());
  }

  Future<void> markMessageAsRead(String chatId, String messageId) async {
    await _chats
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }
}
