import 'package:tap_tooltip/tap_tooltip.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const TapTooltipDemoApp());
}

class TapTooltipDemoApp extends StatelessWidget {
  const TapTooltipDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TapTooltip 配置演示')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: const [
          _Section(title: '0. 实时配置面板', child: _InteractivePlayground()),
          _Section(title: '1. 方向 (direction)', child: _DirectionDemos()),
          _Section(title: '2. 箭头对齐 (isStart)', child: _IsStartDemos()),
          _Section(
            title: '3. 箭头形状 (triangleWidth / triangleHeight / triangleRadius)',
            child: _TriangleShapeDemos(),
          ),
          _Section(
            title: '4. 自定义锚点 (child / questionColor / questionSize)',
            child: _AnchorDemos(),
          ),
          _Section(
            title: '5. 内容形式 (tooltip / tooltipWidget / tooltipBuilder)',
            child: _ContentDemos(),
          ),
          _Section(
            title: '6. 样式 (decoration / tooltipStyle / padding)',
            child: _StyleDemos(),
          ),
          _Section(title: '7. 模糊背景 (isBlur)', child: _BlurDemos()),
          _Section(
            title:
                '8. 交互控制 (autoDismiss / barrierDismissible / clickable / controller)',
            child: _InteractionDemos(),
          ),
          _Section(
            title: '9. 偏移与尺寸 (offset / maxWidth / maxHeight)',
            child: _SizeDemos(),
          ),
          _Section(
            title: '10. 安全区域 (autoSafeDetection / safePadding)',
            child: _SafeAreaDemos(),
          ),
        ],
      ),
    );
  }
}

// ─── Section wrapper ───────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        child,
        const Divider(indent: 20, endIndent: 20, height: 24),
      ],
    );
  }
}

// ─── Demo tile ─────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.child, this.subtitle});

  final String label;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) const SizedBox(height: 2),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          child,
        ],
      ),
    );
  }
}

// ─── 0. Interactive playground ─────────────────────────────────────────────

enum _DemoContent { text, widget, builder }

enum _DemoAnchor { icon, coloredIcon, bigIcon, custom }

enum _DemoStyle { dark, light, gradient }

class _InteractivePlayground extends StatefulWidget {
  const _InteractivePlayground();

  @override
  State<_InteractivePlayground> createState() => _InteractivePlaygroundState();
}

