import 'dart:convert';
import '../models/models.dart';
import 'api_client.dart';
import 'gemini_service.dart';
import 'nim_service.dart';

/// Routes each AI task to the provider that does it best:
///   • Course generation  -> Gemini 2.5 Flash (strong structured JSON)
///   • Doubt Q&A           -> Gemini 2.5 Flash + Google Search (live internet)
///   • Practice quizzes    -> NVIDIA NIM Llama 3.1 (fast, cheap drafts)
///
/// If a backend [ApiClient] is configured (BACKEND_URL set), all three go
/// through the server instead — keeping the API keys off the device. Each
/// path degrades gracefully if its provider is unavailable.
class AiService {
  AiService({GeminiService? gemini, NimService? nim, ApiClient? api})
      : _gemini = gemini ?? GeminiService(),
        _nim = nim ?? NimService(),
        _api = api ?? ApiClient();

  final GeminiService _gemini;
  final NimService _nim;
  final ApiClient _api;

  bool get usesBackend => _api.isConfigured;
  bool get isLive => usesBackend || _gemini.isLive || _nim.isLive;
  bool get geminiLive => _gemini.isLive;
  bool get nimLive => _nim.isLive;

  Future<Course> generateCourse(String goal) =>
      usesBackend ? _api.generateCourse(goal) : _gemini.generateCourse(goal);

  Future<String> answerDoubt({
    required String question,
    required Lesson lesson,
  }) async {
    if (usesBackend) {
      try {
        return await _api.answerDoubt(question: question, lesson: lesson);
      } catch (_) {/* fall through to on-device */}
    }
    try {
      return await _gemini.answerDoubt(question: question, lesson: lesson);
    } catch (_) {
      // Fall back to the fast model if Gemini is unreachable.
      if (_nim.isLive) {
        return _nim.chat(
          'You are a helpful tutor. Lesson: "${lesson.title}".\n'
          '${lesson.summary}\n\nQuestion: $question\n\n'
          'Answer clearly in ~200 words.',
        );
      }
      rethrow;
    }
  }

  /// Generates fresh practice questions for a lesson — used for the adaptive
  /// "Practice more" feature so learners get new questions each time. Routed to
  /// NIM (fast); falls back to recycling the lesson's own quiz on any failure.
  Future<List<Question>> generatePracticeQuiz({
    required Lesson lesson,
    int count = 5,
    String difficulty = 'medium',
  }) async {
    if (usesBackend) {
      try {
        final qs = await _api.practice(
            lesson: lesson, count: count, difficulty: difficulty);
        if (qs.isNotEmpty) return qs;
      } catch (_) {/* fall through */}
    }
    if (_nim.isLive) {
      try {
        final raw = await _nim.chat(
          'Create $count $difficulty multiple-choice questions to test this '
          'lesson. Return ONLY a JSON array, no prose:\n'
          '[{"stem":"...","options":["a","b","c","d"],"correctIndex":0,"explanation":"..."}]\n\n'
          'Lesson: ${lesson.title}\n${lesson.script}',
          maxTokens: 1100,
        );
        final parsed = _parseQuestions(raw);
        if (parsed.isNotEmpty) return parsed;
      } catch (_) {/* fall through */}
    }
    // Fallback: reuse existing questions (shuffled) so the feature still works.
    final existing = lesson.quiz?.questions ?? const [];
    return List<Question>.from(existing)..shuffle();
  }

  List<Question> _parseQuestions(String raw) {
    // NIM sometimes wraps JSON in prose/markdown — extract the array.
    final start = raw.indexOf('[');
    final end = raw.lastIndexOf(']');
    if (start < 0 || end <= start) return const [];
    try {
      final list = jsonDecode(raw.substring(start, end + 1)) as List;
      final out = <Question>[];
      for (final q in list) {
        final m = q as Map<String, dynamic>;
        final opts =
            (m['options'] as List? ?? const []).map((e) => e.toString()).toList();
        if (opts.length < 2) continue;
        out.add(Question(
          stem: m['stem']?.toString() ?? '',
          options: opts,
          correctIndex:
              ((m['correctIndex'] as num?)?.toInt() ?? 0).clamp(0, opts.length - 1),
          explanation: m['explanation']?.toString() ?? '',
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}
