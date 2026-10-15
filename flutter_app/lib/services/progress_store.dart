import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// All per-student state, persisted locally (offline-first).
///
/// Shape mirrors the planned Firestore `student_progress` + `enrollments`
/// collections so a future sync layer is a drop-in.
class ProgressState {
  final Set<String> enrolledCourseIds;
  final Set<String> completedLessonIds;
  final Map<String, int> quizScores; // quizId -> best % score
  final Set<String> bookmarkedLessonIds;
  final Map<String, String> notes; // lessonId -> note text
  final int timeSpentMinutes;
  final Set<String> activeDays; // ISO yyyy-MM-dd, for streaks

  // Gamification.
  final int xp; // lifetime XP
  final int dailyXp; // XP earned on dailyXpDay
  final String dailyXpDay; // ISO day dailyXp belongs to
  final int heartsUsedToday; // wrong-answer hearts spent on heartsDay
  final String heartsDay; // ISO day heartsUsedToday belongs to

  const ProgressState({
    this.enrolledCourseIds = const {},
    this.completedLessonIds = const {},
    this.quizScores = const {},
    this.bookmarkedLessonIds = const {},
    this.notes = const {},
    this.timeSpentMinutes = 0,
    this.activeDays = const {},
    this.xp = 0,
    this.dailyXp = 0,
    this.dailyXpDay = '',
    this.heartsUsedToday = 0,
    this.heartsDay = '',
  });

  ProgressState copyWith({
    Set<String>? enrolledCourseIds,
    Set<String>? completedLessonIds,
    Map<String, int>? quizScores,
    Set<String>? bookmarkedLessonIds,
    Map<String, String>? notes,
    int? timeSpentMinutes,
    Set<String>? activeDays,
    int? xp,
    int? dailyXp,
    String? dailyXpDay,
    int? heartsUsedToday,
    String? heartsDay,
  }) {
    return ProgressState(
      enrolledCourseIds: enrolledCourseIds ?? this.enrolledCourseIds,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      quizScores: quizScores ?? this.quizScores,
      bookmarkedLessonIds: bookmarkedLessonIds ?? this.bookmarkedLessonIds,
      notes: notes ?? this.notes,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      activeDays: activeDays ?? this.activeDays,
      xp: xp ?? this.xp,
      dailyXp: dailyXp ?? this.dailyXp,
      dailyXpDay: dailyXpDay ?? this.dailyXpDay,
      heartsUsedToday: heartsUsedToday ?? this.heartsUsedToday,
      heartsDay: heartsDay ?? this.heartsDay,
    );
  }

  // ---- Gamification math -------------------------------------------------
  static const int xpPerLevel = 100;
  static const int dailyGoal = 50;
  static const int maxHearts = 5;

  int get level => (xp ~/ xpPerLevel) + 1;
  int get xpIntoLevel => xp % xpPerLevel;
  double get levelProgress => xpIntoLevel / xpPerLevel;

  /// XP counted toward today's goal (0 if the stored day isn't today).
  int get todayXp => dailyXpDay == fmtToday() ? dailyXp : 0;
  double get dailyGoalProgress => (todayXp / dailyGoal).clamp(0, 1).toDouble();

  /// Hearts left today (refills to max each new day).
  int get heartsRemaining =>
      heartsDay == fmtToday() ? (maxHearts - heartsUsedToday).clamp(0, maxHearts) : maxHearts;

  /// Consecutive-day streak ending today (or yesterday).
  /// Optimized: Uses the [activeDays] Set directly for O(1) membership checks.
  int get streak {
    if (activeDays.isEmpty) return 0;
    final today = DateTime.now();
    int count = 0;
    // Allow the streak to count if the last active day was today or yesterday.
    var cursor = activeDays.contains(_fmt(today))
        ? today
        : today.subtract(const Duration(days: 1));
    if (!activeDays.contains(_fmt(cursor))) return 0;
    while (activeDays.contains(_fmt(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  static String fmtToday() => _fmt(DateTime.now());

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'enrolled': enrolledCourseIds.toList(),
        'completed': completedLessonIds.toList(),
        'scores': quizScores,
        'bookmarks': bookmarkedLessonIds.toList(),
        'notes': notes,
        'time': timeSpentMinutes,
        'days': activeDays.toList(),
        'xp': xp,
        'dailyXp': dailyXp,
        'dailyXpDay': dailyXpDay,
        'heartsUsedToday': heartsUsedToday,
        'heartsDay': heartsDay,
      };

  factory ProgressState.fromJson(Map<String, dynamic> j) => ProgressState(
        enrolledCourseIds:
            (j['enrolled'] as List? ?? const []).cast<String>().toSet(),
        completedLessonIds:
            (j['completed'] as List? ?? const []).cast<String>().toSet(),
        quizScores: (j['scores'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as num).toInt()),
            ) ??
            const {},
        bookmarkedLessonIds:
            (j['bookmarks'] as List? ?? const []).cast<String>().toSet(),
        notes: (j['notes'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as String),
            ) ??
            const {},
        timeSpentMinutes: (j['time'] as num?)?.toInt() ?? 0,
        activeDays: (j['days'] as List? ?? const []).cast<String>().toSet(),
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        dailyXp: (j['dailyXp'] as num?)?.toInt() ?? 0,
        dailyXpDay: j['dailyXpDay'] as String? ?? '',
        heartsUsedToday: (j['heartsUsedToday'] as num?)?.toInt() ?? 0,
        heartsDay: j['heartsDay'] as String? ?? '',
      );
}

class ProgressStore {
  static const _key = 'courseforge_progress_v1';

  Future<ProgressState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const ProgressState();
    try {
      return ProgressState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ProgressState();
    }
  }

  Future<void> save(ProgressState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}
