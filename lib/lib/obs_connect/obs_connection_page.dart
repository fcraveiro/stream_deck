import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stream_deck/lib/obs_control_panel/obs_control_panel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:developer';

class OBSConnectionPage extends StatefulWidget {
  const OBSConnectionPage({super.key});

  @override
  State<OBSConnectionPage> createState() => _OBSConnectionPageState();
}

class _OBSConnectionPageState extends State<OBSConnectionPage> {
  late IOWebSocketChannel _channel;
  bool _isConnected = false; // Variável agora será usada corretamente
  String _status = 'Desconectado';

  final TextEditingController _ipController =
      TextEditingController(text: '192.168.0.107');
  final TextEditingController _portController =
      TextEditingController(text: '4455');
  final TextEditingController _passwordController =
      TextEditingController(text: 'jj3IlRBaPaTUFCtI');

  @override
  void initState() {
    super.initState();
  }

  void _connectToOBS() {
    final ip = _ipController.text;
    final port = _portController.text;

    setState(() {
      _status = 'Conectando...';
    });

    try {
      _channel = IOWebSocketChannel.connect('ws://$ip:$port');
      _channel.stream.listen(
        (message) {
          log('Mensagem recebida: $message');
          final response = json.decode(message);
          if (response['op'] == 0) {
            _authenticate(_passwordController.text);
          } else if (response['op'] == 2) {
            _handleAuthResponse(response);
          }
        },
        onDone: () {
          setState(() {
            _isConnected = false;
            _status = 'Desconectado';
          });
        },
        onError: (error) {
          log('Erro na conexão: $error');
          setState(() {
            _isConnected = false;
            _status = 'Erro: $error';
          });
        },
      );
    } catch (e) {
      log('Erro ao conectar: $e');
      setState(() {
        _status = 'Erro na conexão: $e';
      });
    }
  }

  void _authenticate(String password) {
    final authMessage = json.encode({
      'op': 1,
      'd': {
        'rpcVersion': 1,
        'authentication': password,
        'eventSubscriptions': 33
      }
    });

    log('Mensagem de autenticação: $authMessage');
    _channel.sink.add(authMessage);
  }

  void _handleAuthResponse(Map<String, dynamic> response) {
    if (response['d']['negotiatedRpcVersion'] != null) {
      setState(() {
        _isConnected = true; // Atualiza o estado de conexão
        _status = 'Conectado';
      });

      // Checa se está conectado antes de navegar
      if (_isConnected) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OBSControlPanel(channel: _channel),
          ),
        );
      }
    } else {
      setState(() {
        _isConnected = false; // Atualiza o estado de conexão em caso de falha
        _status = 'Erro de autenticação';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar ao OBS'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(labelText: 'IP do OBS'),
            ),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(labelText: 'Porta do OBS'),
            ),
            TextField(
              controller: _passwordController,
              decoration:
                  const InputDecoration(labelText: 'Senha do WebSocket'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isConnected
                  ? null
                  : _connectToOBS, // Desabilita botão se já conectado
              child: const Text('Conectar ao OBS'),
            ),
            const SizedBox(height: 20),
            Text('Status: $_status'),
          ],
        ),
      ),
    );
  }
}
