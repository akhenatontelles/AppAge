class Message {
  final int id;
  final int userId;
  final String message;
  final bool isRead;
  final DateTime timestamp;
  final String? sender; // Permitir que o sender seja nulo

  Message({
    required this.id,
    required this.userId,
    required this.message,
    required this.isRead,
    required this.timestamp,
    this.sender, // Ajustar o construtor para aceitar nulo
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      userId: json['user_id'],
      message: json['message'],
      isRead: json['is_read'] == 1,
      timestamp: DateTime.parse(json['timestamp']),
      sender: json['sender'] ?? 'unknown', // Tratamento de nulo
    );
  }

  get isSentByUser => null;
}
