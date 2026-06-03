import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';

/// Loads courses and creators from bundled JSON assets.
///
/// This is the offline-first data source. When a backend is added later,
/// swap this single class for a Firestore-backed implementation behind the
/// same method signatures — nothing else in the app needs to change.
class ContentRepository {
  List<Course>? _courses;
  Map<String, Creator>? _creators;

  Future<void> _ensureLoaded() async {
    if (_courses != null) return;

    final iasRaw = await rootBundle.loadString('assets/data/ias_course.json');
    final catalogRaw =
        await rootBundle.loadString('assets/data/catalog.json');

    final ias = Course.fromJson(jsonDecode(iasRaw) as Map<String, dynamic>);
    final catalog = jsonDecode(catalogRaw) as Map<String, dynamic>;

    final extraCourses = (catalog['courses'] as List)
        .map((c) => Course.fromJson(c as Map<String, dynamic>))
        .toList();

    final creators = <String, Creator>{};
    for (final c in (catalog['creators'] as List)) {
      final creator = Creator.fromJson(c as Map<String, dynamic>);
      creators[creator.id] = creator;
    }

    // IAS course is the flagship — keep it first.
    _courses = [ias, ...extraCourses];
    _creators = creators;
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
