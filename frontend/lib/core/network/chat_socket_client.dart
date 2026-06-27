import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../models/chat_socket_event.dart';

class ChatSocketClient {
  final StreamController<ChatSocketEvent> _eventsController =
      StreamController<ChatSocketEvent>.broadcast();
  static const _heartbeatInterval = Duration(seconds: 25);
  static const _reconnectDelay = Duration(seconds: 3);

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  String? _desiredToken;
  String? _connectedToken;
  bool _isConnected = false;
  bool _manualDisconnect = false;

  Stream<ChatSocketEvent> get events => _eventsController.stream;
  bool get isConnected => _isConnected;

  void ensureConnected(String token) {
    _manualDisconnect = false;
    _desiredToken = token;

    if (_connectedToken == token && _channel != null && _isConnected) {
      return;
    }

    _reconnectTimer?.cancel();
    _openConnection(token);
  }

  void _openConnection(String token) {
    _subscription?.cancel();
    _subscription = null;
    _stopHeartbeat();
    _channel?.sink.close();

    _connectedToken = token;
    _channel = WebSocketChannel.connect(AppConfig.buildWebSocketUri(token));
    _isConnected = true;
    _startHeartbeat();

    _subscription = _channel!.stream.listen(
      (dynamic data) {
        if (data is! String) {
          return;
        }

        final decoded = jsonDecode(data);
        if (decoded is! Map<String, dynamic>) {
          return;
        }

        _eventsController.add(ChatSocketEvent.fromJson(decoded));
      },
      onDone: () => _handleConnectionClosed(shouldReconnect: true),
      onError: (_) => _handleConnectionClosed(shouldReconnect: true),
    );
  }

  void _handleConnectionClosed({required bool shouldReconnect}) {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _connectedToken = null;
    _isConnected = false;
    _stopHeartbeat();

    if (shouldReconnect && !_manualDisconnect && _desiredToken != null) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) {
      return;
    }

    _reconnectTimer = Timer(_reconnectDelay, () {
      final token = _desiredToken;
      if (token == null || _manualDisconnect) {
        return;
      }
      _openConnection(token);
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendRaw(const {'type': 'PING'});
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void disconnect() {
    _manualDisconnect = true;
    _desiredToken = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopHeartbeat();
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _connectedToken = null;
    _isConnected = false;
  }

  bool sendChatMessage({
    required int conversationId,
    required String content,
    String? clientMessageId,
  }) {
    return _sendRaw({
      'type': 'CHAT_SEND',
      'conversationId': conversationId,
      'clientMessageId': clientMessageId,
      'content': content,
    });
  }

  bool _sendRaw(Map<String, dynamic> payload) {
    if (!_isConnected || _channel == null) {
      return false;
    }

    _channel!.sink.add(jsonEncode(payload));
    return true;
  }

  void dispose() {
    disconnect();
    _eventsController.close();
  }
}
