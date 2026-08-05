import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_click_app/widgets/live_class_card.dart';

void main() {
  testWidgets('LiveClassCard renders within ProviderScope without throwing', (WidgetTester tester) async {
    // Build LiveClassCard wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: LiveClassCard(),
        ),
      ),
    ));

    // Initially while timetable provider loading/empty, it should build cleanly without throwing errors
    expect(tester.takeException(), isNull);
  });
}
