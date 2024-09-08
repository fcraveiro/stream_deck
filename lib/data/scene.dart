class SceneObs {
  final String name;
  final String uuid;

  SceneObs(this.name, this.uuid);

  factory SceneObs.fromJson(Map<String, dynamic> json) {
    return SceneObs(
      json['sceneName'] as String,
      json['sceneUuid'] as String,
    );
  }
}
