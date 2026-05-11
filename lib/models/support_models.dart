class SupportTicket {
  final String id;
  final String subject;
  final String status; // 'open', 'closed', 'pending'
  final DateTime createdAt;
  final List<TicketReply> replies;

  SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.createdAt,
    this.replies = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['_id'] ?? json['id'] ?? '',
      subject: json['subject'] ?? '',
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      replies: (json['replies'] as List? ?? [])
          .map((r) => TicketReply.fromJson(r))
          .toList(),
    );
  }
}

class TicketReply {
  final String message;
  final String senderRole; // 'user', 'admin'
  final DateTime createdAt;

  TicketReply({
    required this.message,
    required this.senderRole,
    required this.createdAt,
  });

  factory TicketReply.fromJson(Map<String, dynamic> json) {
    return TicketReply(
      message: json['message'] ?? '',
      senderRole: json['senderRole'] ?? 'user',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
