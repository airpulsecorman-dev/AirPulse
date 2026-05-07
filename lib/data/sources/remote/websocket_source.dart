import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketSource {
  final _clientsController = StreamController<List<String>>.broadcast();
  final _commandController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _newClientController = StreamController<String>.broadcast();

  final Map<String, WebSocketChannel> _clients = {};

  Stream<List<String>> get connectedClientsStream => _clientsController.stream;
  Stream<Map<String, dynamic>> get commandStream => _commandController.stream;
  /// Emite el clientId cada vez que se conecta un nuevo cliente.
  Stream<String> get newClientStream => _newClientController.stream;
  List<String> get connectedClientIds => _clients.keys.toList();

  void registerClient(String clientId, WebSocketChannel channel) {
    _clients[clientId] = channel;
    _clientsController.add(connectedClientIds);
    _newClientController.add(clientId);

    channel.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          data['_clientId'] = clientId;
          _commandController.add(data);
        } catch (_) {}
      },
      onDone: () => removeClient(clientId),
      onError: (_) => removeClient(clientId),
    );
  }

  void removeClient(String clientId) {
    _clients.remove(clientId);
    _clientsController.add(connectedClientIds);
  }

  void broadcast(Map<String, dynamic> data) {
    final message = jsonEncode(data);
    for (final client in _clients.values) {
      client.sink.add(message);
    }
  }

  void sendToClient(String clientId, Map<String, dynamic> data) {
    _clients[clientId]?.sink.add(jsonEncode(data));
  }

  void dispose() {
    for (final client in _clients.values) {
      client.sink.close();
    }
    _clients.clear();
    _clientsController.close();
    _commandController.close();
    _newClientController.close();
  }
}
