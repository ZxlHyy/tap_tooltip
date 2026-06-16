import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum TooltipDirection { top, bottom, left, right }

enum TriangleDirection { top, bottom, left, right }

class ClickTooltipController {
  final ValueNotifier<bool> showTip = ValueNotifier<bool>(false);
  VoidCallback? _onShow;
  VoidCallback? _onHide;

  bool get isShowing => showTip.value;

  void _bindView(VoidCallback onShow, VoidCallback onHide) {
    _onShow = onShow;
    _onHide = onHide;
  }

  void _unbindView() {
    _onShow = null;
    _onHide = null;
  }

  void show() {
    _onShow?.call();
    if (_onShow == null) {
      showTip.value = true;
    }
  }

  void hide() {
    _onHide?.call();
    if (_onHide == null) {
      showTip.value = false;
    }
  }

  void toggle() {
    if (showTip.value) {
      hide();
    } else {
      show();
    }
  }

  void dispose() {
    showTip.dispose();
  }
}

class ClickTooltip extends StatefulWidget {
  final ClickTooltipController? controller;

  /// The clickable widget. Defaults to a help icon.
  final Widget? child;
  final Color? questionColor;
  final double? questionSize;
  final EdgeInsets? padding;
  final BoxConstraints? constraints;
  final double? maxWidth;
  final double? maxHeight;
  final BoxDecoration? decoration;
  final WidgetBuilder? tooltipBuilder;
  final Widget? tooltipWidget;
  final String? tooltip;
  final TextStyle? tooltipStyle;
  final Offset? offset;
  final bool autoDismiss;
  final bool autoSafeDetection;
  final EdgeInsets safePadding;
  final bool barrierDismissible;

  /// The side where the tooltip bubble appears relative to the anchor.
  final TooltipDirection direction;
  final bool isStart;
  final bool isBlur;
  final bool clickable;
  final double? triangleWidth;
  final double? triangleHeight;
  final double triangleRadius;

  const ClickTooltip({
    super.key,
    this.controller,
    this.child,
    this.questionColor,
    this.questionSize,
    this.padding,
    this.constraints,
    this.maxWidth,
    this.maxHeight,
    this.decoration,
    this.tooltipBuilder,
    this.tooltipWidget,
    this.tooltip,
    this.tooltipStyle,
    this.offset,
    this.autoDismiss = true,
    this.autoSafeDetection = true,
    this.safePadding = const EdgeInsets.all(8),
    this.barrierDismissible = true,
    this.direction = TooltipDirection.bottom,
    this.isStart = true,
    this.isBlur = false,
    this.clickable = true,
    this.triangleWidth,
    this.triangleHeight,
    this.triangleRadius = 0,
  }) : assert(
         tooltipBuilder != null || tooltipWidget != null || tooltip != null,
         'tooltipBuilder, tooltipWidget, or tooltip must be provided.',
       ),
       assert(triangleWidth == null || triangleWidth > 0),
       assert(triangleHeight == null || triangleHeight > 0),
       assert(triangleRadius >= 0);

  @override
  State<ClickTooltip> createState() => _ClickTooltipState();
}

