import 'package:flutter_test/flutter_test.dart';
import 'package:courseforge/services/course_parser.dart';

void main() {
  group('courseFromAiJson', () {
    test('happy path: fully populated course JSON', () {
      final json = {
        'title': 'Test Course',
        'subtitle': 'Test Subtitle',
        'description': 'A comprehensive test course',
        'category': 'Programming',
        'tags': ['dart', 'flutter'],
        'thumbnailEmoji': '🚀',
        'modules': [
          {
            'title': 'Module 1',
            'description': 'First module',
            'lessons': [
              {
                'title': 'Lesson 1',
                'summary': 'First lesson summary',
                'script': 'Lesson 1 script text',
                'keyPoints': ['Point 1', 'Point 2'],
                'durationMinutes': 15,
                'quiz': {
                  'questions': [
                    {
                      'stem': 'What is Flutter?',
                      'options': ['A bird', 'A UI toolkit', 'A fruit'],
                      'correctIndex': 1,
                      'explanation': 'It is a UI toolkit from Google'
                    }
                  ]
                }
              },
              {
                'title': 'Lesson 2',
                'durationMinutes': 20,
              }
            ]
          },
          {
            'title': 'Module 2',
            'lessons': [
              {
                'title': 'Lesson 3',
              }
            ]
          }
        ]
      };

      final course = courseFromAiJson(json, 'Fallback Goal');

      // Course-level properties
      expect(course.title, 'Test Course');
      expect(course.subtitle, 'Test Subtitle'); // From JSON, not goal
      expect(course.description, 'A comprehensive test course');
      expect(course.category, 'Programming');
      expect(course.tags, ['dart', 'flutter']);
      expect(course.thumbnailEmoji, '🚀');
      expect(course.creatorId, 'ai-tutor');
      expect(course.priceInr, 0);
      expect(course.aiGenerated, true);
      expect(course.modules.length, 2);

      // Module 1
      final module1 = course.modules[0];
      expect(module1.title, 'Module 1');
      expect(module1.description, 'First module');
      expect(module1.order, 1);
      expect(module1.lessons.length, 2);

      // Lesson 1
      final lesson1 = module1.lessons[0];
      expect(lesson1.title, 'Lesson 1');
      expect(lesson1.summary, 'First lesson summary');
      expect(lesson1.script, 'Lesson 1 script text');
      expect(lesson1.keyPoints, ['Point 1', 'Point 2']);
      expect(lesson1.durationMinutes, 15);
      expect(lesson1.order, 1);
      expect(lesson1.freePreview, true); // Module 1, Lesson 1

      // Quiz in Lesson 1
      expect(lesson1.quiz, isNotNull);
      expect(lesson1.quiz!.title, 'Check yourself');
      expect(lesson1.quiz!.passPercentage, 60);
      expect(lesson1.quiz!.questions.length, 1);

      final q1 = lesson1.quiz!.questions[0];
      expect(q1.stem, 'What is Flutter?');
      expect(q1.options, ['A bird', 'A UI toolkit', 'A fruit']);
      expect(q1.correctIndex, 1);
      expect(q1.explanation, 'It is a UI toolkit from Google');

      // Lesson 2
      final lesson2 = module1.lessons[1];
      expect(lesson2.title, 'Lesson 2');
      expect(lesson2.durationMinutes, 20);
      expect(lesson2.order, 2);
      expect(lesson2.freePreview, false); // Module 1, Lesson 2

      // Module 2
      final module2 = course.modules[1];
      expect(module2.title, 'Module 2');
      expect(module2.order, 2);
      expect(module2.lessons.length, 1);

      // Lesson 3
      final lesson3 = module2.lessons[0];
      expect(lesson3.title, 'Lesson 3');
      expect(lesson3.order, 1);
      expect(lesson3.freePreview, false); // Module 2, Lesson 1
    });

    test('fallback values for empty or missing top-level fields', () {
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

    test('handles missing or null modules', () {
      final json1 = {'modules': null};
      expect(courseFromAiJson(json1, 'Goal').modules, isEmpty);

      // The parser casts to List directly: (j['modules'] as List?)
      // We skip testing invalid types like 'not a list' because
      // the cast would throw, which we accept as behavior.
    });

    test('handles missing or null lessons', () {
      final json = {
        'modules': [
          {'title': 'Module with no lessons'},
          {'title': 'Module with null lessons', 'lessons': null},
        ]
      };

      final course = courseFromAiJson(json, 'Goal');
      expect(course.modules.length, 2);
      for (final m in course.modules) {
        expect(m.lessons, isEmpty);
      }
    });

    test('skips questions with fewer than 2 options', () {
      final json = {
        'modules': [
          {
            'lessons': [
              {
                'quiz': {
                  'questions': [
                    {
                      'stem': 'Valid question',
                      'options': ['Opt A', 'Opt B'],
                      'correctIndex': 0,
                    },
                    {
                      'stem': 'Invalid: only 1 option',
                      'options': ['Lonely option'],
                      'correctIndex': 0,
                    },
                    {
                      'stem': 'Invalid: 0 options',
                      'options': [],
                      'correctIndex': 0,
                    },
                    {
                      'stem': 'Invalid: null options',
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
      final quiz = course.modules[0].lessons[0].quiz;

      expect(quiz, isNotNull);
      expect(quiz!.questions.length, 1);
      expect(quiz.questions[0].stem, 'Valid question');
    });

    test('clamps correctIndex to valid range', () {
      final json = {
        'modules': [
          {
            'lessons': [
              {
                'quiz': {
                  'questions': [
                    {
                      'stem': 'Negative index',
                      'options': ['A', 'B', 'C'],
                      'correctIndex': -1,
                    },
                    {
                      'stem': 'Too large index',
                      'options': ['A', 'B', 'C'],
                      'correctIndex': 5,
                    },
                  ]
                }
              }
            ]
          }
        ]
      };

      final course = courseFromAiJson(json, 'Goal');
      final quiz = course.modules[0].lessons[0].quiz;

      expect(quiz, isNotNull);
      expect(quiz!.questions.length, 2);
      expect(quiz.questions[0].correctIndex, 0); // clamped -1 -> 0
      expect(quiz.questions[1].correctIndex, 2); // clamped 5 -> length - 1 (2)
    });

    test('missing or malformed quiz and questions are skipped', () {
      final json = {
        'modules': [
          {
            'lessons': [
              {
                'title': 'Lesson with bad quiz 1',
                'quiz': 'not a map'
              },
              {
                'title': 'Lesson with bad quiz 2',
                'quiz': {'questions': 'not a list'}
              },
            ]
          }
        ]
      };

      final course = courseFromAiJson(json, 'Goal');
      expect(course.modules[0].lessons[0].quiz, isNull);
      expect(course.modules[0].lessons[1].quiz, isNull);
    });
  });
}
