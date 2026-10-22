class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String testUserId = String.fromEnvironment('TEST_USER_ID');

  static Map<String, String> headers() =>
      testUserId.isEmpty ? const {} : {'X-Test-User-ID': testUserId};
}