# tap_tooltip

A Flutter widget for showing a click-triggered tooltip from any anchor widget.
It supports text, custom content widgets, fully custom overlay builders,
directional placement, arrow styling, controller-driven visibility, background
blur, outside-tap dismissal, and automatic screen-boundary adjustment.

[![](https://img.shields.io/pub/v/tap_tooltip.svg)](https://pub.dev/packages/tap_tooltip)

![top](https://raw.githubusercontent.com/ZxlHyy/tap_tooltip/master/images/top.jpg)
![bottom](https://raw.githubusercontent.com/ZxlHyy/tap_tooltip/master/images/bottom.jpg)
![left](https://raw.githubusercontent.com/ZxlHyy/tap_tooltip/master/images/left.jpg)
![right](https://raw.githubusercontent.com/ZxlHyy/tap_tooltip/master/images/right.jpg)
![child](https://raw.githubusercontent.com/ZxlHyy/tap_tooltip/master/images/child.jpg)
![gradiant](https://raw.githubusercontent.com/ZxlHyy/tap_tooltip/master/images/gradiant.jpg)
![setting](https://raw.githubusercontent.com/ZxlHyy/tap_tooltip/master/images/setting.jpg)


## Features

- Show a tooltip when the user taps an icon or any custom child widget.
- Place the tooltip above, below, left, or right of the anchor.
- Use plain text, a custom `Widget`, or a complete `tooltipBuilder` overlay.
- Customize padding, constraints, width, height, decoration, text style, arrow
  size, and arrow radius.
- Control visibility from outside the widget with `TapTooltipController`.
- Keep the tooltip inside the visible screen with `autoSafeDetection` and
  `safePadding`.
- Optionally dismiss the tooltip on outside taps or disable anchor click
  handling for controller-only flows.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  tap_tooltip: ^0.0.5
```

Then import it:

```dart
import 'package:tap_tooltip/tap_tooltip.dart';
```

## Basic Usage

```dart
TapTooltip(
  tooltip: 'Helpful explanation',
)
```

By default, `TapTooltip` renders a small help icon. Tapping the icon opens the
tooltip.

## Custom Anchor

Pass `child` to use your own clickable anchor:

```dart
TapTooltip(
  direction: TooltipDirection.bottom,
  tooltip: 'This message is attached to a custom button.',
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.indigo,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'Tap me',
      style: TextStyle(color: Colors.white),
    ),
  ),
)
```

If you use the default icon, you can customize it with `questionColor` and
`questionSize`.

## Tooltip Content

Use `tooltip` for simple text:

```dart
TapTooltip(
  tooltip: 'Plain text tooltip',
)
```

Use `tooltipWidget` for custom content inside the default bubble:

```dart
TapTooltip(
  tooltipWidget: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Text(
        'Title',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 6),
      Text(
        'Any Flutter widget can be used here.',
        style: TextStyle(color: Colors.white),
      ),
    ],
  ),
)
```

Use `tooltipBuilder` when you want to draw the entire overlay yourself:

```dart
TapTooltip(
  direction: TooltipDirection.left,
  tooltipBuilder: (context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            color: Color(0x26000000),
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Fully custom tooltip overlay'),
      ),
    );
  },
)
```

At least one of `tooltip`, `tooltipWidget`, or `tooltipBuilder` must be
provided.

## Controller

Use `TapTooltipController` when another widget should show, hide, or toggle
the tooltip:

```dart
class ControlledTooltipExample extends StatefulWidget {
  const ControlledTooltipExample({super.key});

  @override
  State<ControlledTooltipExample> createState() =>
      _ControlledTooltipExampleState();
}

class _ControlledTooltipExampleState extends State<ControlledTooltipExample> {
  final TapTooltipController _controller = TapTooltipController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TapTooltip(
          controller: _controller,
          tooltip: 'Controlled tooltip',
          clickable: false,
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: _controller.toggle,
          child: const Text('Toggle'),
        ),
      ],
    );
  }
}
```

## Positioning And Safety

Choose the popup side with `direction`:

```dart
TapTooltip(
  direction: TooltipDirection.right,
  tooltip: 'The tooltip appears on the right side.',
)
```

Available directions are:

- `TooltipDirection.top`
- `TooltipDirection.bottom`
- `TooltipDirection.left`
- `TooltipDirection.right`

`autoSafeDetection` is enabled by default. It limits tooltip size and shifts the
bubble so it stays inside the overlay bounds. Use `safePadding` to reserve space
from screen edges:

```dart
TapTooltip(
  direction: TooltipDirection.bottom,
  autoSafeDetection: true,
  safePadding: const EdgeInsets.all(16),
  tooltip: 'This tooltip stays away from screen edges.',
)
```

Use `offset` for manual adjustment:

```dart
TapTooltip(
  offset: const Offset(12, 8),
  tooltip: 'Offset from the default anchor position.',
)
```

## Styling

```dart
TapTooltip(
  direction: TooltipDirection.bottom,
  padding: const EdgeInsets.all(14),
  maxWidth: 240,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.indigo),
    boxShadow: const [
      BoxShadow(
        blurRadius: 12,
        color: Color(0x1F000000),
        offset: Offset(0, 4),
      ),
    ],
  ),
  tooltipStyle: const TextStyle(color: Colors.black87),
  triangleWidth: 18,
  triangleHeight: 10,
  triangleRadius: 2,
  tooltip: 'Styled tooltip',
)
```

Set `isBlur: true` to apply a blur effect behind the tooltip bubble when using
the default bubble renderer.

## Dismiss Behavior

- `autoDismiss`: inserts a full-screen tap target behind the tooltip.
- `barrierDismissible`: controls whether tapping that background hides the
  tooltip.
- `clickable`: controls whether tapping the anchor toggles the tooltip.

```dart
TapTooltip(
  tooltip: 'Tap outside to close',
  autoDismiss: true,
  barrierDismissible: true,
)
```

## Example

The package includes an example app with a configuration playground and focused
samples for every public option. Run it with:

```sh
cd example
flutter run
```

## License

This package is released under the license included in the repository.
