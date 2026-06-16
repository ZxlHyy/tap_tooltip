import 'package:tap_tooltip/tap_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows tooltip on tap and hides after outside tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: TapTooltip(
              tooltip: 'Tooltip message',
              child: Text('Tap me'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tooltip message'), findsNothing);

    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();

    expect(find.text('Tooltip message'), findsOneWidget);

    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    expect(find.text('Tooltip message'), findsNothing);
  });

  testWidgets('can be controlled by TapTooltipController', (
    WidgetTester tester,
  ) async {
    final controller = TapTooltipController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TapTooltip(
              controller: controller,
              tooltip: 'Controlled tooltip',
              child: const Text('Anchor'),
            ),
          ),
        ),
      ),
    );

    controller.show();
    await tester.pumpAndSettle();

    expect(controller.isShowing, isTrue);
    expect(find.text('Controlled tooltip'), findsOneWidget);

    controller.hide();
    await tester.pumpAndSettle();

    expect(controller.isShowing, isFalse);
    expect(find.text('Controlled tooltip'), findsNothing);
  });

  testWidgets('uses direction as tooltip popup side', (
    WidgetTester tester,
  ) async {
    final cases = <TooltipDirection, bool Function(Rect tooltip, Rect anchor)>{
      TooltipDirection.top: (tooltip, anchor) => tooltip.bottom <= anchor.top,
      TooltipDirection.bottom: (tooltip, anchor) =>
          tooltip.top >= anchor.bottom,
      TooltipDirection.left: (tooltip, anchor) => tooltip.right <= anchor.left,
      TooltipDirection.right: (tooltip, anchor) => tooltip.left >= anchor.right,
    };

    for (final entry in cases.entries) {
      final controller = TapTooltipController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 300,
                  top: 300,
                  child: TapTooltip(
                    controller: controller,
                    direction: entry.key,
                    autoSafeDetection: false,
                    tooltipBuilder: (_) {
                      return const SizedBox(
                        key: _tooltipBoxKey,
                        width: 100,
                        height: 40,
                        child: Text('Directional tooltip'),
                      );
                    },
                    child: const SizedBox(
                      key: _anchorKey,
                      width: 10,
                      height: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      controller.show();
      await tester.pumpAndSettle();

      final tooltip = tester.getRect(find.byKey(_tooltipBoxKey));
      final anchor = tester.getRect(find.byKey(_anchorKey));
      expect(entry.value(tooltip, anchor), isTrue);
    }
  });

  testWidgets('limits left and right tooltip width to available side width', (
    WidgetTester tester,
  ) async {
    final leftMaxWidth = await _layoutTooltipAndReadConstraints(
      tester,
      direction: TooltipDirection.left,
      anchorLeft: 80,
      anchorTop: 300,
    );
    expect(leftMaxWidth.width, lessThanOrEqualTo(70));

    final rightMaxWidth = await _layoutTooltipAndReadConstraints(
      tester,
      direction: TooltipDirection.right,
      anchorLeft: 710,
      anchorTop: 300,
    );
    expect(rightMaxWidth.width, lessThanOrEqualTo(70));
  });

  testWidgets('limits top and bottom tooltip height to available side height', (
    WidgetTester tester,
  ) async {
    final topMaxHeight = await _layoutTooltipAndReadConstraints(
      tester,
      direction: TooltipDirection.top,
      anchorLeft: 300,
      anchorTop: 80,
    );
    expect(topMaxHeight.height, lessThanOrEqualTo(70));

    final bottomMaxHeight = await _layoutTooltipAndReadConstraints(
      tester,
      direction: TooltipDirection.bottom,
      anchorLeft: 300,
      anchorTop: 510,
    );
    expect(bottomMaxHeight.height, lessThanOrEqualTo(70));
  });

  testWidgets(
    'allows top and bottom tooltip arrows to match side edge spacing',
    (WidgetTester tester) async {
      final controller = TapTooltipController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 300,
                  top: 300,
                  child: TapTooltip(
                    controller: controller,
                    direction: TooltipDirection.bottom,
                    autoSafeDetection: false,
                    isStart: true,
                    triangleWidth: 20,
                    padding: EdgeInsets.zero,
                    tooltipWidget: const SizedBox(
                      key: _tooltipBoxKey,
                      width: 120,
                      height: 40,
                    ),
                    child: const SizedBox(
                      key: _anchorKey,
                      width: 10,
                      height: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      controller.show();
      await tester.pumpAndSettle();

      final tooltip = tester.getRect(find.byKey(_tooltipBoxKey));
      final anchor = tester.getRect(find.byKey(_anchorKey));
      expect((tooltip.left + 5 - anchor.center.dx).abs(), lessThan(0.01));
    },
  );

  testWidgets(
    'keeps tooltip inside screen when auto safe detection is enabled',
    (WidgetTester tester) async {
      await _pumpEdgeTooltip(tester, autoSafeDetection: true);

      final safeLeft = tester.getTopLeft(find.byKey(_tooltipBoxKey)).dx;
      expect(safeLeft, greaterThanOrEqualTo(0));
    },
  );

  testWidgets('allows overflow when auto safe detection is disabled', (
    WidgetTester tester,
  ) async {
    await _pumpEdgeTooltip(tester, autoSafeDetection: false);

    final unsafeLeft = tester.getTopLeft(find.byKey(_tooltipBoxKey)).dx;
    expect(unsafeLeft, lessThan(0));
  });

  testWidgets('respects safe padding when auto safe detection is enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 200,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 100,
                  child: TapTooltip(
                    direction: TooltipDirection.bottom,
                    autoSafeDetection: true,
                    safePadding: const EdgeInsets.only(left: 24, top: 12),
                    tooltipBuilder: (_) {
                      return const SizedBox(
                        key: _tooltipBoxKey,
                        width: 180,
                        height: 40,
                        child: Text('Padded tooltip'),
                      );
                    },
                    child: const SizedBox(key: _anchorKey, width: 1, height: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(_anchorKey), warnIfMissed: false);
    await tester.pumpAndSettle();

    final paddedLeft = tester.getTopLeft(find.byKey(_tooltipBoxKey)).dx;
    expect(paddedLeft, greaterThanOrEqualTo(24));
  });
}

const _anchorKey = Key('anchor');
const _tooltipBoxKey = Key('tooltip-box');

Future<Size> _layoutTooltipAndReadConstraints(
  WidgetTester tester, {
  required TooltipDirection direction,
  required double anchorLeft,
  required double anchorTop,
}) async {
  final controller = TapTooltipController();
  addTearDown(controller.dispose);
  Size? maxSize;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(
              left: anchorLeft,
              top: anchorTop,
              child: TapTooltip(
                controller: controller,
                direction: direction,
                autoSafeDetection: true,
                safePadding: const EdgeInsets.all(20),
                padding: EdgeInsets.zero,
                triangleWidth: 1,
                triangleHeight: 1,
                tooltipWidget: LayoutBuilder(
                  builder: (context, constraints) {
                    maxSize = Size(constraints.maxWidth, constraints.maxHeight);
                    return const SizedBox(width: 1000, height: 1000);
                  },
                ),
                child: const SizedBox(key: _anchorKey, width: 10, height: 10),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  controller.show();
  await tester.pumpAndSettle();

  return maxSize!;
}

Future<void> _pumpEdgeTooltip(
  WidgetTester tester, {
  required bool autoSafeDetection,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 100,
                child: TapTooltip(
                  direction: TooltipDirection.bottom,
                  autoSafeDetection: autoSafeDetection,
                  offset: const Offset(-24, 0),
                  tooltipBuilder: (_) {
                    return const SizedBox(
                      key: _tooltipBoxKey,
                      width: 180,
                      height: 40,
                      child: Text('Safe tooltip'),
                    );
                  },
                  child: const SizedBox(key: _anchorKey, width: 1, height: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.byKey(_anchorKey), warnIfMissed: false);
  await tester.pumpAndSettle();
}
