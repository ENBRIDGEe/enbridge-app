import 'dart:convert';

import 'package:enbridge/core/models/aiva_chat_message.dart';
import 'package:enbridge/core/supabase/supabase_client.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    final decodedArguments = jsonDecode(
      (json['function'] as Map<String, dynamic>)['arguments'] as String,
    );
    return ToolCall(
      id: json['id'] as String,
      name: (json['function'] as Map<String, dynamic>)['name'] as String,
      arguments: _normalizeArguments(decodedArguments),
    );
  }

  static Map<String, dynamic> _normalizeArguments(dynamic raw) {
    final decoded = _decodeNestedJson(raw);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }

  static dynamic _decodeNestedJson(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          return _decodeNestedJson(jsonDecode(trimmed));
        } catch (_) {
          return value;
        }
      }
      return value;
    }

    if (value is List) {
      return value.map(_decodeNestedJson).toList();
    }

    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (entry) => MapEntry(entry.key.toString(), _decodeNestedJson(entry.value)),
        ),
      );
    }

    return value;
  }
}

class ToolResultMessage {
  final String toolCallId;
  final String content;

  const ToolResultMessage({
    required this.toolCallId,
    required this.content,
  });
}

class NvidiaTurnResponse {
  final String text;
  final List<ToolCall> toolCalls;
  final Map<String, dynamic>? assistantMessage;

  const NvidiaTurnResponse({
    required this.text,
    this.toolCalls = const [],
    this.assistantMessage,
  });
}

class NvidiaService {
  NvidiaService._();

  static final instance = NvidiaService._();

  static const _apiKey = String.fromEnvironment('NVIDIA_API_KEY');
  static const _baseUrl = 'https://integrate.api.nvidia.com/v1';
  static const _localProxyUrl = 'http://localhost:8787/aiva-chat';
  static const _model = 'meta/llama-3.1-8b-instruct';

  static const _systemPrompt =
      'You are AIVA, an AI productivity companion inside the Enbridge mobile app. '
      'You can help users plan work, reduce overload, and take actions in the app. '
      'When a user explicitly asks to add, create, edit, update, complete, delete, or control something, '
      'use the matching tool instead of pretending it happened. '
      'Never claim an action succeeded unless the tool result confirms it. '
      'When the user asks for a multi-day plan, meal plan, study plan, workout plan, or checklist that should appear in the app, '
      'you must create visible app items for it instead of only describing it in chat. '
      'For meal or diet plans, create one task per day and put the meals for that day inside the task description. '
      'Use habits only for short recurring routines. Use tasks for dated day-by-day plans so users can see and complete each step. '
      'If the user asks to add a detailed plan to habits, create one short supporting habit and the detailed plan as tasks. '
      'If the user is only chatting or asking for advice, reply normally without calling tools. '
      'Use the live user data in context for personalised suggestions. '
      'Use plain language. Keep most responses concise, but when the user asks for a structured plan, return a clear day-by-day plan with enough detail to follow.';

