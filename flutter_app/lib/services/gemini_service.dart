import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'course_parser.dart';

/// Doubt-solver backed by Gemini 2.0 Flash.
///
/// If no API key is configured, it returns a helpful grounded answer built
/// from the lesson content so the feature works end-to-end with zero setup.
/// Drop a key in via --dart-define=GEMINI_API_KEY=... to go live.
class GeminiService {
  GeminiService({String? apiKey})
      : _apiKey = (apiKey != null && apiKey.isNotEmpty)
            ? apiKey
            : const String.fromEnvironment('GEMINI_API_KEY',
                defaultValue: _embeddedKey);

  // No embedded key — AI now routes through the backend (server/ /ai/*). For a
  // direct on-device build, pass one via --dart-define=GEMINI_API_KEY=...
  static const _embeddedKey = '';

  final String _apiKey;

  bool get isLive => _apiKey.isNotEmpty;

  // gemini-2.0-flash has 0 free-tier quota on this project; 2.5-flash works.
  static const _model = 'gemini-2.5-flash';

  Future<String> answerDoubt({
    required String question,
    required Lesson lesson,
  }) async {
    if (!isLive) {
      return _mockAnswer(question, lesson);
    }

    final prompt = '''
You are a patient UPSC exam mentor answering a student's doubt.

Lesson: ${lesson.title}
Lesson content:
${lesson.script}

Key points:
${lesson.keyPoints.map((k) => '- $k').join('\n')}

Student's question: $question

Answer clearly in 200-300 words, grounded in the lesson content above.
Use simple language and a concrete example where helpful. If the question
goes beyond the lesson, use up-to-date information and suggest what to read next.
''';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        // Internet access: let the model ground answers with live Google Search.
        'tools': [
          {'google_search': {}}
        ],
      }),
    );

    if (resp.statusCode != 200) {
      return 'Sorry, the AI service returned an error (${resp.statusCode}). '
          'Here is what the lesson says instead:\n\n${_mockAnswer(question, lesson)}';
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    try {
      final text = data['candidates'][0]['content']['parts'][0]['text']
          as String;
      return text.trim();
    } catch (_) {
      return _mockAnswer(question, lesson);
    }
  }

  /// Builds an entire course from a learner's plain-language goal.
  ///
  /// e.g. "I'm studying for IAS, help me crack it" -> a structured course with
  /// modules, lessons, key points, and a quiz per lesson. The AI decides the
  /// structure. Falls back to a generated skeleton when no key is configured.
  Future<Course> generateCourse(String goal) async {
    if (!isLive) {
      await Future.delayed(const Duration(milliseconds: 1200));
      return mockCourse(goal);
    }

    final prompt = '''
You are an expert tutor and curriculum designer. A learner says:
"$goal"

Design a focused self-study course that gets them to their goal. YOU decide how
many modules and lessons are appropriate for this specific goal.

Return ONLY valid JSON (no markdown) in exactly this shape:
{
  "title": "short course title",
  "subtitle": "one motivating line",
  "description": "2-3 sentence overview",
  "category": "one of: Exam Prep, Skill, Language, Academic, Career, General",
  "tags": ["3-6 short tags"],
  "thumbnailEmoji": "a single emoji that fits",
  "modules": [
    {
      "title": "Module title",
      "description": "one line",
      "lessons": [
        {
          "title": "Lesson title",
          "summary": "2-3 sentence summary",
          "script": "250-450 word lesson body, conversational, with a concrete example",
          "keyPoints": ["6-10 concise bullet strings"],
          "durationMinutes": 10,
          "quiz": {
            "questions": [
              {"stem": "...", "options": ["a","b","c","d"], "correctIndex": 0, "explanation": "why"}
            ]
          }
        }
      ]
    }
  ]
}

Make 4-5 modules with 2-3 lessons each, covering the topic broadly. Each
"script" is a 250-400 word lesson with a concrete example. Every lesson MUST
have a quiz of 3 questions, each with exactly 4 options and one correct
answer. Be accurate and specific.''';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      // thinking off + token cap so generation stays well under the timeout.
      'generationConfig': {
        'responseMimeType': 'application/json',
        'thinkingConfig': {'thinkingBudget': 0},
        'maxOutputTokens': 24000,
      },
    });

    // Retry: model JSON can occasionally truncate or rate-limit; try a few
    // times before falling back to the offline skeleton.
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final resp = await http.post(uri,
            headers: {'Content-Type': 'application/json'}, body: body);
        if (resp.statusCode != 200) {
          await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
          continue;
        }
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        final j = jsonDecode(text) as Map<String, dynamic>;
        final course = courseFromAiJson(j, goal);
        if (course.totalLessons > 0) return course;
      } catch (_) {
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    return mockCourse(goal);
  }

  String _mockAnswer(String question, Lesson lesson) {
    final points = lesson.keyPoints.take(3).map((k) => '• $k').join('\n');
    return 'Here\'s a grounded answer based on "${lesson.title}".\n\n'
        'Your question: "$question"\n\n'
        'The most relevant points from this lesson are:\n$points\n\n'
        'Re-read the lesson summary above and notice how these connect to your '
        'question. (This is an offline answer — add a Gemini API key with '
        '--dart-define=GEMINI_API_KEY=... to get full AI explanations.)';
  }
}
