import 'user_model.dart';

class Conversation {
  final String id;
  final List<User> participants;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Backend may send lastMessage as a String (the text) or a Map (full message).
    ChatMessage? parsedLast;
    final rawLast = json['lastMessage'];
    if (rawLast is Map) {
      parsedLast = ChatMessage.fromJson(Map<String, dynamic>.from(rawLast));
    } else if (rawLast is String && rawLast.isNotEmpty) {
      parsedLast = ChatMessage(
        id: '',
        conversationId: json['_id']?.toString() ?? '',
        senderId: '',
        text: rawLast,
        createdAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? '') ?? DateTime.now(),
      );
    }

    // Backend often returns `otherUser` instead of full `participants` list.
    final participantsRaw = json['participants'] as List?;
    final otherUser = json['otherUser'];
    final List<User> participants = participantsRaw != null
        ? participantsRaw.map((p) => User.fromJson(p as Map<String, dynamic>)).toList()
        : (otherUser is Map
            ? [User.fromJson(Map<String, dynamic>.from(otherUser))]
            : <User>[]);

    return Conversation(
      id: json['_id'] ?? json['id'] ?? '',
      participants: participants,
      lastMessage: parsedLast,
      unreadCount: json['unreadCount'] ?? 0,
      updatedAt: DateTime.tryParse(
            json['updatedAt']?.toString() ?? json['lastMessageAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? json['sender'] ?? '',
      text: json['message'] ?? json['text'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }
}
