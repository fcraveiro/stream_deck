import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:stream_deck/lib/notifier.dart';
import 'package:stream_deck/test_two/data/scene.dart';
import 'package:stream_deck/test_two/obs_socket/obs_socket.dart';

class ObsPageControl extends StatefulWidget {
  const ObsPageControl({super.key});

  @override
  State<ObsPageControl> createState() => _ObsPageControlState();
}

class _ObsPageControlState extends State<ObsPageControl> {
  final OBSWebSocketManager _obsManager = OBSWebSocketManager();
  final NotifierList<SceneObs> _sceneList = NotifierList([]);
  String? _currentScene;

  final Notifier<bool> _recordModeEnabled = Notifier(false);
  final Notifier<bool> _liveModeEnabled = Notifier(false);
  final Notifier<bool> _studioModeEnabled = Notifier(false);

  @override
  void initState() {
    super.initState();
    _obsManager.addListener(_onMessageReceived);
    _checkConnectionAndFetchScenes();
  }

  void _checkConnectionAndFetchScenes() {
    if (_obsManager.isConnected) {
      _getSceneList();
    } else {
      // Handle the case when not connected (e.g., show an error message)
    }
  }

  void _onMessageReceived(dynamic message) {
    final response = json.decode(message);
    if (response['op'] == 7) {
      _handleCommandResponse(response);
    }
  }

  void _handleCommandResponse(Map<String, dynamic> response) {
    final requestType = response['d']['requestType'];
    final requestStatus = response['d']['requestStatus'];

    if (requestStatus['result'] == true) {
      if (requestType == 'GetSceneList') {
        _updateSceneList(response['d']['responseData']['scenes']);
      } else if (requestType == 'SetCurrentProgramScene') {
        _updateCurrentScene(response['d']['requestData']['sceneName']);
      }
    } else {
      // Trate erros conforme necessário
    }
  }

  void _getSceneList() {
    _obsManager.sendCommand('GetSceneList');
  }

  void _updateSceneList(List<dynamic> scenes) {
    final sceneObjects = scenes.map((scene) {
      final id = scene['sceneUuid'] as String;
      final name = scene['sceneName'] as String;
      return SceneObs(name, id);
    }).toList();
    _sceneList.value = UnmodifiableListView(sceneObjects);
    log('Lista de cenas atualizada NOME : ${sceneObjects.map((scene) => scene.name).toList()}');
    log('Lista de cenas atualizada UUID : ${sceneObjects.map((scene) => scene.uuid).toList()}');
  }

  void _updateCurrentScene(String sceneName) {
    setState(() {
      _currentScene = sceneName;
    });
  }

  void _recordMode(bool enabled) {
    enabled
        ? _obsManager.sendCommand('StopRecord')
        : _obsManager.sendCommand('StartRecord');
    _recordModeEnabled.value = !enabled;
  }

  void _startStreaming() {
    _obsManager.sendCommand('StartStream');
    _liveModeEnabled.value = true;
  }

  void _stopStreaming() {
    _obsManager.sendCommand('StopStream');
    _liveModeEnabled.value = false;
  }

  void _studioModeOff(bool enabled) {
    _obsManager.setStudioMode(enabled);
    _studioModeEnabled.value = enabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle do OBS'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 20),
            const Text('Controles',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _liveModeEnabled.show(
              (enabled) => Center(
                child: InkWell(
                  onTap: () => enabled ? _stopStreaming() : _startStreaming(),
                  child: button(enabled, 'Live'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _recordModeEnabled.show(
              (enabled) => Center(
                child: InkWell(
                  onTap: () => _recordMode(enabled),
                  child: button(enabled, 'Gravação'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _studioModeEnabled.show(
              (enabled) => InkWell(
                onTap: () => _studioModeOff(!enabled),
                child: button(enabled, 'Estúdio'),
              ),
            ),
            _sceneList.show(
              (sceneList) => DropdownButton<String>(
                value: _currentScene,
                hint: const Text('Selecione uma cena'),
                onChanged: (String? newScene) {
                  setState(() {
                    _currentScene = newScene;
                  });
                  if (newScene != null) {
                    _obsManager.sendCommand('SetCurrentProgramScene', {
                      'sceneName': newScene,
                    });
                  }
                },
                items: sceneList.map((scene) {
                  return DropdownMenuItem<String>(
                    value: scene.name,
                    child: Text(scene.name),
                  );
                }).toList(),
              ),
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

  Widget button(bool enabled, String title) {
    return Center(
      child: Container(
        width: 130,
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? Colors.red[500] : Colors.blue[500],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
        ),
        child: Text(
          enabled ? '$title\nAtivado' : '$title\nDesativado',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
