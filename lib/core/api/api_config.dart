class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://vesper-8f787b421f31.herokuapp.com/api',
  );

  static const String testUserId = String.fromEnvironment('TEST_USER_ID');

  // Add this line to resolve the compilation error:
  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> headers() =>
      testUserId.isEmpty ? const {} : {'X-Test-User-ID': testUserId};
}