class _InteractivePlaygroundState extends State<_InteractivePlayground> {
  final TapTooltipController _controller = TapTooltipController();
  TooltipDirection _direction = TooltipDirection.top;
  _DemoContent _content = _DemoContent.text;
  _DemoAnchor _anchor = _DemoAnchor.icon;
  _DemoStyle _style = _DemoStyle.dark;
  bool _isStart = true;
  bool _autoDismiss = true;
  bool _barrierDismissible = true;
  bool _autoSafeDetection = true;
  bool _isBlur = false;
  bool _clickable = true;
  bool _useConstraints = false;
  double _triangleWidth = 16;
  double _triangleHeight = 16;
  double _triangleRadius = 0;
  double _offsetX = 0;
  double _offsetY = 0;
  double _maxWidth = 220;
  double _maxHeight = 220;
  double _padding = 12;
  double _safePadding = 8;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: _PlaygroundBackdrop()),
                Align(
                  alignment: Alignment.center,
                  child: _buildTooltip(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: _controller.show,
                child: const Text('显示'),
              ),
              OutlinedButton(
                onPressed: _controller.hide,
                child: const Text('隐藏'),
              ),
              OutlinedButton(
                onPressed: _controller.toggle,
                child: const Text('切换'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ControlBlock(
            label: 'direction',
            child: SegmentedButton<TooltipDirection>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: TooltipDirection.top, label: Text('top')),
                ButtonSegment(
                  value: TooltipDirection.bottom,
                  label: Text('bottom'),
                ),
                ButtonSegment(
                  value: TooltipDirection.left,
                  label: Text('left'),
                ),
                ButtonSegment(
                  value: TooltipDirection.right,
                  label: Text('right'),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (value) {
                setState(() => _direction = value.first);
                _controller.show();
              },
            ),
          ),
          _ControlBlock(
            label: '内容',
            child: SegmentedButton<_DemoContent>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _DemoContent.text, label: Text('text')),
                ButtonSegment(
                  value: _DemoContent.widget,
                  label: Text('widget'),
                ),
                ButtonSegment(
                  value: _DemoContent.builder,
                  label: Text('builder'),
                ),
              ],
              selected: {_content},
              onSelectionChanged: (value) {
                setState(() => _content = value.first);
                _controller.show();
              },
            ),
          ),
          _ControlBlock(
            label: '锚点',
            child: SegmentedButton<_DemoAnchor>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _DemoAnchor.icon, label: Text('默认')),
                ButtonSegment(
                  value: _DemoAnchor.coloredIcon,
                  label: Text('红色'),
                ),
                ButtonSegment(value: _DemoAnchor.bigIcon, label: Text('大图标')),
                ButtonSegment(value: _DemoAnchor.custom, label: Text('child')),
              ],
              selected: {_anchor},
              onSelectionChanged: (value) {
                setState(() => _anchor = value.first);
                _controller.show();
              },
            ),
          ),
          _ControlBlock(
            label: '样式',
            child: SegmentedButton<_DemoStyle>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _DemoStyle.dark, label: Text('黑色')),
                ButtonSegment(value: _DemoStyle.light, label: Text('白色')),
                ButtonSegment(value: _DemoStyle.gradient, label: Text('渐变')),
              ],
              selected: {_style},
              onSelectionChanged: (value) {
                setState(() => _style = value.first);
                _controller.show();
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BoolChip(
                label: 'isStart',
                value: _isStart,
                onChanged: (value) => _setBool(() => _isStart = value),
              ),
              _BoolChip(
                label: 'autoDismiss',
                value: _autoDismiss,
                onChanged: (value) => _setBool(() => _autoDismiss = value),
              ),
              _BoolChip(
                label: 'barrierDismissible',
                value: _barrierDismissible,
                onChanged: (value) =>
                    _setBool(() => _barrierDismissible = value),
              ),
              _BoolChip(
                label: 'autoSafeDetection',
                value: _autoSafeDetection,
                onChanged: (value) =>
                    _setBool(() => _autoSafeDetection = value),
              ),
              _BoolChip(
                label: 'isBlur',
                value: _isBlur,
                onChanged: (value) => _setBool(() => _isBlur = value),
              ),
              _BoolChip(
                label: 'clickable',
                value: _clickable,
                onChanged: (value) => _setBool(() => _clickable = value),
              ),
              _BoolChip(
                label: 'constraints',
                value: _useConstraints,
                onChanged: (value) => _setBool(() => _useConstraints = value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _NumberSlider(
            label: 'triangleWidth',
            value: _triangleWidth,
            min: 8,
            max: 36,
            onChanged: (value) =>
                _setNumber(() => _triangleWidth = value.roundToDouble()),
          ),
          _NumberSlider(
            label: 'triangleHeight',
            value: _triangleHeight,
            min: 8,
            max: 36,
            onChanged: (value) =>
                _setNumber(() => _triangleHeight = value.roundToDouble()),
          ),
          _NumberSlider(
            label: 'triangleRadius',
            value: _triangleRadius,
            min: 0,
            max: 10,
            onChanged: (value) =>
                _setNumber(() => _triangleRadius = value.roundToDouble()),
          ),
          _NumberSlider(
            label: 'offset.dx',
            value: _offsetX,
            min: -80,
            max: 80,
            onChanged: (value) =>
                _setNumber(() => _offsetX = value.roundToDouble()),
          ),
          _NumberSlider(
            label: 'offset.dy',
            value: _offsetY,
            min: -60,
            max: 60,
            onChanged: (value) =>
                _setNumber(() => _offsetY = value.roundToDouble()),
          ),
          _NumberSlider(
            label: 'maxWidth',
            value: _maxWidth,
            min: 120,
            max: 360,
            onChanged: (value) =>
                _setNumber(() => _maxWidth = value.roundToDouble()),
          ),
          _NumberSlider(
            label: 'maxHeight',
            value: _maxHeight,
            min: 48,
            max: 260,
            onChanged: (value) =>
                _setNumber(() => _maxHeight = value.roundToDouble()),
          ),
          _NumberSlider(
            label: 'padding',
            value: _padding,
            min: 4,
            max: 28,
            onChanged: (value) =>
                _setNumber(() => _padding = value.roundToDouble()),
          ),
          _NumberSlider(
            label: 'safePadding',
            value: _safePadding,
            min: 0,
            max: 60,
            onChanged: (value) =>
                _setNumber(() => _safePadding = value.roundToDouble()),
          ),
          const SizedBox(height: 8),
          Text(
            _configText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip(BuildContext context) {
    return TapTooltip(
      key: ValueKey(_content),
      controller: _controller,
      direction: _direction,
      isStart: _isStart,
      autoDismiss: _autoDismiss,
      barrierDismissible: _barrierDismissible,
      autoSafeDetection: _autoSafeDetection,
      safePadding: EdgeInsets.all(_safePadding),
      isBlur: _isBlur,
      clickable: _clickable,
      triangleWidth: _triangleWidth,
      triangleHeight: _triangleHeight,
      triangleRadius: _triangleRadius,
      offset: Offset(_offsetX, _offsetY),
      maxWidth: _maxWidth,
      maxHeight: _maxHeight,
      constraints: _useConstraints
          ? BoxConstraints(
              minWidth: 180,
              minHeight: 96,
              maxWidth: _maxWidth,
              maxHeight: _maxHeight,
            )
          : null,
      padding: EdgeInsets.all(_padding),
      decoration: _content == _DemoContent.builder ? null : _decoration,
      tooltipStyle: _tooltipStyle,
      tooltip: _content == _DemoContent.text ? _tooltipText : null,
      tooltipWidget: _content == _DemoContent.widget ? _tooltipWidget : null,
      tooltipBuilder: _content == _DemoContent.builder
          ? _buildCustomOverlay
          : null,
      questionColor: _anchor == _DemoAnchor.coloredIcon ? Colors.red : null,
      questionSize: _anchor == _DemoAnchor.bigIcon ? 32 : null,
      child: _anchor == _DemoAnchor.custom ? _customAnchor : null,
    );
  }

  String get _tooltipText {
    return '实时预览当前配置：direction=$_direction, isStart=$_isStart, '
        'offset=(${_offsetX.toInt()}, ${_offsetY.toInt()})';
  }

  Widget get _tooltipWidget {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'tooltipWidget',
          style: TextStyle(color: _contentColor, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'padding=${_padding.toInt()}, maxWidth=${_maxWidth.toInt()}',
          style: TextStyle(color: _contentColor, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildCustomOverlay(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: _maxWidth),
      padding: EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: Colors.white54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x26000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Text('tooltipBuilder：整个浮层完全由 builder 控制'),
    );
  }

  BoxDecoration get _decoration {
    switch (_style) {
      case _DemoStyle.dark:
        return BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        );
      case _DemoStyle.light:
        return BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.indigo.shade200),
          boxShadow: const [
            BoxShadow(
              blurRadius: 14,
              color: Color(0x26000000),
              offset: Offset(0, 6),
            ),
          ],
        );
      case _DemoStyle.gradient:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Colors.indigo, Colors.purple],
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 14,
              color: Color(0x33000000),
              offset: Offset(0, 6),
            ),
          ],
        );
    }
  }

  TextStyle get _tooltipStyle {
    return TextStyle(
      color: _contentColor,
      fontSize: _style == _DemoStyle.gradient ? 15 : 13,
      fontWeight: _style == _DemoStyle.gradient
          ? FontWeight.w700
          : FontWeight.w400,
    );
  }

  Color get _contentColor {
    return _style == _DemoStyle.light ? Colors.black87 : Colors.white;
  }

  Widget get _customAnchor {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '自定义 child',
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  String get _configText {
    return '当前：direction=$_direction, isStart=$_isStart, '
        'autoDismiss=$_autoDismiss, barrierDismissible=$_barrierDismissible, '
        'autoSafeDetection=$_autoSafeDetection, isBlur=$_isBlur, '
        'clickable=$_clickable, constraints=$_useConstraints, '
        'triangle=${_triangleWidth.toInt()}x${_triangleHeight.toInt()}, '
        'radius=${_triangleRadius.toInt()}, offset=(${_offsetX.toInt()}, ${_offsetY.toInt()}), '
        'maxWidth=${_maxWidth.toInt()}, maxHeight=${_maxHeight.toInt()}, '
        'padding=${_padding.toInt()}, safePadding=${_safePadding.toInt()}';
  }

  void _setBool(VoidCallback update) {
    setState(update);
  }

  void _setNumber(VoidCallback update) {
    setState(update);
  }
}

