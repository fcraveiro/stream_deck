import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_view_controller/flutter_view_controller.dart';
import 'package:stream_deck/data/scene.dart';
import 'package:stream_deck/obs_socket/obs_socket.dart';

class ObsPageControlController extends Controller {
  final OBSWebSocketManager _obsManager = OBSWebSocketManager();
  // ignore: unused_field
  String? _currentScene;

  final NotifierList<SceneObs> _sceneList = NotifierList();
  final NotifierList<Widget> buttonsObs = NotifierList();
  final Notifier<String?> currentScene = Notifier('');
  final Notifier<bool> _recordModeEnabled = Notifier(false);
  final Notifier<bool> _studioModeEnabled = Notifier(false);
  final Notifier<bool> _liveModeEnabled = Notifier(false);
  final Notifier<bool> isConnected = Notifier(true);

  @override
  onInit() {
    _obsManager.addListener(_onMessageReceived);
    _checkConnectionAndFetchScenes();
    guardaWidgets();
  }

  void _checkConnectionAndFetchScenes() {
    if (_obsManager.isConnected) {
      _getSceneList();
    } else {
      // Handle the case when not connected (e.g., show an error message)
    }
  }

  guardaWidgets() {
    buttonsObs.value = [
      _liveModeEnabled.show(
        (enabled) => GestureDetector(
          onTap: () => enabled ? _stopStreaming() : _startStreaming(),
          child: button(enabled, 'Live', MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height),
        ),
      ),
      _recordModeEnabled.show(
        (enabled) => GestureDetector(
          onTap: () => _recordMode(enabled),
          child: button(enabled, 'Gravação', MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height),
        ),
      ),
      _studioModeEnabled.show(
        (enabled) => GestureDetector(
          onTap: () => _studioModeOff(!enabled),
          child: button(enabled, 'Estúdio', MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height),
        ),
      ),
      _studioModeEnabled.show(
        (enabled) => GestureDetector(
          onTap: () => _studioModeOff(!enabled),
          child: button(enabled, 'Vazio', MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height),
        ),
      ),
    ];
  }

  _onMessageReceived(dynamic message) {
    if (message == "desconectado") {
      return isConnected.value = false;
    }
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
    // log('Lista de cenas atualizada NOME : ${sceneObjects.map((scene) => scene.name).toList()}');
    // log('Lista de cenas atualizada UUID : ${sceneObjects.map((scene) => scene.uuid).toList()}');
  }

  void _updateCurrentScene(String sceneName) {
    currentScene.value = sceneName;
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
  onClose() {
    _obsManager.disconnect();
  }
}

class ObsPageControlView extends ViewOf<ObsPageControlController> {
  ObsPageControlView({super.key, required super.controller, super.size});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: controller.isConnected.show(
        (value) => value
            ? Container(
                width: double.infinity,
                height: double.infinity,
                color: controller.isConnected.value
                    ? Colors.blue.shade200
                    : Colors.red.shade200,
                child: Padding(
                  padding: EdgeInsets.only(
                      left: size.width(3.5), right: size.width(3.5)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Controles',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 3, // Número de colunas
                            crossAxisSpacing: size.width(2.5),
                            mainAxisSpacing: size.height(1.5),
                            children: controller.buttonsObs.value,
                          ),
                        ),
                      ]),
                ),
              )
            : Container(
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                color: controller.isConnected.value
                    ? Colors.blue.shade200
                    : Colors.red.shade200,
                child: const Text('Desconectado')),
      ),
    );
  }
}

Widget button(bool enabled, String title, double width, double height) {
  log('Button enabled: $enabled');
  log('Button title: $title');
  log('Button size: ${width.toString()}');
  log('Button size: ${height.toString()}');
  return Align(
    alignment: Alignment.center,
    child: Container(
      width: width / 3,
      height: width / 3,
      alignment: Alignment.center,
      // margin: EdgeInsets.only(left: width / 98, right: width / 98),
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
