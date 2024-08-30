class Plug<T> {
  // Função de callback genérica
  Function? _callback;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Método para definir um callback sem argumento
  void then(Function() f) {
    _isConnected = true;
    _callback = f;
  }

  // Método para definir um callback com argumento
  void take(Function(T) f) {
    _isConnected = true;
    _callback = f;
  }

  // Chama o callback sem argumento
  Future<void> call() async {
    if (_callback is Function()) {
      await (_callback as Function())();
    }
  }

  // Chama o callback com argumento
  Future<void> send(T arg) async {
    if (_callback is Function(T)) {
      await (_callback as Function(T))(arg);
    }
  }
}
