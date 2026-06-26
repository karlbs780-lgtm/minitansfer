/// Centralized app configuration.
class AppConfig {
  /// Base URL of the MiniTransfer REST API.
  ///
  /// Defaults to `10.0.2.2` which is how the Android emulator reaches the host
  /// machine's `localhost`. Override at build/run time, e.g.:
  ///
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080
  ///
  /// Use `http://localhost:8080` for the iOS simulator / Flutter web / desktop.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String currency = 'FCFA';
}
