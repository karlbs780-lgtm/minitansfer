/// A typed error carrying the API's HTTP status, machine code and human message.
/// Falls back to a friendly default message for network failures.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final Map<String, String> fieldErrors;

  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.fieldErrors = const {},
  });

  bool get isUnauthorized => statusCode == 401;

  /// Builds an exception from a parsed error body returned by the backend.
  factory ApiException.fromResponse(int statusCode, dynamic body) {
    if (body is Map<String, dynamic>) {
      final rawFieldErrors = body['fieldErrors'];
      final fieldErrors = <String, String>{};
      if (rawFieldErrors is Map) {
        rawFieldErrors.forEach((key, value) {
          fieldErrors[key.toString()] = value.toString();
        });
      }
      // Prefer the first field error message when present (more actionable for the user).
      final message = fieldErrors.isNotEmpty
          ? fieldErrors.values.first
          : (body['message']?.toString() ?? 'Une erreur est survenue.');
      return ApiException(
        statusCode: statusCode,
        code: body['code']?.toString() ?? 'ERROR',
        message: message,
        fieldErrors: fieldErrors,
      );
    }
    return ApiException(
      statusCode: statusCode,
      code: 'ERROR',
      message: 'Une erreur est survenue (code $statusCode).',
    );
  }

  /// Used when the request never reached the server (no connectivity, timeout...).
  factory ApiException.network() {
    return ApiException(
      statusCode: 0,
      code: 'NETWORK_ERROR',
      message: 'Impossible de joindre le serveur. Verifiez votre connexion et l\'adresse de l\'API.',
    );
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
