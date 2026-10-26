
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://vesper-8f787b421f31.herokuapp.com/api',
  );

  static const Duration timeout = Duration(seconds: 30);
}
