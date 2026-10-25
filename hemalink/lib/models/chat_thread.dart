class ChatMessage {
  final String senderId;
  final String text;
  final DateTime sentAt;

  const ChatMessage({
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        senderId: j['senderId'] as String,
        text: j['text'] as String,
        sentAt: DateTime.parse(j['sentAt'] as String),
      );
}

class ChatThread {
  final String id;
  final String requestId;
  final String requesterId;
  String requesterName;
  final String donorId;
  String donorName;
  final String bloodType;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  ChatThread({
    required this.id,
    required this.requestId,
    required this.requesterId,
    required this.requesterName,
    required this.donorId,
    required this.donorName,
    required this.bloodType,
    required this.createdAt,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  String otherName(String myId) => myId == requesterId ? donorName : requesterName;

  DateTime get updatedAt => messages.isEmpty ? createdAt : messages.last.sentAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'requesterId': requesterId,
        'requesterName': requesterName,
        'donorId': donorId,
        'donorName': donorName,
        'bloodType': bloodType,
        'createdAt': createdAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatThread.fromJson(Map<String, dynamic> j) => ChatThread(
        id: j['id'] as String,
        requestId: j['requestId'] as String,
        requesterId: j['requesterId'] as String,
        requesterName: j['requesterName'] as String,
        donorId: j['donorId'] as String,
        donorName: j['donorName'] as String,
        bloodType: j['bloodType'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        messages: (j['messages'] as List)
            .map((m) => ChatMessage.fromJson((m as Map).cast<String, dynamic>()))
            .toList(),
      );
}
