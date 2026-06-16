import 'package:tap_tooltip_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the example page', (WidgetTester tester) async {
    await tester.pumpWidget(const TapTooltipDemoApp());

    expect(find.text('ClickTooltip'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline_rounded), findsWidgets);
  });
}