class _ClickTooltipState extends State<ClickTooltip>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 180);
  static const double _defaultIconSize = 16;
  static const double _defaultPadding = 12;
  static const double _defaultBorderRadius = 8;
  static const double _defaultFontSize = 14;
  static const double _defaultVerticalTriangleWidth = 16;
  static const double _defaultVerticalTriangleHeight = 10;
  static const double _defaultHorizontalTriangleWidth = 10;
  static const double _defaultHorizontalTriangleHeight = 16;

  late ClickTooltipController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Size? _tooltipSize;
  bool _ownsController = false;
  bool _isVisible = false;
  int _animationToken = 0;

  @override
  void initState() {
    super.initState();
    _bindController(widget.controller);
    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
      reverseDuration: _animationDuration,
    );
    final curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fadeAnimation = curvedAnimation;
    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(curvedAnimation);
  }

  @override
  void didUpdateWidget(covariant ClickTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _releaseController();
      _bindController(widget.controller);
    }
    if (_overlayEntry != null) {
      _tooltipSize = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) {
          _overlayEntry!.markNeedsBuild();
        }
      });
    }
  }

  @override
  void dispose() {
    _releaseController();
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  Axis get _axis =>
      widget.direction == TooltipDirection.top ||
          widget.direction == TooltipDirection.bottom
      ? Axis.vertical
      : Axis.horizontal;

  TriangleDirection get _arrowDirection {
    switch (widget.direction) {
      case TooltipDirection.top:
        return TriangleDirection.bottom;
      case TooltipDirection.bottom:
        return TriangleDirection.top;
      case TooltipDirection.left:
        return TriangleDirection.right;
      case TooltipDirection.right:
        return TriangleDirection.left;
    }
  }

  Offset get _offset => widget.offset ?? Offset.zero;

  Offset get _followerOffset {
    if (_axis == Axis.vertical) {
      return Offset(0, _offset.dy);
    }
    return Offset(_offset.dx, 0);
  }

  void _bindController(ClickTooltipController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? ClickTooltipController();
    _controller._bindView(_showTooltip, _hideTooltip);
    _setVisible(_controller.showTip.value, rebuild: false);
    if (_controller.showTip.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showTooltip();
        }
      });
    }
  }

  void _releaseController() {
    _controller._unbindView();
    if (_ownsController) {
      _controller.dispose();
    }
  }

  void _toggleTooltip() {
    if (_isVisible) {
      _hideTooltip();
    } else {
      _showTooltip();
    }
  }

  void _showTooltip() {
    if (!mounted) {
      return;
    }
    _animationToken++;
    if (_overlayEntry == null) {
      _overlayEntry = _buildOverlayEntry();
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    }
    if (_tooltipSize == null) {
      _animationController.value = 0;
    } else if (_isVisible) {
      _animationController.forward();
    } else {
      _animationController.forward(from: 0);
    }
    _setVisible(true);
  }

  Future<void> _hideTooltip() async {
    if (_overlayEntry == null) {
      _setVisible(false);
      return;
    }
    final token = ++_animationToken;
    if (mounted) {
      try {
        await _animationController.reverse().orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (token != _animationToken) {
      return;
    }
    _removeOverlay();
    _setVisible(false);
  }

  void _removeOverlay() {
    _animationToken++;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _tooltipSize = null;
  }

  void _setVisible(bool value, {bool rebuild = true}) {
    if (_isVisible == value) {
      if (_controller.showTip.value != value) {
        _controller.showTip.value = value;
      }
      return;
    }
    _isVisible = value;
    if (_controller.showTip.value != value) {
      _controller.showTip.value = value;
    }
    if (rebuild && mounted) {
      setState(() {});
    }
  }

  Alignment _targetAnchor() {
    switch (widget.direction) {
      case TooltipDirection.top:
        return Alignment.topCenter;
      case TooltipDirection.bottom:
        return Alignment.bottomCenter;
      case TooltipDirection.left:
        return Alignment.centerLeft;
      case TooltipDirection.right:
        return Alignment.centerRight;
    }
  }

  Alignment _fallbackFollowerAnchor() {
    switch (_arrowDirection) {
      case TriangleDirection.top:
        return widget.isStart ? Alignment.topLeft : Alignment.topRight;
      case TriangleDirection.bottom:
        return widget.isStart ? Alignment.bottomLeft : Alignment.bottomRight;
      case TriangleDirection.left:
        return widget.isStart ? Alignment.topLeft : Alignment.bottomLeft;
      case TriangleDirection.right:
        return widget.isStart ? Alignment.topRight : Alignment.bottomRight;
    }
  }

  Alignment _followerAnchor(
    double triangleWidth,
    double triangleHeight,
    Offset safeOffset,
  ) {
    final size = _tooltipSize;
    if (size == null || size.isEmpty) {
      return _fallbackFollowerAnchor();
    }
    final tipOffset =
        _arrowTipOffset(size, triangleWidth, triangleHeight) - safeOffset;
    return Alignment(
      tipOffset.dx / size.width * 2 - 1,
      tipOffset.dy / size.height * 2 - 1,
    );
  }

  Offset _arrowTipOffset(
    Size tooltipSize,
    double triangleWidth,
    double triangleHeight,
  ) {
    switch (_arrowDirection) {
      case TriangleDirection.top:
        return Offset(
          _verticalArrowTipX(tooltipSize, triangleWidth, triangleHeight),
          0,
        );
      case TriangleDirection.bottom:
        return Offset(
          _verticalArrowTipX(tooltipSize, triangleWidth, triangleHeight),
          tooltipSize.height,
        );
      case TriangleDirection.left:
        return Offset(0, _horizontalArrowTipY(tooltipSize, triangleHeight));
      case TriangleDirection.right:
        return Offset(
          tooltipSize.width,
          _horizontalArrowTipY(tooltipSize, triangleHeight),
        );
    }
  }

  double _verticalArrowTipX(
    Size tooltipSize,
    double triangleWidth,
    double triangleHeight,
  ) {
    final minTipX = triangleHeight / 2;
    final maxTipX = math.max(minTipX, tooltipSize.width - minTipX);
    final tipX = widget.isStart
        ? math.max(minTipX, -_offset.dx)
        : tooltipSize.width - math.max(minTipX, _offset.dx);
    return tipX.clamp(minTipX, maxTipX);
  }

  double _horizontalArrowTipY(Size tooltipSize, double triangleHeight) {
    final minTipY = triangleHeight / 2;
    final maxTipY = math.max(minTipY, tooltipSize.height - minTipY);
    final tipY = widget.isStart
        ? math.max(minTipY, -_offset.dy)
        : tooltipSize.height - math.max(minTipY, _offset.dy);
    return tipY.clamp(minTipY, maxTipY);
  }

  void _handleTooltipSizeChanged(Size size) {
    if (_tooltipSize == size) {
      return;
    }
    _tooltipSize = size;
    _overlayEntry?.markNeedsBuild();
    if (!_isVisible ||
        _overlayEntry == null ||
        _animationController.status != AnimationStatus.dismissed) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_isVisible ||
          _overlayEntry == null ||
          _animationController.status != AnimationStatus.dismissed) {
        return;
      }
      _animationController.forward(from: 0);
    });
  }

  Offset _safeOffset(
    BuildContext overlayContext,
    double triangleWidth,
    double triangleHeight,
  ) {
    final tooltipSize = _tooltipSize;
    if (!widget.autoSafeDetection ||
        tooltipSize == null ||
        tooltipSize.isEmpty) {
      return Offset.zero;
    }
    final targetRenderObject = context.findRenderObject();
    final overlayRenderObject = Overlay.of(
      overlayContext,
      rootOverlay: true,
    ).context.findRenderObject();
    if (targetRenderObject is! RenderBox ||
        overlayRenderObject is! RenderBox ||
        !targetRenderObject.hasSize ||
        !overlayRenderObject.hasSize) {
      return Offset.zero;
    }

    final targetAnchor = _targetAnchor().alongSize(targetRenderObject.size);
    final targetOffset = targetRenderObject.localToGlobal(
      targetAnchor,
      ancestor: overlayRenderObject,
    );
    final tipOffset = _arrowTipOffset(
      tooltipSize,
      triangleWidth,
      triangleHeight,
    );
    final desiredTopLeft = targetOffset + _followerOffset - tipOffset;
    final overlaySize = overlayRenderObject.size;
    final safePadding = widget.safePadding;
    final minLeft = math.min(safePadding.left, overlaySize.width);
    final minTop = math.min(safePadding.top, overlaySize.height);
    final maxLeft = math.max(
      minLeft,
      overlaySize.width - tooltipSize.width - safePadding.right,
    );
    final maxTop = math.max(
      minTop,
      overlaySize.height - tooltipSize.height - safePadding.bottom,
    );
    final adjustedTopLeft = Offset(
      desiredTopLeft.dx.clamp(minLeft, maxLeft),
      desiredTopLeft.dy.clamp(minTop, maxTop),
    );
    return adjustedTopLeft - desiredTopLeft;
  }

  OverlayEntry _buildOverlayEntry() {
    final triangleWidth =
        widget.triangleWidth ??
        (_axis == Axis.vertical
            ? _defaultVerticalTriangleWidth
            : _defaultHorizontalTriangleWidth);
    final triangleHeight =
        widget.triangleHeight ??
        (_axis == Axis.vertical
            ? _defaultVerticalTriangleHeight
            : _defaultHorizontalTriangleHeight);

    return OverlayEntry(
      builder: (context) {
        final safeOffset = _safeOffset(context, triangleWidth, triangleHeight);
        final followerAnchor = _followerAnchor(
          triangleWidth,
          triangleHeight,
          safeOffset,
        );
        return Stack(
          children: [
            if (widget.autoDismiss)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: widget.barrierDismissible ? _hideTooltip : null,
                ),
              ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: _followerOffset,
              targetAnchor: _targetAnchor(),
              followerAnchor: followerAnchor,
              child: Material(
                type: MaterialType.transparency,
                child: _MeasureSize(
                  onChange: _handleTooltipSizeChanged,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      alignment: followerAnchor,
                      scale: _scaleAnimation,
                      child: _buildTooltipContent(
                        context,
                        triangleWidth,
                        triangleHeight,
                        safeOffset,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTooltipContent(
    BuildContext context,
    double triangleWidth,
    double triangleHeight,
    Offset safeOffset,
  ) {
    if (widget.tooltipBuilder != null) {
      return widget.tooltipBuilder!(context);
    }

    final color = widget.decoration?.color ?? Colors.black.withAlpha(204);
    final decoration =
        widget.decoration ??
        BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(_defaultBorderRadius),
        );
    Widget content = _Bubble(
      direction: _arrowDirection,
      isStart: widget.isStart,
      offset: _offset,
      safeOffset: safeOffset,
      triangleWidth: triangleWidth,
      triangleHeight: triangleHeight,
      triangleRadius: widget.triangleRadius,
      padding: widget.padding ?? const EdgeInsets.all(_defaultPadding),
      constraints: _effectiveConstraints(context),
      decoration: decoration,
      isBlur: widget.isBlur,
      child:
          widget.tooltipWidget ??
          Text(
            widget.tooltip!,
            style:
                widget.tooltipStyle ??
                const TextStyle(
                  fontSize: _defaultFontSize,
                  color: Colors.white,
                ),
          ),
    );
    return content;
  }

  BoxConstraints _effectiveConstraints(BuildContext overlayContext) {
    final baseConstraints =
        widget.constraints ?? _defaultConstraints(overlayContext);
    if (!widget.autoSafeDetection) {
      return baseConstraints;
    }

    final maxDisplaySize = _maxDisplaySize(overlayContext);
    if (maxDisplaySize == null) {
      return baseConstraints;
    }
    final maxWidth = math.min(baseConstraints.maxWidth, maxDisplaySize.width);
    final maxHeight = math.min(
      baseConstraints.maxHeight,
      maxDisplaySize.height,
    );
    return BoxConstraints(
      minWidth: math.min(baseConstraints.minWidth, maxWidth),
      maxWidth: maxWidth,
      minHeight: math.min(baseConstraints.minHeight, maxHeight),
      maxHeight: maxHeight,
    );
  }

  Size? _maxDisplaySize(BuildContext overlayContext) {
    final targetRenderObject = context.findRenderObject();
    final overlayRenderObject = Overlay.of(
      overlayContext,
      rootOverlay: true,
    ).context.findRenderObject();
    if (targetRenderObject is! RenderBox ||
        overlayRenderObject is! RenderBox ||
        !targetRenderObject.hasSize ||
        !overlayRenderObject.hasSize) {
      return null;
    }

    final targetAnchor = _targetAnchor().alongSize(targetRenderObject.size);
    final targetOffset = targetRenderObject.localToGlobal(
      targetAnchor,
      ancestor: overlayRenderObject,
    );
    final overlaySize = overlayRenderObject.size;
    final safePadding = widget.safePadding;
    final safeWidth = math.max(
      0.0,
      overlaySize.width - safePadding.left - safePadding.right,
    );
    final safeHeight = math.max(
      0.0,
      overlaySize.height - safePadding.top - safePadding.bottom,
    );

    switch (widget.direction) {
      case TooltipDirection.top:
        return Size(
          safeWidth,
          math.max(0.0, targetOffset.dy + _offset.dy - safePadding.top),
        );
      case TooltipDirection.bottom:
        return Size(
          safeWidth,
          math.max(
            0.0,
            overlaySize.height -
                safePadding.bottom -
                targetOffset.dy -
                _offset.dy,
          ),
        );
      case TooltipDirection.left:
        return Size(
          math.max(0.0, targetOffset.dx + _offset.dx - safePadding.left),
          safeHeight,
        );
      case TooltipDirection.right:
        return Size(
          math.max(
            0.0,
            overlaySize.width -
                safePadding.right -
                targetOffset.dx -
                _offset.dx,
          ),
          safeHeight,
        );
    }
  }

  BoxConstraints _defaultConstraints(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    return BoxConstraints(
      minWidth: 0,
      minHeight: 0,
      maxWidth: widget.maxWidth ?? screenSize.width * 0.8,
      maxHeight: widget.maxHeight ?? screenSize.height * 0.8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.clickable ? _toggleTooltip : null,
        child:
            widget.child ??
            Icon(
              Icons.help_outline_rounded,
              size: widget.questionSize ?? _defaultIconSize,
              color: widget.questionColor,
            ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.direction,
    required this.isStart,
    required this.offset,
    required this.safeOffset,
    required this.triangleWidth,
    required this.triangleHeight,
    required this.triangleRadius,
    required this.padding,
    required this.constraints,
    required this.decoration,
    required this.isBlur,
    required this.child,
  });

  final TriangleDirection direction;
  final bool isStart;
  final Offset offset;
  final Offset safeOffset;
  final double triangleWidth;
  final double triangleHeight;
  final double triangleRadius;
  final EdgeInsets padding;
  final BoxConstraints constraints;
  final BoxDecoration decoration;
  final bool isBlur;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final arrowPadding = _arrowPadding();
    final contentPadding = padding.add(arrowPadding);
    final borderWidth = _borderWidth(decoration.border);
    Widget result = CustomPaint(
      painter: _BubblePainter(
        direction: direction,
        isStart: isStart,
        offset: offset,
        safeOffset: safeOffset,
        triangleWidth: triangleWidth,
        triangleHeight: triangleHeight,
        triangleRadius: triangleRadius,
        decoration: decoration,
        borderWidth: borderWidth,
      ),
      child: Container(
        constraints: constraints,
        padding: contentPadding,
        child: child,
      ),
    );
    if (!isBlur) {
      return result;
    }
    return ClipPath(
      clipper: _BubbleClipper(
        direction: direction,
        isStart: isStart,
        offset: offset,
        safeOffset: safeOffset,
        triangleWidth: triangleWidth,
        triangleHeight: triangleHeight,
        triangleRadius: triangleRadius,
        borderRadius: _borderRadius(decoration.borderRadius),
        borderWidth: borderWidth,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: result,
      ),
    );
  }

  EdgeInsets _arrowPadding() {
    switch (direction) {
      case TriangleDirection.top:
        return EdgeInsets.only(top: triangleHeight);
      case TriangleDirection.bottom:
        return EdgeInsets.only(bottom: triangleHeight);
      case TriangleDirection.left:
        return EdgeInsets.only(left: triangleWidth);
      case TriangleDirection.right:
        return EdgeInsets.only(right: triangleWidth);
    }
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({
    required this.direction,
    required this.isStart,
    required this.offset,
    required this.safeOffset,
    required this.triangleWidth,
    required this.triangleHeight,
    required this.triangleRadius,
    required this.decoration,
    required this.borderWidth,
  });

  final TriangleDirection direction;
  final bool isStart;
  final Offset offset;
  final Offset safeOffset;
  final double triangleWidth;
  final double triangleHeight;
  final double triangleRadius;
  final BoxDecoration decoration;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final borderRadius = _borderRadius(decoration.borderRadius);
    final path = _BubblePathBuilder(
      direction: direction,
      isStart: isStart,
      offset: offset,
      safeOffset: safeOffset,
      triangleWidth: triangleWidth,
      triangleHeight: triangleHeight,
      triangleRadius: triangleRadius,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
    ).build(size);

    for (final boxShadow in decoration.boxShadow ?? const <BoxShadow>[]) {
      canvas.drawShadow(
        path.shift(boxShadow.offset),
        boxShadow.color,
        boxShadow.blurRadius,
        true,
      );
    }

    final backgroundColor = decoration.color ?? Colors.transparent;
    if (backgroundColor != Colors.transparent) {
      final fillPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = backgroundColor;
      canvas.drawPath(path, fillPaint);
    }
    final gradient = decoration.gradient;
    if (gradient != null) {
      final gradientPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..shader = gradient.createShader(Offset.zero & size);
      canvas.drawPath(path, gradientPaint);
    }

    final border = decoration.border;
    final borderSide = border is Border ? _uniformBorderSide(border) : null;
    if (borderSide != null && borderSide.style != BorderStyle.none) {
      final strokePaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderSide.width
        ..color = borderSide.color;
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.isStart != isStart ||
        oldDelegate.offset != offset ||
        oldDelegate.safeOffset != safeOffset ||
        oldDelegate.triangleWidth != triangleWidth ||
        oldDelegate.triangleHeight != triangleHeight ||
        oldDelegate.triangleRadius != triangleRadius ||
        oldDelegate.decoration != decoration ||
        oldDelegate.borderWidth != borderWidth;
  }
}

class _BubbleClipper extends CustomClipper<Path> {
  const _BubbleClipper({
    required this.direction,
    required this.isStart,
    required this.offset,
    required this.safeOffset,
    required this.triangleWidth,
    required this.triangleHeight,
    required this.triangleRadius,
    required this.borderRadius,
    required this.borderWidth,
  });

  final TriangleDirection direction;
  final bool isStart;
  final Offset offset;
  final Offset safeOffset;
  final double triangleWidth;
  final double triangleHeight;
  final double triangleRadius;
  final BorderRadius borderRadius;
  final double borderWidth;

  @override
  Path getClip(Size size) {
    return _BubblePathBuilder(
      direction: direction,
      isStart: isStart,
      offset: offset,
      safeOffset: safeOffset,
      triangleWidth: triangleWidth,
      triangleHeight: triangleHeight,
      triangleRadius: triangleRadius,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
    ).build(size);
  }

  @override
  bool shouldReclip(covariant _BubbleClipper oldClipper) {
    return oldClipper.direction != direction ||
        oldClipper.isStart != isStart ||
        oldClipper.offset != offset ||
        oldClipper.safeOffset != safeOffset ||
        oldClipper.triangleWidth != triangleWidth ||
        oldClipper.triangleHeight != triangleHeight ||
        oldClipper.triangleRadius != triangleRadius ||
        oldClipper.borderRadius != borderRadius ||
        oldClipper.borderWidth != borderWidth;
  }
}

class _BubblePathBuilder {
  const _BubblePathBuilder({
    required this.direction,
    required this.isStart,
    required this.offset,
    required this.safeOffset,
    required this.triangleWidth,
    required this.triangleHeight,
    required this.triangleRadius,
    required this.borderRadius,
    required this.borderWidth,
  });

  final TriangleDirection direction;
  final bool isStart;
  final Offset offset;
  final Offset safeOffset;
  final double triangleWidth;
  final double triangleHeight;
  final double triangleRadius;
  final BorderRadius borderRadius;
  final double borderWidth;

  Path build(Size size) {
    final rect = _bodyRect(size);
    final resolvedRadius = _resolveRadius(rect);
    switch (direction) {
      case TriangleDirection.top:
        return _topPath(rect, resolvedRadius);
      case TriangleDirection.bottom:
        return _bottomPath(rect, resolvedRadius);
      case TriangleDirection.left:
        return _leftPath(rect, resolvedRadius);
      case TriangleDirection.right:
        return _rightPath(rect, resolvedRadius);
    }
  }

  Rect _bodyRect(Size size) {
    final inset = borderWidth / 2;
    switch (direction) {
      case TriangleDirection.top:
        return Rect.fromLTRB(
          inset,
          triangleHeight + inset,
          size.width - inset,
          size.height - inset,
        );
      case TriangleDirection.bottom:
        return Rect.fromLTRB(
          inset,
          inset,
          size.width - inset,
          size.height - triangleHeight - inset,
        );
      case TriangleDirection.left:
        return Rect.fromLTRB(
          triangleWidth + inset,
          inset,
          size.width - inset,
          size.height - inset,
        );
      case TriangleDirection.right:
        return Rect.fromLTRB(
          inset,
          inset,
          size.width - triangleWidth - inset,
          size.height - inset,
        );
    }
  }

  BorderRadius _resolveRadius(Rect rect) {
    final maxRadius = math.max(0.0, math.min(rect.width, rect.height) / 2);
    return BorderRadius.only(
      topLeft: _clampRadius(borderRadius.topLeft, maxRadius),
      topRight: _clampRadius(borderRadius.topRight, maxRadius),
      bottomRight: _clampRadius(borderRadius.bottomRight, maxRadius),
      bottomLeft: _clampRadius(borderRadius.bottomLeft, maxRadius),
    );
  }

  Radius _clampRadius(Radius radius, double maxRadius) {
    return Radius.elliptical(
      radius.x.clamp(0, maxRadius),
      radius.y.clamp(0, maxRadius),
    );
  }

  Path _topPath(Rect rect, BorderRadius radius) {
    final arrowCenter = _verticalArrowCenter(rect);
    final halfWidth = triangleWidth / 2;
    final leftBase = (arrowCenter - halfWidth).clamp(
      rect.left + radius.topLeft.x,
      rect.right - radius.topRight.x,
    );
    final rightBase = (arrowCenter + halfWidth).clamp(
      rect.left + radius.topLeft.x,
      rect.right - radius.topRight.x,
    );
    final tip = Offset(arrowCenter.clamp(leftBase, rightBase), borderWidth / 2);
    final path = Path()
      ..moveTo(rect.left + radius.topLeft.x, rect.top)
      ..lineTo(leftBase, rect.top);
    _addTriangle(
      path,
      Offset(leftBase, rect.top),
      tip,
      Offset(rightBase, rect.top),
    );
    path
      ..lineTo(rect.right - radius.topRight.x, rect.top)
      ..quadraticBezierTo(
        rect.right,
        rect.top,
        rect.right,
        rect.top + radius.topRight.y,
      )
      ..lineTo(rect.right, rect.bottom - radius.bottomRight.y)
      ..quadraticBezierTo(
        rect.right,
        rect.bottom,
        rect.right - radius.bottomRight.x,
        rect.bottom,
      )
      ..lineTo(rect.left + radius.bottomLeft.x, rect.bottom)
      ..quadraticBezierTo(
        rect.left,
        rect.bottom,
        rect.left,
        rect.bottom - radius.bottomLeft.y,
      )
      ..lineTo(rect.left, rect.top + radius.topLeft.y)
      ..quadraticBezierTo(
        rect.left,
        rect.top,
        rect.left + radius.topLeft.x,
        rect.top,
      )
      ..close();
    return path;
  }

  Path _bottomPath(Rect rect, BorderRadius radius) {
    final arrowCenter = _verticalArrowCenter(rect);
    final halfWidth = triangleWidth / 2;
    final leftBase = (arrowCenter - halfWidth).clamp(
      rect.left + radius.bottomLeft.x,
      rect.right - radius.bottomRight.x,
    );
    final rightBase = (arrowCenter + halfWidth).clamp(
      rect.left + radius.bottomLeft.x,
      rect.right - radius.bottomRight.x,
    );
    final tip = Offset(
      arrowCenter.clamp(leftBase, rightBase),
      rect.bottom + triangleHeight,
    );
    final path = Path()
      ..moveTo(rect.left + radius.topLeft.x, rect.top)
      ..lineTo(rect.right - radius.topRight.x, rect.top)
      ..quadraticBezierTo(
        rect.right,
        rect.top,
        rect.right,
        rect.top + radius.topRight.y,
      )
      ..lineTo(rect.right, rect.bottom - radius.bottomRight.y)
      ..quadraticBezierTo(
        rect.right,
        rect.bottom,
        rect.right - radius.bottomRight.x,
        rect.bottom,
      )
      ..lineTo(rightBase, rect.bottom);
    _addTriangle(
      path,
      Offset(rightBase, rect.bottom),
      tip,
      Offset(leftBase, rect.bottom),
    );
    path
      ..lineTo(rect.left + radius.bottomLeft.x, rect.bottom)
      ..quadraticBezierTo(
        rect.left,
        rect.bottom,
        rect.left,
        rect.bottom - radius.bottomLeft.y,
      )
      ..lineTo(rect.left, rect.top + radius.topLeft.y)
      ..quadraticBezierTo(
        rect.left,
        rect.top,
        rect.left + radius.topLeft.x,
        rect.top,
      )
      ..close();
    return path;
  }

  Path _leftPath(Rect rect, BorderRadius radius) {
    final arrowCenter = _horizontalArrowCenter(rect);
    final halfHeight = triangleHeight / 2;
    final topBase = (arrowCenter - halfHeight).clamp(
      rect.top + radius.topLeft.y,
      rect.bottom - radius.bottomLeft.y,
    );
    final bottomBase = (arrowCenter + halfHeight).clamp(
      rect.top + radius.topLeft.y,
      rect.bottom - radius.bottomLeft.y,
    );
    final tip = Offset(borderWidth / 2, arrowCenter.clamp(topBase, bottomBase));
    final path = Path()
      ..moveTo(rect.left + radius.topLeft.x, rect.top)
      ..lineTo(rect.right - radius.topRight.x, rect.top)
      ..quadraticBezierTo(
        rect.right,
        rect.top,
        rect.right,
        rect.top + radius.topRight.y,
      )
      ..lineTo(rect.right, rect.bottom - radius.bottomRight.y)
      ..quadraticBezierTo(
        rect.right,
        rect.bottom,
        rect.right - radius.bottomRight.x,
        rect.bottom,
      )
      ..lineTo(rect.left + radius.bottomLeft.x, rect.bottom)
      ..quadraticBezierTo(
        rect.left,
        rect.bottom,
        rect.left,
        rect.bottom - radius.bottomLeft.y,
      )
      ..lineTo(rect.left, bottomBase);
    _addTriangle(
      path,
      Offset(rect.left, bottomBase),
      tip,
      Offset(rect.left, topBase),
    );
    path
      ..lineTo(rect.left, rect.top + radius.topLeft.y)
      ..quadraticBezierTo(
        rect.left,
        rect.top,
        rect.left + radius.topLeft.x,
        rect.top,
      )
      ..close();
    return path;
  }

  Path _rightPath(Rect rect, BorderRadius radius) {
    final arrowCenter = _horizontalArrowCenter(rect);
    final halfHeight = triangleHeight / 2;
    final topBase = (arrowCenter - halfHeight).clamp(
      rect.top + radius.topRight.y,
      rect.bottom - radius.bottomRight.y,
    );
    final bottomBase = (arrowCenter + halfHeight).clamp(
      rect.top + radius.topRight.y,
      rect.bottom - radius.bottomRight.y,
    );
    final tip = Offset(
      rect.right + triangleWidth,
      arrowCenter.clamp(topBase, bottomBase),
    );
    final path = Path()
      ..moveTo(rect.left + radius.topLeft.x, rect.top)
      ..lineTo(rect.right - radius.topRight.x, rect.top)
      ..quadraticBezierTo(
        rect.right,
        rect.top,
        rect.right,
        rect.top + radius.topRight.y,
      )
      ..lineTo(rect.right, topBase);
    _addTriangle(
      path,
      Offset(rect.right, topBase),
      tip,
      Offset(rect.right, bottomBase),
    );
    path
      ..lineTo(rect.right, rect.bottom - radius.bottomRight.y)
      ..quadraticBezierTo(
        rect.right,
        rect.bottom,
        rect.right - radius.bottomRight.x,
        rect.bottom,
      )
      ..lineTo(rect.left + radius.bottomLeft.x, rect.bottom)
      ..quadraticBezierTo(
        rect.left,
        rect.bottom,
        rect.left,
        rect.bottom - radius.bottomLeft.y,
      )
      ..lineTo(rect.left, rect.top + radius.topLeft.y)
      ..quadraticBezierTo(
        rect.left,
        rect.top,
        rect.left + radius.topLeft.x,
        rect.top,
      )
      ..close();
    return path;
  }

  double _verticalArrowCenter(Rect rect) {
    final horizontalEdgeSpacing = triangleHeight / 2;
    final center = isStart
        ? math.max(rect.left + horizontalEdgeSpacing, rect.left - offset.dx)
        : rect.right - math.max(horizontalEdgeSpacing, offset.dx);
    return (center - safeOffset.dx).clamp(rect.left, rect.right);
  }

  double _horizontalArrowCenter(Rect rect) {
    final halfHeight = triangleHeight / 2;
    final center = isStart
        ? math.max(rect.top + halfHeight, rect.top - offset.dy)
        : rect.bottom - math.max(halfHeight, offset.dy);
    return (center - safeOffset.dy).clamp(rect.top, rect.bottom);
  }

  void _addTriangle(Path path, Offset start, Offset tip, Offset end) {
    final radius = triangleRadius.clamp(
      0.0,
      _maxTriangleRadius(start, tip, end),
    );
    if (radius == 0) {
      path
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(end.dx, end.dy);
      return;
    }
    final startRound = _pointOnLine(tip, start, radius);
    final endRound = _pointOnLine(tip, end, radius);
    path
      ..lineTo(startRound.dx, startRound.dy)
      ..quadraticBezierTo(tip.dx, tip.dy, endRound.dx, endRound.dy)
      ..lineTo(end.dx, end.dy);
  }

  Offset _pointOnLine(Offset from, Offset to, double distance) {
    final vector = to - from;
    final length = vector.distance;
    if (length == 0) {
      return from;
    }
    return from + vector / length * math.min(distance, length / 2);
  }

  double _maxTriangleRadius(Offset a, Offset b, Offset c) {
    return math.min((a - b).distance, (c - b).distance) / 2;
  }
}

BorderRadius _borderRadius(BorderRadiusGeometry? borderRadius) {
  return borderRadius?.resolve(TextDirection.ltr) ?? BorderRadius.zero;
}

double _borderWidth(BoxBorder? border) {
  if (border is! Border) {
    return 0;
  }
  final side = _uniformBorderSide(border);
  if (side == null || side.style == BorderStyle.none) {
    return 0;
  }
  return side.width;
}

BorderSide? _uniformBorderSide(Border border) {
  final top = border.top;
  if (border.right == top && border.bottom == top && border.left == top) {
    return top;
  }
  return null;
}

class Triangle extends StatelessWidget {
  final TriangleDirection direction;
  final double width;
  final double height;
  final double radius;
  final Color color;

  const Triangle({
    super.key,
    required this.direction,
    required this.width,
    required this.height,
    this.radius = 0,
    this.color = Colors.black,
  }) : assert(width > 0),
       assert(height > 0),
       assert(radius >= 0);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _TrianglePainter(
        direction: direction,
        radius: radius,
        color: color,
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({
    required this.direction,
    required this.radius,
    required this.color,
  });

  final TriangleDirection direction;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final points = _points(size);
    final path = radius <= 0
        ? _sharpPath(points)
        : _roundedPath(points, radius.clamp(0, _maxRadius(points)));
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawPath(path, paint);
  }

  List<Offset> _points(Size size) {
    switch (direction) {
      case TriangleDirection.top:
        return [
          Offset(size.width / 2, 0),
          Offset(size.width, size.height),
          Offset(0, size.height),
        ];
      case TriangleDirection.bottom:
        return [
          Offset(0, 0),
          Offset(size.width, 0),
          Offset(size.width / 2, size.height),
        ];
      case TriangleDirection.left:
        return [
          Offset(0, size.height / 2),
          Offset(size.width, 0),
          Offset(size.width, size.height),
        ];
      case TriangleDirection.right:
        return [
          Offset(0, 0),
          Offset(size.width, size.height / 2),
          Offset(0, size.height),
        ];
    }
  }

  Path _sharpPath(List<Offset> points) {
    return Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..close();
  }

  Path _roundedPath(List<Offset> points, double radius) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final previous = points[(i + points.length - 1) % points.length];
      final next = points[(i + 1) % points.length];
      final start = _pointOnLine(current, previous, radius);
      final end = _pointOnLine(current, next, radius);
      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
    }
    return path..close();
  }

  Offset _pointOnLine(Offset from, Offset to, double distance) {
    final vector = to - from;
    final length = vector.distance;
    if (length == 0) {
      return from;
    }
    return from + vector / length * math.min(distance, length / 2);
  }

  double _maxRadius(List<Offset> points) {
    var shortest = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      shortest = math.min(shortest, (next - current).distance);
    }
    return shortest / 2;
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color;
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_oldSize == newSize) {
      return;
    }
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}
