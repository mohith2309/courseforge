import 'package:flutter_test/flutter_test.dart';
import 'package:courseforge/services/course_parser.dart';
import 'package:courseforge/models/models.dart';

void main() {
  group('courseFromAiJson', () {
    test('parses a fully populated JSON correctly', () {
      final json = {
        'title': 'Test Course',
        'subtitle': 'A test subtitle',
        'description': 'A test description',
        'category': 'Testing',
        'tags': ['test', 'flutter'],
        'thumbnailEmoji': '🚀',
        'modules': [
          {
            'title': 'Module 1',
            'description': 'First module',
            'lessons': [
              {
                'title': 'Lesson 1',
                'summary': 'First lesson',
                'script': 'Hello world',
                'keyPoints': ['point 1', 'point 2'],
                'durationMinutes': 15,
                'quiz': {
                  'questions': [
                    {
                      'stem': 'What is 1+1?',
                      'options': ['1', '2', '3'],
                      'correctIndex': 1,
                      'explanation': 'Because math'
                    }
                  ]
                }
              }
            ]
          }
        ]
      };

      final course = courseFromAiJson(json, 'Goal');

      expect(course.title, 'Test Course');
      expect(course.subtitle, 'A test subtitle');
      expect(course.description, 'A test description');
      expect(course.category, 'Testing');
      expect(course.tags, ['test', 'flutter']);
      expect(course.thumbnailEmoji, '🚀');
      expect(course.aiGenerated, true);
      expect(course.modules.length, 1);

      final module = course.modules.first;
      expect(module.title, 'Module 1');
      expect(module.description, 'First module');
      expect(module.order, 1);
      expect(module.lessons.length, 1);

      final lesson = module.lessons.first;
      expect(lesson.title, 'Lesson 1');
      expect(lesson.summary, 'First lesson');
      expect(lesson.script, 'Hello world');
      expect(lesson.keyPoints, ['point 1', 'point 2']);
      expect(lesson.durationMinutes, 15);
      expect(lesson.order, 1);
      expect(lesson.freePreview, true);

      expect(lesson.quiz, isNotNull);
      expect(lesson.quiz!.questions.length, 1);

      final question = lesson.quiz!.questions.first;
      expect(question.stem, 'What is 1+1?');
      expect(question.options, ['1', '2', '3']);
      expect(question.correctIndex, 1);
      expect(question.explanation, 'Because math');
    });

    test('handles missing optional fields by using defaults or goal', () {
      final json = <String, dynamic>{};
      final course = courseFromAiJson(json, 'My Goal');

      expect(course.title, 'Your course');
      expect(course.subtitle, 'My Goal');
      expect(course.description, '');
      expect(course.category, 'General');
      expect(course.tags, isEmpty);
      expect(course.thumbnailEmoji, '🎯');
      expect(course.modules, isEmpty);
    });

    test('handles missing or empty modules list gracefully', () {
      final course1 = courseFromAiJson({'modules': null}, 'Goal');
      expect(course1.modules, isEmpty);

      final course2 = courseFromAiJson({'modules': []}, 'Goal');
      expect(course2.modules, isEmpty);
    });

    test('handles missing or empty lessons list gracefully', () {
      final json = {
        'modules': [
          {'title': 'M1'}
        ]
      };
      final course = courseFromAiJson(json, 'Goal');
      expect(course.modules.length, 1);
      expect(course.modules.first.lessons, isEmpty);
    });

    test('handles missing quiz or empty questions gracefully', () {
      final json = {
        'modules': [
          {
            'lessons': [
              {'title': 'L1'},
              {'title': 'L2', 'quiz': {}},
              {'title': 'L3', 'quiz': {'questions': []}},
            ]
          }
        ]
      };

      final course = courseFromAiJson(json, 'Goal');
      final lessons = course.modules.first.lessons;

      expect(lessons[0].quiz, isNull);
      expect(lessons[1].quiz, isNull);
      expect(lessons[2].quiz, isNull);
    });

    test('skips questions with fewer than 2 options', () {
      final json = {
        'modules': [
          {
            'lessons': [
              {
                'title': 'L1',
                'quiz': {
                  'questions': [
                    {
                      'stem': 'Invalid question',
                      'options': ['only one'],
                      'correctIndex': 0,
                    },
                    {
                      'stem': 'Valid question',
                      'options': ['A', 'B'],
                      'correctIndex': 0,
                    }
                  ]
                }
              }
            ]
          }
        ]
      };

      final course = courseFromAiJson(json, 'Goal');
      final lesson = course.modules.first.lessons.first;

      expect(lesson.quiz, isNotNull);
      expect(lesson.quiz!.questions.length, 1);
      expect(lesson.quiz!.questions.first.stem, 'Valid question');
    });

    test('handles invalid quiz structure gracefully', () {
       final json = {
        'modules': [
          {
            'lessons': [
              {
                'title': 'L1',
                'quiz': 'this is not a map'
              }
            ]
          }
        ]
      };

      final course = courseFromAiJson(json, 'Goal');
      final lesson = course.modules.first.lessons.first;
      expect(lesson.quiz, isNull);
    });
  });
}
