import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackendConfig {
  const BackendConfig({required this.generateStoryEndpointUrl});

  final String generateStoryEndpointUrl;
}

/// Flutter tarafında endpoint URL'nin tek noktadan yönetilmesi.
///
/// MVP varsayılanı placeholder'dır; gerçek Cloud Functions URL'siyle
/// değiştirilecektir.
final backendConfigProvider = Provider<BackendConfig>((ref) {
  const defaultEndpoint =
      'https://us-central1-masal-evi-b3a1e.cloudfunctions.net/generateStory';
  const baseUrl = String.fromEnvironment('FUNCTION_BASE_URL', defaultValue: '');
  const path = String.fromEnvironment(
    'GENERATE_STORY_HTTP_PATH',
    defaultValue: '/generateStory',
  );
  final endpointUrl = baseUrl.isEmpty ? defaultEndpoint : '$baseUrl$path';
  return BackendConfig(generateStoryEndpointUrl: endpointUrl);
});
