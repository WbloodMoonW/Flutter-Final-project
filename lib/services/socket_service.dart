import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'storage_service.dart';

class SocketService {
  static IO.Socket? _socket;
  static const String _serverUrl = 'https://angezny.onrender.com';

  static Future<IO.Socket> connect() async {
    if (_socket != null && _socket!.connected) return _socket!;
    final token = await StorageService.getToken();
    _socket = IO.io(
      _serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
    return _socket!;
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  static IO.Socket? get socket => _socket;
}
