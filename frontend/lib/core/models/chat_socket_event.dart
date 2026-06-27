import 'chat_models.dart';

enum ChatSocketEventType {
  connected,
  messageAck,
  messageReceived,
  presenceChanged,
  error,
  pong,
  unknown,
}

class ChatSocketEvent {
  ChatSocketEvent({
    required this.type,
    this.conversationId,
    this.message,
    this.userId,
    this.online,
    this.code,
    this.notice,
  });

  final ChatSocketEventType type;
  final int? conversationId;
  final MessageItem? message;
  final int? userId;
  final bool? online;
  final int? code;
  final String? notice;

  factory ChatSocketEvent.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String? ?? '').toUpperCase();
    final data = json['data'];
    final dataMap = data is Map<String, dynamic>
        ? data
        : data is Map
        ? data.map((key, value) => MapEntry(key.toString(), value))
        : null;

    return ChatSocketEvent(
      type: switch (rawType) {
        'CONNECTED' => ChatSocketEventType.connected,
        'MESSAGE_ACK' => ChatSocketEventType.messageAck,
        'MESSAGE_RECEIVED' => ChatSocketEventType.messageReceived,
        'PRESENCE_CHANGED' => ChatSocketEventType.presenceChanged,
        'ERROR' => ChatSocketEventType.error,
        'PONG' => ChatSocketEventType.pong,
        _ => ChatSocketEventType.unknown,
      },
      conversationId: (json['conversationId'] as num?)?.toInt(),
      message: rawType == 'MESSAGE_ACK' || rawType == 'MESSAGE_RECEIVED'
          ? dataMap == null
                ? null
                : MessageItem.fromJson(dataMap)
          : null,
      userId: (dataMap?['userId'] as num?)?.toInt(),
      online: dataMap?['online'] as bool?,
      code: (json['code'] as num?)?.toInt(),
      notice: json['message'] as String?,
    );
  }
}