class _PlaygroundBackdrop extends StatelessWidget {
  const _PlaygroundBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PlaygroundBackdropPainter());
  }
}

class _PlaygroundBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(16)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ControlBlock extends StatelessWidget {
  const _ControlBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: child),
        ],
      ),
    );
  }
}

class _BoolChip extends StatelessWidget {
  const _BoolChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      showCheckmark: false,
    );
  }
}

class _NumberSlider extends StatelessWidget {
  const _NumberSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 116, child: Text('$label: ${value.toInt()}')),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ─── 1. Direction ──────────────────────────────────────────────────────────

class _DirectionDemos extends StatelessWidget {
  const _DirectionDemos();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Tile(
          label: 'direction: top',
          subtitle: '气泡在锚点上方',
          child: TapTooltip(
            direction: TooltipDirection.top,
            tooltip: 'direction=top → 气泡出现在锚点上方',
          ),
        ),
        _Tile(
          label: 'direction: bottom',
          subtitle: '气泡在锚点下方',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            tooltip: 'direction=bottom → 气泡出现在锚点下方',
          ),
        ),
        _Tile(
          label: 'direction: left',
          subtitle: '气泡在锚点左侧',
          child: TapTooltip(
            direction: TooltipDirection.left,
            tooltip: 'direction=left → 气泡出现在锚点左侧',
          ),
        ),
        _Tile(
          label: 'direction: right',
          subtitle: '气泡在锚点右侧',
          child: TapTooltip(
            direction: TooltipDirection.right,
            tooltip: 'direction=right → 气泡出现在锚点右侧',
          ),
        ),
      ],
    );
  }
}

