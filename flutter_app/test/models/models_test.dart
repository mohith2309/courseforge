import 'package:flutter_test/flutter_test.dart';
import 'package:courseforge/models/models.dart';

void main() {
  group('Course Model Tests', () {
    test('totalMinutes should be 0 when there are no modules', () {
      final course = Course(
        id: 'c1',
        title: 'Test Course',
        subtitle: '',
        description: '',
        category: '',
        tags: [],
        creatorId: 'u1',
        priceInr: 0,
        thumbnailEmoji: '',
        rating: 0,
        reviewCount: 0,
        enrollmentsCount: 0,
        featured: false,
        modules: [],
      );

      expect(course.totalMinutes, 0);
    });

    test('totalMinutes should be 0 when modules have no lessons', () {
      final course = Course(
        id: 'c1',
        title: 'Test Course',
        subtitle: '',
        description: '',
        category: '',
        tags: [],
        creatorId: 'u1',
        priceInr: 0,
        thumbnailEmoji: '',
        rating: 0,
        reviewCount: 0,
        enrollmentsCount: 0,
        featured: false,
        modules: [
          Module(
            id: 'm1',
            title: 'Module 1',
            description: '',
            order: 1,
            lessons: [],
          ),
          Module(
            id: 'm2',
            title: 'Module 2',
            description: '',
            order: 2,
            lessons: [],
          ),
        ],
      );

      expect(course.totalMinutes, 0);
    });

    test('totalMinutes should return sum of durationMinutes across all lessons in all modules', () {
      final course = Course(
        id: 'c1',
        title: 'Test Course',
        subtitle: '',
        description: '',
        category: '',
        tags: [],
        creatorId: 'u1',
        priceInr: 0,
        thumbnailEmoji: '',
        rating: 0,
        reviewCount: 0,
        enrollmentsCount: 0,
        featured: false,
        modules: [
          Module(
            id: 'm1',
            title: 'Module 1',
            description: '',
            order: 1,
            lessons: [
              Lesson(
                id: 'l1',
                moduleId: 'm1',
                title: 'Lesson 1',
                summary: '',
                script: '',
                keyPoints: [],
                durationMinutes: 10,
                order: 1,
                freePreview: false,
                quiz: null,
              ),
              Lesson(
                id: 'l2',
                moduleId: 'm1',
                title: 'Lesson 2',
                summary: '',
                script: '',
                keyPoints: [],
                durationMinutes: 15,
                order: 2,
                freePreview: false,
                quiz: null,
              ),
            ],
          ),
          Module(
            id: 'm2',
            title: 'Module 2',
            description: '',
            order: 2,
            lessons: [
              Lesson(
                id: 'l3',
                moduleId: 'm2',
                title: 'Lesson 3',
                summary: '',
                script: '',
                keyPoints: [],
                durationMinutes: 20,
                order: 1,
                freePreview: false,
                quiz: null,
              ),
            ],
          ),
        ],
      );

      expect(course.totalMinutes, 45); // 10 + 15 + 20
    });
  });
}
