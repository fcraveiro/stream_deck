import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';

class OBSWebSocketManager {
  static final OBSWebSocketManager _instance = OBSWebSocketManager._internal();

  factory OBSWebSocketManager() {
    return _instance;
  }

  OBSWebSocketManager._internal();

  IOWebSocketChannel? _channel;
  final _controller = StreamController<dynamic>.broadcast();

  bool get isConnected => _channel != null;

  void connect(
    String url, {
    String? password,
    Function? onConnect,
    Function? onDisconnect,
    Function(dynamic)? onError,
  }) {
    _channel = IOWebSocketChannel.connect(url);
    _channel!.stream.listen(
      (message) {
        _controller.add(message);
      },
      onDone: () {
        _channel = null;
        _controller.add('desconectado');
        onDisconnect?.call();
      },
      onError: onError,
    );

    if (password != null) {
      send('{"op": 1, "d": {"rpcVersion": 1, "authentication": "$password"}}');
    }

    onConnect?.call();
  }

  void send(String message) {
    _channel?.sink.add(message);
  }

  void addListener(void Function(dynamic) listener) {
    _controller.stream.listen(listener);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void sendCommand(String requestType,
      [Map<String, dynamic>? additionalParams]) {
    if (isConnected) {
      final request = {
        'op': 6,
        'd': {
          'requestType': requestType,
          'requestId': DateTime.now().millisecondsSinceEpoch.toString(),
          ...?additionalParams,
        }
      };
      send(json.encode(request));
    }
  }

  void setStudioMode(bool enable) {
    sendCommand('SetStudioModeEnabled', {
      'requestData': {
        'studioModeEnabled': enable,
      },
    });
  }
}
