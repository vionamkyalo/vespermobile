class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://relive-mummified-jovial.ngrok-free.dev/api',
  );

  static const Duration timeout = Duration(seconds: 30);
}
