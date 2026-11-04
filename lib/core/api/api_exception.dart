class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  final int statusCode;
  final String code;
  final String message;
  final Object? details;

  bool get isNetwork => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isRateLimited => statusCode == 429;

  factory ApiException.network() => const ApiException(
    statusCode: 0,
    code: 'NETWORK',
    message:
        "Can't reach Vesper. Check your internet connection and try again.",
  );

  factory ApiException.fromBody(int statusCode, Object? body) {
    if (body is Map<String, dynamic>) {
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        final msg = first is Map ? first['msg']?.toString() : null;
        return ApiException(
          statusCode: statusCode,
          code: 'VALIDATION_ERROR',
          message: msg ?? _fallback(statusCode),
          details: errors,
        );
      }
      final detail = body['detail'];
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        final msg = first is Map ? first['msg']?.toString() : null;
        return ApiException(
          statusCode: statusCode,
          code: 'VALIDATION_ERROR',
          message: msg ?? _fallback(statusCode),
          details: detail,
        );
      }
      if (detail is String) {
        return ApiException(
          statusCode: statusCode,
          code: 'ERROR',
          message: detail,
        );
      }
    }
    return ApiException(
      statusCode: statusCode,
      code: 'ERROR',
      message: _fallback(statusCode),
    );
  }

  static String _fallback(int status) {
    if (status == 401) return 'Please sign in again.';
    if (status == 403) return "You don't have access to this.";
    if (status == 404) return 'Not found.';
    if (status == 429) return 'Too many tries. Please wait a moment.';
    if (status >= 500)
      return 'Vesper is having a problem. Please try again soon.';
    return 'Something went wrong. Please try again.';
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
