import 'dart:math' as math;
import 'package:flutter/material.dart';

class TransformHandles extends StatelessWidget {
  final Rect rect;
  final double rotation;
  final bool locked;
  final ValueChanged<Offset>? onMove;
  final ValueChanged<Offset>? onResize;
  final ValueChanged<double>? onRotate;

  const TransformHandles({
    super.key,
    required this.rect,
    required this.rotation,
    required this.locked,
    this.onMove,
    this.onResize,
    this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return IgnorePointer(
        child: CustomPaint(
          size: Size(rect.width + 20, rect.height + 20),
          painter: _TransformPainter(
            rect: Rect.fromLTWH(10, 10, rect.width, rect.height),
            rotation: rotation,
            locked: true,
          ),
        ),
      );
    }

    return Positioned(
      left: rect.left - 10,
      top: rect.top - 10,
      width: rect.width + 20,
      height: rect.height + 70,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) {
          onMove?.call(details.delta);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: Size(rect.width + 20, rect.height + 20),
              painter: _TransformPainter(
                rect: Rect.fromLTWH(10, 10, rect.width, rect.height),
                rotation: rotation,
                locked: false,
              ),
            ),
            _handle(
              Alignment.topLeft,
              (details) => onResize?.call(
                Offset(-details.delta.dx, -details.delta.dy),
              ),
            ),
            _handle(
              Alignment.topRight,
              (details) => onResize?.call(
                Offset(details.delta.dx, -details.delta.dy),
              ),
            ),
            _handle(
              Alignment.bottomLeft,
              (details) => onResize?.call(
                Offset(-details.delta.dx, details.delta.dy),
              ),
            ),
            _handle(
              Alignment.bottomRight,
              (details) => onResize?.call(
                Offset(details.delta.dx, details.delta.dy),
              ),
            ),
            Positioned(
              top: -34,
              left: rect.width / 2 - 11,
              child: GestureDetector(
                onPanUpdate: (details) {
                  onRotate?.call(details.delta.dx);
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    color: Colors.blueAccent,
                  ),
                  child: const Icon(
                    Icons.rotate_right,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _handle(
    Alignment alignment,
    GestureDragUpdateCallback onPanUpdate,
  ) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: onPanUpdate,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.blueAccent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _TransformPainter extends CustomPainter {
  final Rect rect;
  final double rotation;
  final bool locked;

  const _TransformPainter({
    required this.rect,
    required this.rotation,
    required this.locked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = rect.center;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = locked ? Colors.grey : Colors.blueAccent;

    canvas.drawRect(rect, paint);

    final linePaint = Paint()
      ..strokeWidth = 1
      ..color = locked ? Colors.grey : Colors.blueAccent;

    canvas.drawLine(
      Offset(center.dx, rect.top),
      Offset(center.dx, rect.top - 24),
      linePaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TransformPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.rotation != rotation ||
        oldDelegate.locked != locked;
  }
}

double normalizeAngle(double angle) {
  while (angle > math.pi) {
    angle -= math.pi * 2;
  }

  while (angle < -math.pi) {
    angle += math.pi * 2;
  }

  return angle;
}
