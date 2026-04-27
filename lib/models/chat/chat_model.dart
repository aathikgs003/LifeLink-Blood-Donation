import '../enums.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final Map<String, Map<String, dynamic>> participantDetails;
  final Map<String, dynamic>? lastMessage;
  final String? requestId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.participantDetails,
    this.lastMessage,
    this.requestId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'participants': participants,
      'participantDetails': participantDetails,
      'lastMessage': lastMessage,
      'requestId': requestId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['chatId'] ?? json['id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      participantDetails: Map<String, Map<String, dynamic>>.from(json['participantDetails'] ?? {}),
      lastMessage: json['lastMessage'],
      requestId: json['requestId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  ChatModel copyWith({
    String? chatId,
    List<String>? participants,
    Map<String, Map<String, dynamic>>? participantDetails,
    Map<String, dynamic>? lastMessage,
    String? requestId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      participantDetails: participantDetails ?? this.participantDetails,
      lastMessage: lastMessage ?? this.lastMessage,
      requestId: requestId ?? this.requestId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.name,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'] ?? json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? json['content'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      isRead: json['isRead'] ?? false,
      type: MessageType.fromString(json['type'] ?? 'text'),
    );
  }

  MessageModel copyWith({
    String? messageId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}
