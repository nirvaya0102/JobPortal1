// This is a basic Flutter widget test for the Job Portal app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app built successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
