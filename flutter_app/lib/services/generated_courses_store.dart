import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Persists AI-generated courses locally so they survive restarts.
/// Same JSON shape as the bundled assets — a future Firestore sync is a drop-in.
class GeneratedCoursesStore {
  static const _key = 'courseforge_generated_courses_v1';

  Future<List<Course>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((c) => Course.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<Course> courses) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(courses.map((c) => c.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> add(Course course) async {
    final current = await load();
    current.removeWhere((c) => c.id == course.id);
    await _saveAll([course, ...current]);
  }

  Future<void> remove(String id) async {
    final current = await load();
    current.removeWhere((c) => c.id == id);
    await _saveAll(current);
  }
}
