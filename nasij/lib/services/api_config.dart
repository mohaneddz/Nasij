class ApiConfig {
  // Use 10.0.2.2 for Android Emulator connecting to localhost
  // Or replace with your ngrok URL or network IP
  static const String baseUrl = 'http://10.0.2.2:8001';
  static const String apiPrefix = '/api';

  static String get apiUrl => '$baseUrl$apiPrefix';
}
