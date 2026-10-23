import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Round outline thumbs-up like soft cuff+fist reference (not Material glyph).
class FriendlyThumbPainter extends CustomPainter {
  FriendlyThumbPainter({
    required this.color,
    this.down = false,
  });

  final Color color;
  final bool down;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    if (down) {
      canvas.rotate(math.pi);
    }
    canvas.translate(-s / 2, -s / 2);
    canvas.scale(s / 100);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Cuff
    final cuff = RRect.fromRectAndRadius(
      const Rect.fromLTWH(5, 36, 24, 46),
      const Radius.circular(9),
    );
    canvas.drawRRect(cuff, stroke);
    canvas.drawCircle(
      const Offset(17, 70),
      3.4,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Hand outer silhouette
    final hand = Path()
      ..moveTo(31, 50)
      ..cubicTo(31, 38, 33, 20, 39, 11)
      ..cubicTo(43, 4, 54, 4, 58, 12)
      ..cubicTo(62, 20, 60, 34, 57, 42)
      ..cubicTo(64, 39, 74, 38, 78, 45)
      ..cubicTo(84, 50, 86, 56, 81, 60)
      ..cubicTo(88, 63, 90, 70, 85, 74)
      ..cubicTo(91, 78, 89, 86, 80, 87)
      ..cubicTo(68, 90, 46, 88, 34, 79)
      ..cubicTo(29, 74, 28, 62, 31, 50)
      ..close();
    canvas.drawPath(hand, stroke);

    // Groove between thumb and fist
    final groove = Path()
      ..moveTo(49, 42)
      ..cubicTo(51, 49, 49, 56, 44, 60);
    canvas.drawPath(groove, stroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FriendlyThumbPainter old) =>
      old.color != color || old.down != down;
}

/// 认识: friendly thumb flies to screen center, pauses, returns.
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

    final origin = box.localToGlobal(box.size.center(Offset.zero));
    final screen = MediaQuery.sizeOf(context);
    final dest = Offset(screen.width / 2, screen.height * 0.42);

    late final OverlayEntry entry;
    final done = Completer<void>();
    entry = OverlayEntry(
      builder: (ctx) => _ThumbFlightOverlay(
        color: widget.color,
        start: origin,
        end: dest,
        startSize: widget.iconSize,
        endSize: widget.iconSize * 2.35,
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
                    child: CustomPaint(
                      key: const ValueKey('learn_known_thumb_xform'),
                      painter: FriendlyThumbPainter(color: widget.color),
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
  /// 0 at button, 1 at center. Hold while peak runs, then animate back.
  double _u = 0;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    _c.addListener(() {
      if (!mounted || _holding) return;
      setState(() {
        _u = Curves.easeInOutCubic.transform(_c.value);
      });
    });
    await _c.forward();
    if (!mounted) return;
    setState(() {
      _u = 1;
      _holding = true;
    });
    // Brief pause at center, then fire learn.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    try {
      await widget.onPeak();
    } catch (_) {}
    if (!mounted) return;
    // Extra beat so the big thumb is readable
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    setState(() => _holding = false);
    _c.value = 0;
    _c.addListener(() {
      if (!mounted || _holding) return;
      setState(() {
        _u = 1.0 - Curves.easeInOutCubic.transform(_c.value);
      });
    });
    await _c.forward(from: 0);
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
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
              child: CustomPaint(
                painter: FriendlyThumbPainter(color: widget.color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
