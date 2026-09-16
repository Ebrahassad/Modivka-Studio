import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/models/canvas_layer.dart';
import 'transform_handles.dart';

class ImageCanvas extends StatefulWidget {
  final List<CanvasLayer> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Offset> onResize;
  final ValueChanged<double> onRotate;

  const ImageCanvas({
    super.key,
    required this.layers,
    required this.selectedIndex,
    required this.onSelected,
    required this.onMove,
    required this.onResize,
    required this.onRotate,
  });

  @override
  State<ImageCanvas> createState() => _ImageCanvasState();
}

class _ImageCanvasState extends State<ImageCanvas> {
  final TransformationController _controller = TransformationController();

  double _zoom = 1.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateZoom(double value) {
    final zoom = value.clamp(0.25, 4.0);

    setState(() {
      _zoom = zoom;
      _controller.value = Matrix4.identity()
        ..scaleByDouble(zoom, zoom, zoom, 1.0);
    });
  }

  void _resetView() {
    setState(() {
      _zoom = 1.0;
      _controller.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF17191F),
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _controller,
              minScale: 0.25,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(1000),
              constrained: false,
              panEnabled: true,
              scaleEnabled: true,
              child: _CanvasSurface(
                layers: widget.layers,
                selectedIndex: widget.selectedIndex,
                onSelected: widget.onSelected,
                onMove: widget.onMove,
                onResize: widget.onResize,
                onRotate: widget.onRotate,
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: _ZoomControls(
              zoom: _zoom,
              onZoomChanged: _updateZoom,
              onReset: _resetView,
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasSurface extends StatelessWidget {
  final List<CanvasLayer> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Offset> onResize;
  final ValueChanged<double> onRotate;

  static const double canvasWidth = 1200;
  static const double canvasHeight = 800;
  static const double guideThreshold = 8;

  const _CanvasSurface({
    required this.layers,
    required this.selectedIndex,
    required this.onSelected,
    required this.onMove,
    required this.onResize,
    required this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1200,
      height: 800,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CanvasBackgroundPainter(),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                width: 1200,
                height: 800,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: const Color(0xFF8A8F98),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          for (var i = 0; i < layers.length; i++)
            _LayerWidget(
              key: ValueKey(layers[i].id),
              layer: layers[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
              onMove: onMove,
              onResize: onResize,
              onRotate: onRotate,
            ),
          if (selectedIndex >= 0 && selectedIndex < layers.length)
            _SmartGuides(
              layer: layers[selectedIndex],
              layers: layers,
              selectedIndex: selectedIndex,
              canvasWidth: canvasWidth,
              canvasHeight: canvasHeight,
              threshold: guideThreshold,
            ),
        ],
      ),
    );
  }
}

class _SmartGuides extends StatelessWidget {
  final CanvasLayer layer;
  final List<CanvasLayer> layers;
  final int selectedIndex;
  final double canvasWidth;
  final double canvasHeight;
  final double threshold;

  const _SmartGuides({
    required this.layer,
    required this.layers,
    required this.selectedIndex,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.threshold,
  });

  bool _near(double a, double b) => (a - b).abs() <= threshold;

  @override
  Widget build(BuildContext context) {
    final guides = <_GuideLine>[];

    final left = layer.x;
    final right = layer.x + layer.width;
    final top = layer.y;
    final bottom = layer.y + layer.height;
    final centerX = layer.x + layer.width / 2;
    final centerY = layer.y + layer.height / 2;

    if (_near(centerX, canvasWidth / 2)) {
      guides.add(
        _GuideLine.vertical(canvasWidth / 2),
      );
    }

    if (_near(centerY, canvasHeight / 2)) {
      guides.add(
        _GuideLine.horizontal(canvasHeight / 2),
      );
    }

    if (_near(left, 0)) {
      guides.add(_GuideLine.vertical(0));
    }

    if (_near(right, canvasWidth)) {
      guides.add(_GuideLine.vertical(canvasWidth));
    }

    if (_near(top, 0)) {
      guides.add(_GuideLine.horizontal(0));
    }

    if (_near(bottom, canvasHeight)) {
      guides.add(_GuideLine.horizontal(canvasHeight));
    }

    for (var i = 0; i < layers.length; i++) {
      if (i == selectedIndex) {
        continue;
      }

      final other = layers[i];

      if (!other.visible) {
        continue;
      }

      final otherLeft = other.x;
      final otherRight = other.x + other.width;
      final otherTop = other.y;
      final otherBottom = other.y + other.height;
      final otherCenterX = other.x + other.width / 2;
      final otherCenterY = other.y + other.height / 2;

      final xTargets = [
        otherLeft,
        otherCenterX,
        otherRight,
      ];

      final yTargets = [
        otherTop,
        otherCenterY,
        otherBottom,
      ];

      final xValues = [
        left,
        centerX,
        right,
      ];

      final yValues = [
        top,
        centerY,
        bottom,
      ];

      for (final x in xValues) {
        for (final target in xTargets) {
          if (_near(x, target)) {
            guides.add(_GuideLine.vertical(target));
            break;
          }
        }
      }

      for (final y in yValues) {
        for (final target in yTargets) {
          if (_near(y, target)) {
            guides.add(_GuideLine.horizontal(target));
            break;
          }
        }
      }
    }

    if (guides.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _SmartGuidePainter(
            guides: guides,
            width: canvasWidth,
            height: canvasHeight,
          ),
        ),
      ),
    );
  }
}

class _GuideLine {
  final Axis axis;
  final double position;

  const _GuideLine.vertical(this.position) : axis = Axis.vertical;

  const _GuideLine.horizontal(this.position) : axis = Axis.horizontal;
}

class _SmartGuidePainter extends CustomPainter {
  final List<_GuideLine> guides;
  final double width;
  final double height;

  const _SmartGuidePainter({
    required this.guides,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final guide in guides) {
      if (guide.axis == Axis.vertical) {
        canvas.drawLine(
          Offset(guide.position, 0),
          Offset(guide.position, height),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(0, guide.position),
          Offset(width, guide.position),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SmartGuidePainter oldDelegate) {
    return oldDelegate.guides.length != guides.length ||
        oldDelegate.guides.any(
          (guide) {
            return !oldDelegate.guides.contains(guide);
          },
        );
  }
}

class _LayerWidget extends StatelessWidget {
  final CanvasLayer layer;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Offset> onResize;
  final ValueChanged<double> onRotate;

  const _LayerWidget({
    super.key,
    required this.layer,
    required this.selected,
    required this.onTap,
    required this.onMove,
    required this.onResize,
    required this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    if (!layer.visible) {
      return const SizedBox.shrink();
    }

    final content = SizedBox(
      width: layer.width,
      height: layer.height,
      child: _LayerContent(layer: layer),
    );

    final selectionBorder = selected
        ? DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF5B8CFF),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x665B8CFF),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: content,
          )
        : content;

    return Positioned(
      left: layer.x,
      top: layer.y,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: layer.locked
            ? null
            : (details) {
                onTap();
                onMove(details.delta);
              },
        child: Transform.rotate(
          angle: layer.rotation,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              selectionBorder,
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: TransformHandles(
                      rect: Rect.fromLTWH(
                        0,
                        0,
                        layer.width,
                        layer.height,
                      ),
                      rotation: layer.rotation,
                      locked: layer.locked,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayerContent extends StatelessWidget {
  final CanvasLayer layer;

  const _LayerContent({
    required this.layer,
  });

  @override
  Widget build(BuildContext context) {
    if (layer.type == LayerType.text) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          layer.text.isEmpty ? layer.name : layer.text,
          textAlign: switch (layer.textAlignment) {
            TextAlignment.left => TextAlign.left,
            TextAlignment.center => TextAlign.center,
            TextAlignment.right => TextAlign.right,
          },
          style: TextStyle(
            color: Color(layer.textColor.value),
            fontSize: layer.fontSize,
            fontWeight: layer.bold ? FontWeight.w700 : FontWeight.w400,
            fontStyle: layer.italic ? FontStyle.italic : FontStyle.normal,
            fontFamily: layer.fontFamily,
            letterSpacing: layer.letterSpacing,
            height: layer.lineHeight,
            decoration: TextDecoration.combine([
              if (layer.underline) TextDecoration.underline,
              if (layer.strikethrough) TextDecoration.lineThrough,
            ]),
          ),
        ),
      );
    }

    final Uint8List? bytes = layer.bytes;

    if (bytes == null || bytes.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF30343B),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          color: Colors.white54,
          size: 48,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.memory(
        bytes,
        width: layer.width,
        height: layer.height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _CanvasBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    const grid = 32.0;
    paint
      ..color = const Color(0xFFE8E8E8)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += grid) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y <= size.height; y += grid) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    paint.color = const Color(0xFFF4F4F4);

    for (double x = 0; x < size.width; x += grid * 2) {
      for (double y = 0; y < size.height; y += grid * 2) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, grid, grid),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _ZoomControls extends StatelessWidget {
  final double zoom;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onReset;

  const _ZoomControls({
    required this.zoom,
    required this.onZoomChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xDD20242B),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Zoom out',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                onZoomChanged(zoom - 0.25);
              },
              icon: const Icon(
                Icons.remove,
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: 110,
              child: Slider(
                value: zoom,
                min: 0.25,
                max: 4.0,
                divisions: 15,
                onChanged: onZoomChanged,
              ),
            ),
            IconButton(
              tooltip: 'Zoom in',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                onZoomChanged(zoom + 0.25);
              },
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
            Text(
              '${(zoom * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              tooltip: 'Reset view',
              visualDensity: VisualDensity.compact,
              onPressed: onReset,
              icon: const Icon(
                Icons.fit_screen_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
