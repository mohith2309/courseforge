import '../models/models.dart';

String _uid(String prefix) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

/// Converts the AI's loose course JSON (from Gemini directly or via the
/// backend) into a fully-formed [Course] with stable ids. Shared so the
/// on-device and server paths build identical objects.
Course courseFromAiJson(Map<String, dynamic> j, String goal) {
  final courseId = _uid('ai');
  int mOrder = 0;
  final modules = <Module>[];
  for (final m in (j['modules'] as List? ?? const [])) {
    mOrder++;
    final moduleId = _uid('m');
    int lOrder = 0;
    final lessons = <Lesson>[];
    for (final l in ((m as Map)['lessons'] as List? ?? const [])) {
      lOrder++;
      final lm = l as Map<String, dynamic>;
      final qs = <Question>[];
      final quizJson = lm['quiz'];
      if (quizJson is Map && quizJson['questions'] is List) {
        for (final q in (quizJson['questions'] as List)) {
          final qm = q as Map<String, dynamic>;
          final opts = (qm['options'] as List? ?? const [])
              .map((e) => e.toString())
              .toList();
          if (opts.length < 2) continue;
          qs.add(Question(
            stem: qm['stem']?.toString() ?? '',
            options: opts,
            correctIndex: ((qm['correctIndex'] as num?)?.toInt() ?? 0)
                .clamp(0, opts.length - 1),
            explanation: qm['explanation']?.toString() ?? '',
          ));
        }
      }
      lessons.add(Lesson(
        id: _uid('l'),
        moduleId: moduleId,
        title: lm['title']?.toString() ?? 'Lesson $lOrder',
        summary: lm['summary']?.toString() ?? '',
        script: lm['script']?.toString() ?? '',
        keyPoints: (lm['keyPoints'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        durationMinutes: (lm['durationMinutes'] as num?)?.toInt() ?? 10,
        order: lOrder,
        freePreview: mOrder == 1 && lOrder == 1,
        quiz: qs.isEmpty
            ? null
            : Quiz(
                id: _uid('q'),
                title: 'Check yourself',
                passPercentage: 60,
                questions: qs,
              ),
      ));
    }
    modules.add(Module(
      id: moduleId,
      title: (m['title']?.toString()) ?? 'Module $mOrder',
      description: m['description']?.toString() ?? '',
      order: mOrder,
      lessons: lessons,
    ));
  }

  return Course(
    id: courseId,
    title: j['title']?.toString() ?? 'Your course',
    subtitle: j['subtitle']?.toString() ?? goal,
    description: j['description']?.toString() ?? '',
    category: j['category']?.toString() ?? 'General',
    tags: (j['tags'] as List? ?? const []).map((e) => e.toString()).toList(),
    creatorId: 'ai-tutor',
    priceInr: 0,
    thumbnailEmoji: j['thumbnailEmoji']?.toString() ?? '🎯',
    rating: 0,
    reviewCount: 0,
    enrollmentsCount: 0,
    featured: false,
    aiGenerated: true,
    modules: modules,
  );
}

/// Offline skeleton so the build flow works with no AI at all.
Course mockCourse(String goal) {
  final topic = goal.trim().isEmpty ? 'your goal' : goal.trim();
  Lesson lesson(String mId, int order, String title, String summary,
      List<String> kp) {
    return Lesson(
      id: _uid('l'),
      moduleId: mId,
      title: title,
      summary: summary,
      script: '$summary\n\n[Offline draft — connect AI to generate a full, '
          'tailored lesson for "$topic".]\n\nStart with the core idea, then a '
          'concrete example, then why it matters for reaching your goal.',
      keyPoints: kp,
      durationMinutes: 10,
      order: order,
      freePreview: order == 1,
      quiz: Quiz(
        id: _uid('q'),
        title: 'Check yourself',
        passPercentage: 60,
        questions: [
          Question(
            stem: 'Placeholder question about "$title". Regenerate with AI '
                'connected for real questions.',
            options: const ['Option A', 'Option B', 'Option C', 'Option D'],
            correctIndex: 0,
            explanation: 'Explanation appears here once AI-generated.',
          ),
        ],
      ),
    );
  }

  Module module(int order, String title, List<String> lessonTitles) {
    final id = _uid('m');
    return Module(
      id: id,
      title: title,
      description: '',
      order: order,
      lessons: [
        for (int i = 0; i < lessonTitles.length; i++)
          lesson(id, i + 1, lessonTitles[i],
              'An overview of ${lessonTitles[i].toLowerCase()}.', [
            'Key idea of ${lessonTitles[i]}',
            'A concrete example',
            'Why it matters'
          ]),
      ],
    );
  }

  return Course(
    id: _uid('ai'),
    title: 'Study plan: $topic',
    subtitle: 'Auto-built for your goal',
    description: 'A structured starting plan generated for "$topic". Connect AI '
        'to generate full, tailored lessons and quizzes.',
    category: 'General',
    tags: const ['ai-generated', 'study plan'],
    creatorId: 'ai-tutor',
    priceInr: 0,
    thumbnailEmoji: '🎯',
    rating: 0,
    reviewCount: 0,
    enrollmentsCount: 0,
    featured: false,
    aiGenerated: true,
    modules: [
      module(1, 'Foundations', ['Getting oriented', 'Core concepts']),
      module(2, 'Building skills', ['Key techniques', 'Practice approach']),
      module(3, 'Putting it together', ['Common pitfalls', 'Final review']),
    ],
  );
}