// ─── 2. isStart ────────────────────────────────────────────────────────────

class _IsStartDemos extends StatelessWidget {
  const _IsStartDemos();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Tile(
          label: 'isStart: true',
          subtitle: '箭头靠起始侧对齐（默认）',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            isStart: true,
            tooltip: 'isStart=true → 箭头靠左/上对齐',
          ),
        ),
        _Tile(
          label: 'isStart: false',
          subtitle: '箭头靠末尾侧对齐',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            isStart: false,
            tooltip: 'isStart=false → 箭头靠右/下对齐',
          ),
        ),
      ],
    );
  }
}

// ─── 3. Triangle shape ─────────────────────────────────────────────────────

class _TriangleShapeDemos extends StatelessWidget {
  const _TriangleShapeDemos();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Tile(
          label: '默认箭头',
          subtitle: 'triangleWidth / triangleHeight 为默认值',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            tooltip: '默认箭头形状',
          ),
        ),
        _Tile(
          label: '宽箭头',
          subtitle: 'triangleWidth: 28, triangleHeight: 14',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            triangleWidth: 28,
            triangleHeight: 14,
            tooltip: '更宽更高的箭头',
          ),
        ),
        _Tile(
          label: '圆角箭头',
          subtitle: 'triangleRadius: 4',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            triangleRadius: 4,
            tooltip: 'triangleRadius 让箭头尖端变圆',
          ),
        ),
        _Tile(
          label: '大圆角箭头',
          subtitle: 'triangleRadius: 8',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            triangleRadius: 8,
            tooltip: '更大的圆角半径',
          ),
        ),
      ],
    );
  }
}

// ─── 4. Custom anchor ──────────────────────────────────────────────────────

