import 'package:flutter_test/flutter_test.dart';

import 'package:scibowlquizzer/main.dart';

void main() {
  testWidgets('loads the science bowl practice screen', (tester) async {
    await tester.pumpWidget(const SciBowlQuizzerApp());
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    await tester.pump();

    expect(find.text('Science Bowl Practice'), findsOneWidget);
    expect(find.textContaining('Life Science'), findsWidgets);
    expect(find.textContaining('organelle'), findsOneWidget);
    expect(find.text('Skip / next'), findsOneWidget);
  });
}
