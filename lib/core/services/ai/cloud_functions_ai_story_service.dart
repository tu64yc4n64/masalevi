import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'ai_story_service.dart';

class CloudFunctionsAiStoryService implements AiStoryService {
  CloudFunctionsAiStoryService({required this.generateStoryEndpointUrl});

  final String generateStoryEndpointUrl;

  @override
  Future<AiStoryResult> generateStory(AiStoryRequest request) async {
    final safe = sanitizeAiRequest(request);
    final currentUser = FirebaseAuth.instance.currentUser;
    final idToken = await currentUser?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Firebase oturumu bulunamadi.');
    }

    final response = await http.post(
      Uri.parse(generateStoryEndpointUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'childId': safe.childId,
        'childName': safe.childName,
        'age': safe.age,
        'gender': safe.gender,
        'theme': safe.theme,
        'value': safe.value,
        'length': safe.length.name,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'generateStory failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return AiStoryResult(
      storyId: decoded['storyId'] as String?,
      title: decoded['title'] as String? ?? 'Masal',
      content: decoded['content'] as String? ?? '',
    );
  }
}