class _AnchorDemos extends StatelessWidget {
  const _AnchorDemos();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Tile(
          label: '默认锚点',
          subtitle: '未设置 child，默认 help 图标',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            tooltip: '默认显示 help_outline 图标',
          ),
        ),
        _Tile(
          label: 'questionColor: Colors.red',
          subtitle: '图标颜色设为红色',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            questionColor: Colors.red,
            tooltip: 'questionColor 控制默认图标颜色',
          ),
        ),
        _Tile(
          label: 'questionSize: 28',
          subtitle: '图标尺寸放大',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            questionSize: 28,
            questionColor: Colors.indigo,
            tooltip: 'questionSize 控制默认图标大小',
          ),
        ),
        _Tile(
          label: '自定义 child',
          subtitle: '用任意 Widget 替代默认图标',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            tooltip: 'child 可以是任意 Widget',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '点我',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 5. Content forms ──────────────────────────────────────────────────────

class _ContentDemos extends StatelessWidget {
  const _ContentDemos();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Tile(
          label: 'tooltip (纯文本)',
          subtitle: '最简用法，传入 String',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            tooltip: '这是 tooltip 参数，支持纯文本',
          ),
        ),
        _Tile(
          label: 'tooltipWidget',
          subtitle: '自定义气泡内容 Widget',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            triangleRadius: 2,
            tooltipWidget: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.yellow.shade200,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '标题',
                      style: TextStyle(
                        color: Colors.yellow.shade200,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'tooltipWidget 支持任意 Widget 组合',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        _Tile(
          label: 'tooltipBuilder',
          subtitle: '完全自定义整个浮层',
          child: TapTooltip(
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
                  child: Text('tooltipBuilder 控制整个浮层，不含默认气泡'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── 6. Styling ────────────────────────────────────────────────────────────

class _StyleDemos extends StatelessWidget {
  const _StyleDemos();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Tile(
          label: '默认样式',
          subtitle: '黑色背景 + 白色文字',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            tooltip: '默认: 黑色半透明背景 + 白色 14px 文字',
          ),
        ),
        _Tile(
          label: '自定义 decoration',
          subtitle: '颜色 + 圆角 + 边框 + 阴影',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.indigo.shade200),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  color: Color(0x1F000000),
                  offset: Offset(0, 4),
                ),
              ],
            ),
            tooltipStyle: const TextStyle(color: Colors.black87, fontSize: 13),
            tooltip: 'decoration 支持颜色、圆角、边框、阴影、渐变等',
          ),
        ),
        _Tile(
          label: '渐变背景 decoration',
          subtitle: 'gradient + 阴影',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Colors.indigo, Colors.purple],
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  color: Color(0x40000000),
                  offset: Offset(0, 4),
                ),
              ],
            ),
            tooltip: '使用渐变背景的气泡',
            tooltipStyle: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        _Tile(
          label: '自定义 padding',
          subtitle: 'padding: EdgeInsets.all(20)',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            tooltipStyle: const TextStyle(color: Colors.white, fontSize: 13),
            tooltip: '更大的内边距让内容更透气',
          ),
        ),
        _Tile(
          label: '自定义 tooltipStyle',
          subtitle: '字体大小、颜色、粗细等',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
            ),
            tooltipStyle: const TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            tooltip: '自定义文字样式',
          ),
        ),
      ],
    );
  }
}

// ─── 7. Blur ───────────────────────────────────────────────────────────────

class _BlurDemos extends StatelessWidget {
  const _BlurDemos();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Tile(
          label: 'isBlur: false (默认)',
          subtitle: '无模糊效果',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            isBlur: false,
            tooltip: '默认无背景模糊',
          ),
        ),
        _Tile(
          label: 'isBlur: true',
          subtitle: '气泡下方背景被模糊处理',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            isBlur: true,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
            ),
            tooltipStyle: const TextStyle(color: Colors.black87, fontSize: 13),
            tooltip: 'isBlur=true → 气泡下方内容会被高斯模糊',
          ),
        ),
      ],
    );
  }
}

// ─── 8. Interaction ───────────────────────────────────────────────────────

