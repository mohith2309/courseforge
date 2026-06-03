import 'dart:convert';
import 'package:http/http.dart' as http;

/// NVIDIA NIM (OpenAI-compatible) provider. Fast and cheap — used for quick
/// conversational tasks (doubt answers, practice-quiz drafts) while Gemini
/// handles the heavy structured course generation. Same key as the GenPay
/// backend; for a public release this belongs behind a server, not in the app.
class NimService {
  NimService({String? apiKey, String? model})
      : _apiKey = (apiKey != null && apiKey.isNotEmpty)
            ? apiKey
            : const String.fromEnvironment('NVIDIA_API_KEY',
                defaultValue: _embeddedKey),
        _model = model ?? 'meta/llama-3.1-8b-instruct';

  static const _embeddedKey =
      'REDACTED_ROTATE_THIS_NVIDIA_KEY';
  static const _base = 'https://integrate.api.nvidia.com/v1';

  final String _apiKey;
  final String _model;

  bool get isLive => _apiKey.isNotEmpty;

  Future<String> chat(String prompt,
      {double temperature = 0.4, int maxTokens = 800}) async {
    final resp = await http.post(
      Uri.parse('$_base/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('NIM error ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return (data['choices'][0]['message']['content'] as String).trim();
  }
}
