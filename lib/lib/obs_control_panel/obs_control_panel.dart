import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:developer';

class OBSControlPanel extends StatefulWidget {
  final IOWebSocketChannel channel;

  const OBSControlPanel({super.key, required this.channel});

  @override
  State<OBSControlPanel> createState() => _OBSControlPanelState();
}

class _OBSControlPanelState extends State<OBSControlPanel> {
  final bool _isConnected = true;
  List<String> _sceneList = [];
  String? _currentScene;
  final String _status = 'Conectado';
  bool _studioModeEnabled =
      false; // Adiciona variável de estado para o Modo Estúdio
  int _messageId = 1;

  @override
  void initState() {
    super.initState();
    _getSceneList();
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
      widget.channel.sink.add(json.encode(request));
    } else {
      log('Não conectado. Não é possível enviar comando.');
    }
  }

  // ignore: unused_element
  void _handleCommandResponse(Map<String, dynamic> response) {
    final requestType = response['d']['requestType'];
    final requestStatus = response['d']['requestStatus'];

    if (requestStatus['result'] == true) {
      log('Comando $requestType executado com sucesso');
      if (requestType == 'GetSceneList') {
        log('Cenas disponíveis: ${response['d']['responseData']['scenes']}');
        _updateSceneList(response['d']['responseData']['scenes']);
      } else if (requestType == 'SetCurrentProgramScene') {
        _updateCurrentScene(response['d']['requestData']['sceneName']);
      } else if (requestType == 'SetStudioModeEnabled') {
        _updateStudioMode(response['d']['requestData']['studioModeEnabled']);
      }
    } else {
      log('Erro ao executar o comando $requestType: ${requestStatus['comment']}');
      if (requestType == 'SetCurrentProgramScene') {
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
      widget.channel.sink.add(json.encode(request));

      setState(() {
        _studioModeEnabled = enable; // Atualiza o estado local
      });
    }
  }

  void _updateStudioMode(bool enabled) {
    setState(() {
      _studioModeEnabled = enabled;
    });
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
            const Text('Modo Estúdio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Desabilitado'),
                Switch(
                  value: _studioModeEnabled, // Usando a variável de estado
                  onChanged: _isConnected ? _setStudioMode : null,
                ),
                const Text('Habilitado'),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Lista de Cenas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: DropdownButton<String>(
                value: _currentScene,
                items: _sceneList.map((String scene) {
                  return DropdownMenuItem<String>(
                    value: scene,
                    child: Text(scene),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  _setCurrentScene(newValue);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
