// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:procurax_frontend/main.dart';

void main() {
  testWidgets('Get Started screen shows title and button', (
    WidgetTester tester,
  ) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // No need to wait for network Future; title is built synchronously.
    expect(find.text('ICC ProcuraX'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
