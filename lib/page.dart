import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:developer';

class OBSControlPage extends StatefulWidget {
  const OBSControlPage({super.key});

  @override
  State<OBSControlPage> createState() => _OBSControlPageState();
}

class _OBSControlPageState extends State<OBSControlPage> {
  late IOWebSocketChannel _channel;
  bool _isConnected = false;
  String _status = 'Desconectado';
  List<String> _sceneList = [];
  String? _currentScene;

  final TextEditingController _ipController =
      TextEditingController(text: '192.168.0.107');
  final TextEditingController _portController =
      TextEditingController(text: '4455');
  final TextEditingController _passwordController =
      TextEditingController(text: 'jj3IlRBaPaTUFCtI');

  int _messageId = 1;

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
          } else if (response['op'] == 7) {
            _handleCommandResponse(response);
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
        _isConnected = true;
        _status = 'Conectado';
      });
      _getSceneList();
    } else {
      setState(() {
        _status = 'Erro de autenticação';
      });
    }
  }

  void _sendCommand(String requestType,
      [Map<String, dynamic>? additionalParams]) {
    if (_isConnected) {
      final request = {
        'op': 6,
        'd': {
          'requestType': requestType,
          'requestId': (_messageId++).toString(),
          ...?additionalParams,
        }
      };
      log('Enviando comando: ${json.encode(request)}');
      _channel.sink.add(json.encode(request));
    } else {
      log('Não conectado. Não é possível enviar comando.');
    }
  }

  void _handleCommandResponse(Map<String, dynamic> response) {
    final requestType = response['d']['requestType'];
    final requestStatus = response['d']['requestStatus'];

    if (requestStatus['result'] == true) {
      log('Comando $requestType executado com sucesso');
      if (requestType == 'GetSceneList') {
        _updateSceneList(response['d']['responseData']['scenes']);
      } else if (requestType == 'SetCurrentProgramScene') {
        _updateCurrentScene(response['d']['requestData']['sceneName']);
      }
    } else {
      log('Erro ao executar o comando $requestType: ${requestStatus['comment']}');
      if (requestType == 'SetCurrentProgramScene') {
        // Se houver erro ao mudar a cena, restaure a cena atual para o valor anterior
        setState(() {
          _currentScene =
              _sceneList.firstWhere((scene) => scene == _currentScene);
        });
      }
    }
  }

  void _getSceneList() {
    _sendCommand('GetSceneList');
  }

  void _updateSceneList(List<dynamic> scenes) {
    setState(() {
      _sceneList = scenes.map((scene) => scene['sceneName'] as String).toList();
      if (_sceneList.isNotEmpty && _currentScene == null) {
        _currentScene = _sceneList.first;
      }
    });
  }

  void _setCurrentScene(String? sceneName) {
    if (sceneName != null && sceneName != _currentScene) {
      log('Tentando trocar para a cena: $sceneName');
      // Atualize o estado para desativar o dropdown até que a cena seja trocada
      setState(() {
        _currentScene = sceneName;
      });
      _sendCommand('SetCurrentProgramScene', {'sceneName': sceneName});
    }
  }

  void _updateCurrentScene(String sceneName) {
    setState(() {
      _currentScene = sceneName;
    });
  }

  void _setStudioMode(bool enable) {
    if (_isConnected) {
      final request = {
        'op': 6,
        'd': {
          'requestType': 'SetStudioModeEnabled',
          'requestId': (_messageId++).toString(),
          'requestData': {
            'studioModeEnabled': enable,
          },
        }
      };
      log('Enviando comando para alterar Modo Estúdio: ${json.encode(request)}');
      _channel.sink.add(json.encode(request));
    }
  }

  void _enableStudioMode() {
    _setStudioMode(true);
  }

  void _disableStudioMode() {
    _setStudioMode(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle OBS'),
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
              onPressed: _connectToOBS,
              child: const Text('Conectar ao OBS'),
            ),
            const SizedBox(height: 20),
            Text('Status: $_status'),
            const SizedBox(height: 20),
            const Text('Controles de Gravação e Transmissão',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                      _isConnected ? () => _sendCommand('StartRecord') : null,
                  child: const Text('Iniciar Gravação'),
                ),
                ElevatedButton(
                  onPressed:
                      _isConnected ? () => _sendCommand('StopRecord') : null,
                  child: const Text('Parar Gravação'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                      _isConnected ? () => _sendCommand('StartStream') : null,
                  child: const Text('Iniciar Transmissão'),
                ),
                ElevatedButton(
                  onPressed:
                      _isConnected ? () => _sendCommand('StopStream') : null,
                  child: const Text('Parar Transmissão'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Controle de Cenas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _currentScene,
              onChanged: _isConnected ? _setCurrentScene : null,
              items: _sceneList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              hint: const Text('Selecione uma cena'),
              isExpanded: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isConnected ? _enableStudioMode : null,
              child: const Text('Ativar Modo Estúdio'),
            ),
            ElevatedButton(
              onPressed: _isConnected ? _disableStudioMode : null,
              child: const Text('Desativar Modo Estúdio'),
            ),
          ],
        ),
      ),
    );
  }
}
