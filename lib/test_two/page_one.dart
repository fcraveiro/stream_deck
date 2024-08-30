import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:stream_deck/test_two/obs_socket/obs_socket.dart';
import 'package:stream_deck/test_two/page_two.dart';

class ObsPageConnection extends StatefulWidget {
  const ObsPageConnection({super.key});

  @override
  ObsPageConnectionState createState() => ObsPageConnectionState();
}

class ObsPageConnectionState extends State<ObsPageConnection> {
  final OBSWebSocketManager _obsManager = OBSWebSocketManager();
  final TextEditingController _ipController =
      TextEditingController(text: '192.168.0.107');
  final TextEditingController _portController =
      TextEditingController(text: '4455');
  final TextEditingController _passwordController =
      TextEditingController(text: 'jj3IlRBaPaTUFCtI');

  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _obsManager.addListener(_onMessageReceived);
  }

  void _onMessageReceived(dynamic message) {
    log('Message from OBS: $message');
  }

  void _connectToOBS() {
    final ip = _ipController.text;
    final port = _portController.text;
    final password = _passwordController.text;
    final url = 'ws://$ip:$port'; // Incluindo a porta no URL

    _obsManager.connect(
      url,
      password: password, // Passando a senha para o método connect
      onConnect: () {
        setState(() {
          _isConnected = true;
        });
        log('Connected to OBS!');
      },
      onDisconnect: () {
        setState(() {
          _isConnected = false;
        });
        log('Disconnected from OBS.');
      },
      onError: (error) {
        log('Connection error: $error');
      },
    );
  }

  _goToPageControl() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ObsPageControl(),
      ),
    );
  }

  void _disconnectFromOBS() {
    _obsManager.disconnect();
    setState(() {
      _isConnected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OBS WebSocket Connection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(labelText: 'IP do OBS'),
              keyboardType: TextInputType.text,
            ),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(labelText: 'Porta do OBS'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _passwordController,
              decoration:
                  const InputDecoration(labelText: 'Senha do WebSocket'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isConnected ? _disconnectFromOBS : _connectToOBS,
              child: Text(_isConnected ? 'Desconectar' : 'Conectar'),
            ),
            const SizedBox(height: 20),
            Text(
              _isConnected ? 'Conectado ao OBS' : 'Desconectado',
              style: TextStyle(
                color: _isConnected ? Colors.green : Colors.red,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _goToPageControl,
              child: const Text('Controle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _obsManager.disconnect();
    super.dispose();
  }
}
