import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:courseforge/main.dart';

void main() {
  testWidgets('App boots to the AI builder home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CourseForgeApp()));
    await tester.pump();

    // The hero prompt and the Build nav tab should be present.
    expect(find.text('What do you want to learn?'), findsOneWidget);
    expect(find.text('Build'), findsWidgets);
  });
}