class _InteractionDemos extends StatefulWidget {
  const _InteractionDemos();

  @override
  State<_InteractionDemos> createState() => _InteractionDemosState();
}

class _InteractionDemosState extends State<_InteractionDemos> {
  final TapTooltipController _controller = TapTooltipController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Tile(
          label: 'autoDismiss: true (默认)',
          subtitle: '点击气泡外部自动关闭',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            autoDismiss: true,
            tooltip: '点击空白处关闭',
          ),
        ),
        _Tile(
          label: 'autoDismiss: false',
          subtitle: '点击气泡外部不会自动关闭',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            autoDismiss: false,
            tooltip: '点击空白处不会关闭，只能通过 controller 关闭',
          ),
        ),
        _Tile(
          label: 'barrierDismissible: false',
          subtitle: 'autoDismiss=true 但点击空白不关闭',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            autoDismiss: true,
            barrierDismissible: false,
            tooltip: 'barrierDismissible=false 禁止点击空白关闭',
          ),
        ),
        _Tile(
          label: 'clickable: false',
          subtitle: '锚点不可点击，由 controller 控制',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            clickable: false,
            controller: _controller,
            tooltip: 'clickable=false → 锚点不可点击，需 controller.show()',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              FilledButton.tonal(
                onPressed: _controller.show,
                child: const Text('controller.show()'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _controller.hide,
                child: const Text('controller.hide()'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _controller.toggle,
                child: const Text('toggle()'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 9. Size & Offset ──────────────────────────────────────────────────────

class _SizeDemos extends StatelessWidget {
  const _SizeDemos();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Tile(
          label: 'offset: Offset(0, 0)',
          subtitle: '无偏移（默认）',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            offset: Offset.zero,
            tooltip: 'offset=Offset.zero 无额外偏移',
          ),
        ),
        _Tile(
          label: 'offset: Offset(40, 0)',
          subtitle: '箭头向右偏移 40px',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            offset: const Offset(40, 0),
            tooltip: 'offset.dx=40 → 箭头向右偏移',
          ),
        ),
        _Tile(
          label: 'maxWidth: 150',
          subtitle: '限制气泡最大宽度',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            maxWidth: 150,
            tooltip: 'maxWidth 限制气泡最大宽度，超出会自动换行',
          ),
        ),
        _Tile(
          label: 'maxWidth: 300',
          subtitle: '更宽的气泡',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            maxWidth: 300,
            tooltip: 'maxWidth 设大一些气泡就更宽',
          ),
        ),
        _Tile(
          label: 'maxHeight: 60',
          subtitle: '限制气泡最大高度',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            maxHeight: 60,
            tooltip: 'maxHeight 限制气泡最大高度，内容超出会被裁切',
          ),
        ),
      ],
    );
  }
}

// ─── 10. Safe area ──────────────────────────────────────────────────────────

class _SafeAreaDemos extends StatelessWidget {
  const _SafeAreaDemos();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Tile(
          label: 'autoSafeDetection: true (默认)',
          subtitle: '气泡自动避让屏幕边缘',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            autoSafeDetection: true,
            tooltip: 'autoSafeDetection=true → 气泡自动调整位置避免超出屏幕',
          ),
        ),
        _Tile(
          label: 'autoSafeDetection: false',
          subtitle: '不自动避让，气泡可能超出屏幕',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            autoSafeDetection: false,
            tooltip: '关闭自动避让，气泡可能被截断',
          ),
        ),
        _Tile(
          label: 'safePadding: EdgeInsets.all(8)',
          subtitle: '安全边距 (默认 8)',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            safePadding: const EdgeInsets.all(8),
            tooltip: 'safePadding 控制气泡与屏幕边缘的最小间距',
          ),
        ),
        _Tile(
          label: 'safePadding: EdgeInsets.all(40)',
          subtitle: '更大的安全边距',
          child: TapTooltip(
            direction: TooltipDirection.bottom,
            safePadding: const EdgeInsets.all(40),
            tooltip: '更大的 safePadding 让气泡更远离屏幕边缘',
          ),
        ),
      ],
    );
  }
}
