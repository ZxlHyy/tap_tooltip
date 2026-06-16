import 'package:tap_tooltip_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('example app shows a tooltip', (WidgetTester tester) async {
    await tester.pumpWidget(const TooltipExampleApp());

    await tester.tap(find.byIcon(Icons.help_outline_rounded).first);
    await tester.pumpAndSettle();

    expect(
      find.text('The bubble is placed on the right side.'),
      findsOneWidget,
    );
  });
}
