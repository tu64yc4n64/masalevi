import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackendConfig {
  const BackendConfig({
    required this.baseUrl,
    required this.generateStoryEndpointUrl,
  });

  final String baseUrl;
  final String generateStoryEndpointUrl;
}

/// Flutter tarafında endpoint URL'nin tek noktadan yönetilmesi.
///
final backendConfigProvider = Provider<BackendConfig>((ref) {
  const defaultBaseUrl = 'https://masalevi.onrender.com';
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );
  const functionBaseUrl = String.fromEnvironment(
    'FUNCTION_BASE_URL',
    defaultValue: '',
  );
  const path = String.fromEnvironment(
    'GENERATE_STORY_HTTP_PATH',
    defaultValue: '/generateStory',
  );
  final endpointUrl = functionBaseUrl.isEmpty
      ? '$baseUrl$path'
      : '$functionBaseUrl$path';
  return BackendConfig(baseUrl: baseUrl, generateStoryEndpointUrl: endpointUrl);
});
