import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:enbridge/core/providers/aiva_provider.dart';

/// Calls the Nvidia NIM API (OpenAI-compatible) as the AIVA persona.
/// API key is injected at build time: --dart-define=NVIDIA_API_KEY=...
class NvidiaService {
  NvidiaService._();
  static final instance = NvidiaService._();

  static const _apiKey = String.fromEnvironment('NVIDIA_API_KEY');
  static const _baseUrl = 'https://integrate.api.nvidia.com/v1';
  static const _model = 'meta/llama-3.1-8b-instruct';

  static const _systemPrompt =
      'You are AIVA, an AI productivity companion embedded in the Enbridge '
      'productivity app, created by AIVA Freelancia. Your mission is to guide '
      'users toward maximum productivity and personal potential.\n\n'
      'You specialize in: goal setting, task prioritization, deep focus '
      'strategies, habit formation, time management, and overcoming '
      'procrastination. Use proven frameworks (Atomic Habits, GTD, deep work, '
      'Pomodoro, Eisenhower matrix) where relevant.\n\n'
      'Personality: warm, encouraging, concise, and action-oriented. Give '
      'specific actionable advice. Keep responses under 200 words unless the '
      'user asks for detail. If asked about topics unrelated to productivity, '
      'gently redirect to how they connect to the user\'s goals.';

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Send the full conversation history and return AIVA's reply.
  Future<String> chat(List<ChatMessage> history) async {
    if (!isConfigured) {
      return 'AIVA is not yet connected — add your Nvidia API key via '
          '--dart-define=NVIDIA_API_KEY=your_key when running the app.';
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      ...history.map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          }),
    ];

    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 512,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      return (choices.first['message']['content'] as String).trim();
    } else {
      throw Exception('Nvidia API ${response.statusCode}: ${response.body}');
    }
  }
}
