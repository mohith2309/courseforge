import '../models/models.dart';

/// Source of bundled content. The release build ships with NO demo/sample
/// courses — the library starts empty and real content comes from the AI
/// builder (your own courses) and the community marketplace.
class ContentRepository {
  List<Course>? _courses;
  Map<String, Creator>? _creators;

  Future<void> _ensureLoaded() async {
    if (_courses != null) return;
    _courses = const [];
    _creators = const {};
  }

  Future<List<Course>> getCourses() async {
    await _ensureLoaded();
    return _courses!;
  }

  Future<Course?> getCourse(String id) async {
    await _ensureLoaded();
    for (final c in _courses!) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<Creator?> getCreator(String id) async {
    await _ensureLoaded();
    return _creators?[id];
  }

  Future<List<String>> getCategories() async {
    await _ensureLoaded();
    final set = <String>{};
    for (final c in _courses!) {
      set.add(c.category);
    }
    return ['All', ...set];
  }

  Lesson? findLesson(Course course, String lessonId) {
    for (final l in course.allLessons) {
      if (l.id == lessonId) return l;
    }
    return null;
  }
}