  static const List<Map<String, dynamic>> _tools = [
    {
      'type': 'function',
      'function': {
        'name': 'add_habit',
        'description': 'Add a new daily habit to the Habits screen',
        'parameters': {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'The habit name, for example "Drink 2L water"',
            },
          },
          'required': ['title'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'create_plan_items',
        'description':
            'Create a visible multi-step plan in the app. Use this for multi-day diet plans, workout plans, study plans, routines, or checklists that the user should see as actionable items in the app. Create tasks for each day or major step. For meal plans, create one task per day and put breakfast, lunch, snack, and dinner inside that task description. Optionally add one or more short habits for recurring routines.',
        'parameters': {
          'type': 'object',
          'properties': {
            'plan_title': {
              'type': 'string',
              'description': 'Short name of the overall plan, for example "7-Day Diet Plan".',
            },
            'tasks': {
              'type': 'array',
              'description': 'Visible tasks to create, usually one per day or step.',
              'items': {
                'type': 'object',
                'properties': {
                  'title': {'type': 'string'},
                  'description': {
                    'type': 'string',
                    'description': 'Detailed instructions or meal list for this task.',
                  },
                  'due_date': {
                    'type': 'string',
                    'description':
                        'Due date in YYYY-MM-DD format based on the system TODAY date.',
                  },
                  'category': {
                    'type': 'string',
                    'description':
                        'Optional category such as Health, Study, Personal, Gym, or Others.',
                  },
                  'priority': {
                    'type': 'string',
                    'description': 'Optional priority: low, medium, high, or critical.',
                  },
                },
                'required': ['title'],
              },
            },
            'habits': {
              'type': 'array',
              'description':
                  'Optional short recurring habits that support the plan. Use brief titles only.',
              'items': {
                'type': 'object',
                'properties': {
                  'title': {'type': 'string'},
                },
                'required': ['title'],
              },
            },
          },
          'required': ['tasks'],
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
            'description': {
              'type': 'string',
              'description': 'Optional task details that users should be able to read in the Tasks screen.',
            },
            'due_date': {
              'type': 'string',
              'description':
                  'Due date in YYYY-MM-DD format based on the system TODAY date.',
            },
            'category': {
              'type': 'string',
              'description': 'Optional category such as Health, Study, Personal, Gym, or Others.',
            },
            'priority': {
              'type': 'string',
              'description': 'Optional priority: low, medium, high, or critical.',
            },
          },
          'required': ['title'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'update_task',
        'description': 'Edit a single existing task by partial title match',
        'parameters': {
          'type': 'object',
          'properties': {
            'match_title': {
              'type': 'string',
              'description': 'Full or partial title of the task to update.',
            },
            'new_title': {'type': 'string'},
            'description': {'type': 'string'},
            'due_date': {
              'type': 'string',
              'description':
                  'New due date in YYYY-MM-DD format. Send an empty string to clear it.',
            },
            'category': {'type': 'string'},
            'priority': {
              'type': 'string',
              'description': 'New priority: low, medium, high, or critical.',
            },
            'completed': {
              'type': 'boolean',
              'description': 'Set true to complete the task or false to reopen it.',
            },
          },
          'required': ['match_title'],
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
        'name': 'update_habit',
        'description': 'Edit a single existing habit by partial title match',
        'parameters': {
          'type': 'object',
          'properties': {
            'match_title': {
              'type': 'string',
              'description': 'Full or partial title of the habit to update.',
            },
            'new_title': {'type': 'string'},
          },
          'required': ['match_title'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'delete_habit',
        'description': 'Delete a habit from the Habits screen by partial title match',
        'parameters': {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'Full or partial habit title',
            },
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
                  'Date in YYYY-MM-DD format based on the system TODAY date.',
            },
            'time': {
              'type': 'string',
              'description': 'Time in HH:MM 24h format, for example "14:00"',
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
        'name': 'update_calendar_event',
        'description': 'Edit a single existing calendar event by partial title match',
        'parameters': {
          'type': 'object',
          'properties': {
            'match_title': {
              'type': 'string',
              'description': 'Full or partial event title to update.',
            },
            'new_title': {'type': 'string'},
            'date': {
              'type': 'string',
              'description':
                  'New event date in YYYY-MM-DD format based on the system TODAY date.',
            },
            'time': {
              'type': 'string',
              'description': 'New time in HH:MM 24h format.',
            },
            'description': {'type': 'string'},
          },
          'required': ['match_title'],
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

  bool get hasDirectFallbackKey => _apiKey.isNotEmpty;

  Future<NvidiaTurnResponse> startChat(
    List<ChatMessage> history, {
    String userContext = '',
  }) async {
    final messages = _buildPromptMessages(history, userContext: userContext);
    final response = await _post(
      messages,
      withTools: true,
    );

    final choice = response['choices'][0] as Map<String, dynamic>;
    final message = choice['message'] as Map<String, dynamic>;
    final finishReason = choice['finish_reason'] as String?;

    if (finishReason == 'tool_calls' && message['tool_calls'] is List<dynamic>) {
      final rawCalls = message['tool_calls'] as List<dynamic>;
      return NvidiaTurnResponse(
        text: (message['content'] as String?)?.trim() ?? '',
        toolCalls: rawCalls
            .map((call) => ToolCall.fromJson(call as Map<String, dynamic>))
            .toList(),
        assistantMessage: message,
      );
    }

    final content = (message['content'] as String?)?.trim() ?? '';
    final pseudoToolCalls = _extractPseudoToolCalls(content);
    if (pseudoToolCalls.isNotEmpty) {
      return NvidiaTurnResponse(
        text: '',
        toolCalls: pseudoToolCalls,
        assistantMessage: _buildSyntheticAssistantMessage(pseudoToolCalls),
      );
    }

    return NvidiaTurnResponse(
      text: content,
    );
  }

  Future<String> completeToolCalls(
    List<ChatMessage> history, {
    required Map<String, dynamic> assistantMessage,
    required List<ToolResultMessage> toolResults,
    String userContext = '',
  }) async {
    final messages = [
      ..._buildPromptMessages(history, userContext: userContext),
      assistantMessage,
      ...toolResults.map(
        (result) => {
          'role': 'tool',
          'content': result.content,
          'tool_call_id': result.toolCallId,
        },
      ),
    ];

    final response = await _post(messages, withTools: false);
    return (response['choices'][0]['message']['content'] as String?)?.trim() ?? '';
  }

  List<Map<String, dynamic>> _buildPromptMessages(
    List<ChatMessage> history, {
    required String userContext,
  }) {
    final now = DateTime.now();
    final todayString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowString =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    final datePreamble =
        'TODAY IS $todayString. TOMORROW IS $tomorrowString. '
        'You must use these exact dates for relative date references such as '
        '"today", "tomorrow", and "next week".\n\n';

    final systemPrompt = datePreamble +
        _systemPrompt +
        (userContext.isEmpty ? '' : '\n\n$userContext');

    return [
      {'role': 'system', 'content': systemPrompt},
      ...history
          .where((message) => !message.isSystem)
          .map(
            (message) => {
              'role': message.isUser ? 'user' : 'assistant',
              'content': message.text,
            },
          ),
    ];
  }

  List<ToolCall> _extractPseudoToolCalls(String content) {
    final cleaned = _stripPseudoToolWrapper(content);
    if (cleaned.isEmpty ||
        (!cleaned.startsWith('{') && !cleaned.startsWith('['))) {
      return const [];
    }

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        final calls = <ToolCall>[];
        for (var i = 0; i < decoded.length; i++) {
          final call = _toolCallFromPseudoJson(decoded[i], i);
          if (call != null) {
            calls.add(call);
          }
        }
        return calls;
      }

      final singleCall = _toolCallFromPseudoJson(decoded, 0);
      return singleCall == null ? const [] : [singleCall];
    } catch (_) {
      return const [];
    }
  }

  String _stripPseudoToolWrapper(String content) {
    var cleaned = content.trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^<\|python_tag\|>\s*'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^```json\s*'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^```\s*'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'\s*```$'), '');
    return cleaned.trim();
  }

  ToolCall? _toolCallFromPseudoJson(dynamic raw, int index) {
    if (raw is! Map) {
      return null;
    }

    final mapped = Map<String, dynamic>.from(raw as Map);
    final function = mapped['function'];
    final name = mapped['name'] as String? ??
        (function is Map ? function['name'] as String? : null);
    final arguments = _coercePseudoArguments(
      mapped['parameters'] ?? mapped['arguments'] ?? (function is Map ? function['arguments'] : null),
    );

    if (name == null || arguments == null) {
      return null;
    }

    return ToolCall(
      id: 'pseudo_${DateTime.now().microsecondsSinceEpoch}_$index',
      name: name,
      arguments: arguments,
    );
  }

  Map<String, dynamic>? _coercePseudoArguments(dynamic raw) {
    final decoded = _decodeNestedJson(raw);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  dynamic _decodeNestedJson(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          return _decodeNestedJson(jsonDecode(trimmed));
        } catch (_) {
          return value;
        }
      }
      return value;
    }

    if (value is List) {
      return value.map(_decodeNestedJson).toList();
    }

    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (entry) => MapEntry(entry.key.toString(), _decodeNestedJson(entry.value)),
        ),
      );
    }

    return value;
  }

  Map<String, dynamic> _buildSyntheticAssistantMessage(List<ToolCall> toolCalls) {
    return {
      'role': 'assistant',
      'content': '',
      'tool_calls': toolCalls
          .map(
            (call) => {
              'id': call.id,
              'type': 'function',
              'function': {
                'name': call.name,
                'arguments': jsonEncode(call.arguments),
              },
            },
          )
          .toList(),
    };
  }

  Future<Map<String, dynamic>> _post(
    List<Map<String, dynamic>> messages, {
    required bool withTools,
  }) async {
    final body = <String, dynamic>{
      'model': _model,
      'messages': messages,
      'temperature': 0.6,
      'max_tokens': 900,
      if (withTools) 'tools': _tools,
      if (withTools) 'tool_choice': 'auto',
    };

    try {
      return await _postViaEdgeFunction(body);
    } catch (edgeError) {
      if (kIsWeb && hasDirectFallbackKey) {
        try {
          return await _postViaLocalProxy(body);
        } catch (proxyError) {
          throw Exception(
            'Edge function failed: $edgeError\nLocal proxy failed: $proxyError',
          );
        }
      }

      if (!hasDirectFallbackKey) {
        rethrow;
      }

      try {
        return await _postDirect(body);
      } catch (directError) {
        throw Exception(
          'Edge function failed: $edgeError\nDirect fallback failed: $directError',
        );
      }
    }
  }

  Future<Map<String, dynamic>> _postViaEdgeFunction(
    Map<String, dynamic> body,
  ) async {
    final response = await supabase.functions.invoke('aiva-chat', body: body);
    final data = response.data;

    if (data is Map) {
      final mapped = Map<String, dynamic>.from(data);
      if (mapped['error'] != null) {
        throw Exception(mapped['error']);
      }
      return mapped;
    }

    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        final mapped = Map<String, dynamic>.from(decoded);
        if (mapped['error'] != null) {
          throw Exception(mapped['error']);
        }
        return mapped;
      }
    }

    throw Exception('Unexpected edge function response');
  }

  Future<Map<String, dynamic>> _postViaLocalProxy(
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse(_localProxyUrl),
          headers: const {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Local AIVA proxy ${response.statusCode}: ${response.body}');
  }

  Future<Map<String, dynamic>> _postDirect(Map<String, dynamic> body) async {
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
