import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:enbridge/core/providers/aiva_provider.dart';

class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const ToolCall({required this.id, required this.name, required this.arguments});

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
        id: json['id'] as String,
        name: (json['function'] as Map<String, dynamic>)['name'] as String,
        arguments: jsonDecode(
            (json['function'] as Map<String, dynamic>)['arguments'] as String)
            as Map<String, dynamic>,
      );
}

class NvidiaResponse {
  final String text;
  final List<ToolCall> toolCalls;

  const NvidiaResponse({required this.text, this.toolCalls = const []});
}

/// Calls the NVIDIA NIM API with tool calling enabled.
/// API key is injected at build time via --dart-define-from-file=.env.json
class NvidiaService {
  NvidiaService._();
  static final instance = NvidiaService._();

  static const _apiKey = String.fromEnvironment('NVIDIA_API_KEY');
  static const _baseUrl = 'https://integrate.api.nvidia.com/v1';
  static const _model = 'meta/llama-3.1-8b-instruct';

  static const _systemPrompt =
      'You are AIVA, an AI productivity companion in the Enbridge app. '
      'You have access to tools that let you directly add habits, tasks, '
      'calendar events, and control the focus timer. '
      'When the user asks you to add, create, complete, delete, or control '
      'something in the app, ALWAYS call the appropriate tool — do not just '
      'describe it in text. '
      'IMPORTANT: ONLY call a tool if the user explicitly requests an action. '
      'If the user just says hi, asks a question, or chats, reply normally and DO NOT call any tools. '
      'After calling a tool, confirm what you did briefly and naturally. '
      'Do NOT mention focus sessions, timers, or upcoming events unless the '
      'user specifically asks or the live context shows the timer is actively running. '
      'You have live data about the user\'s tasks, goals, habits, and calendar '
      'in the context — use it to give personalised advice. '
      'Keep replies concise (under 120 words).';

  static const List<Map<String, dynamic>> _tools = [
    {
      'type': 'function',
      'function': {
        'name': 'add_habit',
        'description': 'Add a new daily habit to track in the Habits screen',
        'parameters': {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'The habit name, e.g. "Drink 2L water"',
            },
          },
          'required': ['title'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'add_task',
        'description': 'Add a new task to the Tasks screen',
        'parameters': {
          'type': 'object',
          'properties': {
            'title': {'type': 'string'},
            'due_date': {
              'type': 'string',
              'description':
                  'Due date in YYYY-MM-DD format. Base it on the TODAY date at the top of the system prompt.',
            },
          },
          'required': ['title'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'complete_task',
        'description': 'Mark a task as completed by partial title match',
        'parameters': {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'Full or partial task title',
            },
          },
          'required': ['title'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'delete_task',
        'description': 'Delete a task by partial title match',
        'parameters': {
          'type': 'object',
          'properties': {
            'title': {'type': 'string'},
          },
          'required': ['title'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'add_calendar_event',
        'description': 'Add an event to the Calendar screen',
        'parameters': {
          'type': 'object',
          'properties': {
            'title': {'type': 'string'},
            'date': {
              'type': 'string',
              'description':
                  'Date in YYYY-MM-DD format. Base it on the TODAY date at the top of the system prompt.',
            },
            'time': {
              'type': 'string',
              'description': 'Time in HH:MM 24h format, e.g. "14:00"',
            },
            'description': {'type': 'string'},
          },
          'required': ['title', 'date'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'delete_calendar_event',
        'description': 'Delete an event from the Calendar screen by partial title match',
        'parameters': {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'Full or partial event title',
            },
          },
          'required': ['title'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'start_focus_timer',
        'description': 'Start the Pomodoro focus timer',
        'parameters': {
          'type': 'object',
          'properties': {
            'duration_minutes': {
              'type': 'integer',
              'description': 'Duration in minutes, default 25',
            },
          },
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'stop_focus_timer',
        'description': 'Pause the running focus timer',
        'parameters': {
          'type': 'object',
          'properties': {},
        },
      },
    },
  ];

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<NvidiaResponse> chat(
    List<ChatMessage> history, {
    String userContext = '',
  }) async {
    if (!isConfigured) {
      return const NvidiaResponse(
          text: 'AIVA is not connected — NVIDIA_API_KEY missing. '
              'Run: flutter run --dart-define-from-file=.env.json');
    }

    // Inject the real device date at the top of every request so the model
    // never falls back to its training-data date when computing due dates.
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tomorrowStr = () {
      final t = now.add(const Duration(days: 1));
      return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
    }();

    final datePreamble =
        'TODAY IS $todayStr. TOMORROW IS $tomorrowStr. '
        'You MUST use these exact dates for all date references '
        '("today", "tomorrow", "next week", etc.). '
        'NEVER use any date from your training data.\n\n';

    final fullPrompt = datePreamble +
        _systemPrompt +
        (userContext.isEmpty ? '' : '\n\n$userContext');

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': fullPrompt},
      ...history.map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          }),
    ];

    // Step 1: Call with tool definitions
    final resp1 = await _post(messages, withTools: true);
    final choice1 = resp1['choices'][0] as Map<String, dynamic>;
    final msg1 = choice1['message'] as Map<String, dynamic>;
    final finishReason = choice1['finish_reason'] as String?;

    // Model called one or more tools
    if (finishReason == 'tool_calls' && msg1.containsKey('tool_calls')) {
      final rawCalls = msg1['tool_calls'] as List<dynamic>;
      final toolCalls = rawCalls
          .map((c) => ToolCall.fromJson(c as Map<String, dynamic>))
          .toList();

      // Step 2: Follow-up with tool results so model gives a natural reply
      final messages2 = <Map<String, dynamic>>[
        ...messages,
        msg1, // assistant message with tool_calls
        ...toolCalls.map((c) => {
              'role': 'tool',
              'content': 'Success',
              'tool_call_id': c.id,
            }),
      ];

      final resp2 = await _post(messages2, withTools: false);
      final text =
          (resp2['choices'][0]['message']['content'] as String?)?.trim() ?? '';
      return NvidiaResponse(text: text, toolCalls: toolCalls);
    }

    // No tool call — plain conversational reply
    final text = (msg1['content'] as String?)?.trim() ?? '';
    return NvidiaResponse(text: text);
  }

  Future<Map<String, dynamic>> _post(
    List<Map<String, dynamic>> messages, {
    required bool withTools,
  }) async {
    final body = <String, dynamic>{
      'model': _model,
      'messages': messages,
      'temperature': 0.6,
      'max_tokens': 512,
    };
    if (withTools) {
      body['tools'] = _tools;
      body['tool_choice'] = 'auto';
    }

    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('NVIDIA API ${response.statusCode}: ${response.body}');
  }
}
