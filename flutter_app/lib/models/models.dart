// Core data models for CourseForge. Pure Dart, JSON-serializable so they map
// cleanly to local asset JSON now and to Firestore documents later.

class Course {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String category;
  final List<String> tags;
  final String creatorId;
  final int priceInr; // one-time price, ₹
  final String thumbnailEmoji; // placeholder visual until real thumbnails
  final double rating;
  final int reviewCount;
  final int enrollmentsCount;
  final bool featured;
  final bool aiGenerated; // true when built by the AI from a learner's goal
  final List<Module> modules;

  // Pre-calculated stats (O(1) access).
  final int totalLessons;
  final int totalQuestions;
  final int totalMinutes;
  final List<Lesson> allLessons;

  Course({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.tags,
    required this.creatorId,
    required this.priceInr,
    required this.thumbnailEmoji,
    required this.rating,
    required this.reviewCount,
    required this.enrollmentsCount,
    required this.featured,
    this.aiGenerated = false,
    required this.modules,
  })  : totalLessons = modules.fold(0, (sum, m) => sum + m.lessons.length),
        totalQuestions = modules.fold(
          0,
          (sum, m) =>
              sum +
              m.lessons.fold(0, (s, l) => s + (l.quiz?.questions.length ?? 0)),
        ),
        totalMinutes = modules.fold(
          0,
          (sum, m) => sum + m.lessons.fold(0, (s, l) => s + l.durationMinutes),
        ),
        allLessons = [for (final m in modules) ...m.lessons];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'category': category,
        'tags': tags,
        'creatorId': creatorId,
        'priceInr': priceInr,
        'thumbnailEmoji': thumbnailEmoji,
        'rating': rating,
        'reviewCount': reviewCount,
        'enrollmentsCount': enrollmentsCount,
        'featured': featured,
        'aiGenerated': aiGenerated,
        'modules': modules.map((m) => m.toJson()).toList(),
      };

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String? ?? '',
        description: j['description'] as String? ?? '',
        category: j['category'] as String? ?? 'General',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        creatorId: j['creatorId'] as String? ?? 'unknown',
        priceInr: (j['priceInr'] as num?)?.toInt() ?? 0,
        thumbnailEmoji: j['thumbnailEmoji'] as String? ?? '📘',
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
        enrollmentsCount: (j['enrollmentsCount'] as num?)?.toInt() ?? 0,
        featured: j['featured'] as bool? ?? false,
        aiGenerated: j['aiGenerated'] as bool? ?? false,
        modules: (j['modules'] as List? ?? const [])
            .map((m) => Module.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

class Module {
  final String id;
  final String title;
  final String description;
  final int order;
  final List<Lesson> lessons;

  const Module({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.lessons,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'order': order,
        'lessons': lessons.map((l) => l.toJson()).toList(),
      };

  factory Module.fromJson(Map<String, dynamic> j) => Module(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        order: (j['order'] as num?)?.toInt() ?? 0,
        lessons: (j['lessons'] as List? ?? const [])
            .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
            .toList(),
      );
}

class Lesson {
  final String id;
  final String moduleId;
  final String title;
  final String summary;
  final String script; // long-form lesson body (Markdown-ish plain text)
  final List<String> keyPoints;
  final int durationMinutes;
  final int order;
  final bool freePreview;
  final Quiz? quiz;

  const Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.summary,
    required this.script,
    required this.keyPoints,
    required this.durationMinutes,
    required this.order,
    required this.freePreview,
    required this.quiz,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'moduleId': moduleId,
        'title': title,
        'summary': summary,
        'script': script,
        'keyPoints': keyPoints,
        'durationMinutes': durationMinutes,
        'order': order,
        'freePreview': freePreview,
        'quiz': quiz?.toJson(),
      };

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String,
        moduleId: j['moduleId'] as String? ?? '',
        title: j['title'] as String,
        summary: j['summary'] as String? ?? '',
        script: j['script'] as String? ?? '',
        keyPoints: (j['keyPoints'] as List?)?.cast<String>() ?? const [],
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 10,
        order: (j['order'] as num?)?.toInt() ?? 0,
        freePreview: j['freePreview'] as bool? ?? false,
        quiz: (j['quiz'] is Map)
            ? Quiz.fromJson(Map<String, dynamic>.from(j['quiz'] as Map))
            : (j['quiz'] is List)
                ? Quiz.fromJson({'questions': j['quiz']})
                : null,
      );
}

class Quiz {
  final String id;
  final String title;
  final int passPercentage;
  final List<Question> questions;

  const Quiz({
    required this.id,
    required this.title,
    required this.passPercentage,
    required this.questions,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'passPercentage': passPercentage,
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  factory Quiz.fromJson(Map<String, dynamic> j) {
    // AI-generated quizzes often arrive as just {questions:[...]} (no id/title)
    // or even as a bare list — parse leniently and never throw.
    final rawList = j['questions'] ?? j['items'] ?? const [];
    final list = rawList is List ? rawList : const [];
    return Quiz(
      id: j['id'] as String? ?? 'quiz_${DateTime.now().microsecondsSinceEpoch}',
      title: j['title'] as String? ?? 'Quiz',
      passPercentage: (j['passPercentage'] as num?)?.toInt() ?? 60,
      questions: list
          .whereType<Map>()
          .map((q) => Question.tryParse(Map<String, dynamic>.from(q)))
          .whereType<Question>()
          .toList(),
    );
  }
}

class Question {
  final String stem;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const Question({
    required this.stem,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'stem': stem,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
      };

  factory Question.fromJson(Map<String, dynamic> j) =>
      tryParse(j) ??
      const Question(
          stem: '', options: ['', ''], correctIndex: 0, explanation: '');

  /// Tolerant parser: accepts field-name variants (stem/question, correctIndex/
  /// answer), string or letter answers, and skips genuinely broken questions
  /// (returns null) so one bad item never crashes the whole course parse.
  static Question? tryParse(Map<String, dynamic> j) {
    final stem = (j['stem'] ?? j['question'] ?? j['q'] ?? '').toString().trim();
    final opts = (j['options'] ?? j['choices'] ?? const []) is List
        ? ((j['options'] ?? j['choices']) as List)
            .map((e) => e.toString())
            .toList()
        : <String>[];
    if (stem.isEmpty || opts.length < 2) return null;

    final raw = j['correctIndex'] ?? j['answer'] ?? j['correct'] ?? 0;
    var ci = 0;
    if (raw is num) {
      ci = raw.toInt();
    } else if (raw is String) {
      ci = int.tryParse(raw.trim()) ??
          // "B" → index 1, or match the full answer text
          (raw.trim().length == 1
              ? raw.trim().toUpperCase().codeUnitAt(0) - 65
              : opts.indexWhere(
                  (o) => o.toLowerCase() == raw.trim().toLowerCase()));
    }
    if (ci < 0 || ci >= opts.length) ci = 0;

    return Question(
      stem: stem,
      options: opts,
      correctIndex: ci,
      explanation: (j['explanation'] ?? j['rationale'] ?? '').toString(),
    );
  }
}

class Creator {
  final String id;
  final String name;
  final String bio;
  final String avatarEmoji;

  const Creator({
    required this.id,
    required this.name,
    required this.bio,
    required this.avatarEmoji,
  });

  factory Creator.fromJson(Map<String, dynamic> j) => Creator(
        id: j['id'] as String,
        name: j['name'] as String,
        bio: j['bio'] as String? ?? '',
        avatarEmoji: j['avatarEmoji'] as String? ?? '🧑‍🏫',
      );
}
