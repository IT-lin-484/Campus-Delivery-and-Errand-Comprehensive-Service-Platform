class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static String resolveApiUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return value;
    }
    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return parsed.toString();
    }
    final baseUri = Uri.parse(apiBaseUrl);
    final normalizedPath = value.startsWith('/') ? value : '/$value';
    return baseUri.replace(path: normalizedPath).toString();
  }

  static Uri buildWebSocketUri(String token) {
    final baseUri = Uri.parse(apiBaseUrl);
    final websocketScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    return baseUri.replace(
      scheme: websocketScheme,
      path: '/ws/chat',
      queryParameters: <String, String>{'token': token},
    );
  }
}
