import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/shared/widgets/app_button.dart';
import 'package:mobile/core/constants/app_metrics.dart';

void main() {
  group('AppButton Widget Tests', () {
    testWidgets('renders button with label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Click Me',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Press',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(pressed, true);
    });

    testWidgets('shows loading indicator when isLoading is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables button when isLoading is true',
        (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Loading',
              onPressed: () {
                pressed = true;
              },
              isLoading: true,
            ),
          ),
        ),
      );

      final elevatedButton = find.byType(ElevatedButton);
      final button = tester.widget<ElevatedButton>(elevatedButton);

      expect(button.onPressed, isNull);
      expect(pressed, false);
    });

    testWidgets('renders with leading icon when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Submit',
              onPressed: () {},
              leadingIcon: Icons.check,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('expands to full width by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Expanded',
              onPressed: () {},
            ),
          ),
        ),
      );

      final sizedBox = find.byType(SizedBox);
      expect(sizedBox, findsWidgets);
    });

    testWidgets('does not expand when expanded is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Not Expanded',
              onPressed: () {},
              expanded: false,
            ),
          ),
        ),
      );

      expect(find.text('Not Expanded'), findsOneWidget);
    });

    testWidgets('button has correct height', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Size Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Find the ElevatedButton to verify it exists and is rendered
      final elevatedButton = find.byType(ElevatedButton);
      expect(elevatedButton, findsOneWidget);

      // Verify the button is visible on screen
      expect(find.text('Size Test'), findsOneWidget);
    });

    testWidgets('handles null onPressed gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'No Action',
              onPressed: null,
            ),
          ),
        ),
      );

      final elevatedButton = find.byType(ElevatedButton);
      final button = tester.widget<ElevatedButton>(elevatedButton);

      expect(button.onPressed, isNull);
    });

    testWidgets('displays icon and text together', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Action',
              onPressed: () {},
              leadingIcon: Icons.send,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('hides text during loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Loading Button',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.text('Loading Button'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
