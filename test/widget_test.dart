// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:lifelink/app/lifelink_app.dart';

void main() {
  testWidgets('LifeLink sign-in screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LifeLinkApp());

    expect(find.text('Welcome to LifeLink'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
