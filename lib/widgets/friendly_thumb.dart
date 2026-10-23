import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Solid thumbs-up (reference silhouette filled, tinted).
class FriendlyThumb extends StatelessWidget {
  const FriendlyThumb({
    super.key,
    required this.color,
    required this.size,
    this.down = false,
  });

  final Color color;
  final double size;
  final bool down;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        down
            ? 'assets/icons/thumb_down_friendly.png'
            : 'assets/icons/thumb_up_friendly.png',
        width: size,
        height: size,
        color: color,
        colorBlendMode: BlendMode.srcIn,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}

/// Kept for golden / CustomPaint call sites that still need a painter.
class FriendlyThumbPainter extends CustomPainter {
  FriendlyThumbPainter({
    required this.color,
    this.down = false,
  });

  final Color color;
  final bool down;

  @override
  void paint(Canvas canvas, Size size) {
    // Fallback outline if asset unavailable in tests without load — simple mark.
    final s = math.min(size.width, size.height);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    if (down) canvas.rotate(math.pi);
    canvas.translate(-s / 2, -s / 2);
    canvas.scale(s / 100);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 40, 20, 48),
        const Radius.circular(7),
      ),
      stroke,
    );
    canvas.drawCircle(const Offset(18, 75), 3.0, Paint()..color = color);
    final hand = Path()
      ..moveTo(32, 48)
      ..cubicTo(32, 36, 34, 18, 40, 10)
      ..cubicTo(44, 4, 54, 4, 58, 10)
      ..cubicTo(62, 16, 62, 30, 58, 38)
      ..cubicTo(66, 36, 76, 34, 82, 40)
      ..cubicTo(88, 44, 90, 50, 86, 54)
      ..cubicTo(92, 56, 94, 62, 90, 66)
      ..cubicTo(96, 70, 94, 78, 86, 82)
      ..cubicTo(74, 90, 48, 92, 34, 82)
      ..cubicTo(30, 76, 30, 60, 32, 48)
      ..close();
    canvas.drawPath(hand, stroke);
    canvas.drawPath(
      Path()
        ..moveTo(50, 40)
        ..cubicTo(52, 48, 50, 56, 46, 60),
      stroke,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FriendlyThumbPainter old) =>
      old.color != color || old.down != down;
}

class ElasticKnownThumbCta extends StatefulWidget {
  const ElasticKnownThumbCta({
    super.key,
    required this.enabled,
    required this.vertical,
    required this.iconSize,
    required this.color,
    required this.label,
    required this.onAction,
  });

  final bool enabled;
  final bool vertical;
  final double iconSize;
  final Color color;
  final String label;
  final Future<void> Function() onAction;

  @override
  State<ElasticKnownThumbCta> createState() => _ElasticKnownThumbCtaState();
}

class _ElasticKnownThumbCtaState extends State<ElasticKnownThumbCta> {
  final GlobalKey _anchorKey = GlobalKey();
  bool _busy = false;
  bool _hideLocal = false;

  Future<void> _play() async {
    if (!widget.enabled || _busy) return;
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayState = Overlay.maybeOf(context);
    if (box == null || !box.hasSize || overlayState == null) {
      await widget.onAction();
      return;
    }
    setState(() {
      _busy = true;
      _hideLocal = true;
    });

    // Map into Overlay local space so the peak lands on the true visual center.
    final overlayBox = overlayState.context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) {
      await widget.onAction();
      if (mounted) {
        setState(() {
          _busy = false;
          _hideLocal = false;
        });
      }
      return;
    }
    final originGlobal = box.localToGlobal(box.size.center(Offset.zero));
    final origin = overlayBox.globalToLocal(originGlobal);
    final dest = overlayBox.size.center(Offset.zero);
    final peakSize = (overlayBox.size.shortestSide * 0.42)
        .clamp(widget.iconSize * 2.8, widget.iconSize * 4.2);

    late final OverlayEntry entry;
    final done = Completer<void>();
    entry = OverlayEntry(
      builder: (ctx) => _ThumbFlightOverlay(
        color: widget.color,
        start: origin,
        end: dest,
        startSize: widget.iconSize,
        endSize: peakSize,
        onPeak: () => widget.onAction(),
        onDone: () {
          entry.remove();
          if (!done.isCompleted) done.complete();
        },
      ),
    );
    overlayState.insert(entry);
    await done.future;
    if (mounted) {
      setState(() {
        _busy = false;
        _hideLocal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !_busy;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? _play : null,
        borderRadius: BorderRadius.circular(24),
        splashColor: widget.color.withValues(alpha: 0.14),
        highlightColor: widget.color.withValues(alpha: 0.05),
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.4,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: widget.vertical ? 12 : 8,
              horizontal: 8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _hideLocal ? 0 : 1,
                  child: SizedBox(
                    key: _anchorKey,
                    width: widget.iconSize,
                    height: widget.iconSize,
                    child: FriendlyThumb(
                      key: const ValueKey('learn_known_thumb_xform'),
                      color: widget.color,
                      size: widget.iconSize,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbFlightOverlay extends StatefulWidget {
  const _ThumbFlightOverlay({
    required this.color,
    required this.start,
    required this.end,
    required this.startSize,
    required this.endSize,
    required this.onPeak,
    required this.onDone,
  });

  final Color color;
  final Offset start;
  final Offset end;
  final double startSize;
  final double endSize;
  final Future<void> Function() onPeak;
  final VoidCallback onDone;

  @override
  State<_ThumbFlightOverlay> createState() => _ThumbFlightOverlayState();
}

class _ThumbFlightOverlayState extends State<_ThumbFlightOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  double _u = 0;
  bool _holding = false;
  VoidCallback? _tick;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    void listenOut() {
      if (!mounted || _holding) return;
      setState(() => _u = Curves.easeInOutCubic.transform(_c.value));
    }

    _tick = listenOut;
    _c.addListener(listenOut);
    await _c.forward();
    if (!mounted) return;
    setState(() {
      _u = 1;
      _holding = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 220));
    try {
      await widget.onPeak();
    } catch (_) {}
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    setState(() => _holding = false);
    _c.removeListener(listenOut);
    void listenBack() {
      if (!mounted || _holding) return;
      setState(() => _u = 1.0 - Curves.easeInOutCubic.transform(_c.value));
    }
    _tick = listenBack;
    _c.addListener(listenBack);
    await _c.forward(from: 0);
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    if (_tick != null) _c.removeListener(_tick!);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = Offset.lerp(widget.start, widget.end, _u)!;
    final size = lerpDouble(widget.startSize, widget.endSize, _u)!;
    final breath = _holding ? 1.0 : (1.0 + 0.04 * math.sin(_u * math.pi));
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: pos.dx - size / 2,
            top: pos.dy - size / 2,
            width: size,
            height: size,
            child: Transform.scale(
              scale: breath,
              child: FriendlyThumb(color: widget.color, size: size),
            ),
          ),
        ],
      ),
    );
  }
}
