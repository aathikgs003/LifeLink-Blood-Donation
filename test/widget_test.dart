import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelink_blood/main.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: LifeLinkApp()));

    // Verify it builds (splash screen should be initial)
    expect(find.byType(LifeLinkApp), findsOneWidget);

    // Let splash/intro animation timers finish before the test disposes the app.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
