import 'package:flutter/material.dart';

import '../core/models/canvas_layer.dart';

class ImageCanvas extends StatefulWidget {
  final List<CanvasLayer> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<Offset>? onMove;

  const ImageCanvas({
    super.key,
    required this.layers,
    required this.selectedIndex,
    required this.onSelected,
    this.onMove,
  });

  @override
  State<ImageCanvas> createState() => _ImageCanvasState();
}

class _ImageCanvasState extends State<ImageCanvas> {
  Offset? _dragStart;
  double? _startX;
  double? _startY;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF15151D),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CheckerboardPainter(),
                ),
              ),
              for (int index = 0; index < widget.layers.length; index++)
                _buildLayer(widget.layers[index], index),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLayer(CanvasLayer layer, int index) {
    if (!layer.visible) {
      return const SizedBox.shrink();
    }

    final selected = index == widget.selectedIndex;

    return Positioned(
      left: layer.x,
      top: layer.y,
      width: layer.width,
      height: layer.height,
      child: GestureDetector(
        onTap: () => widget.onSelected(index),
        onPanStart: selected && !layer.locked
            ? (details) {
                _dragStart = details.globalPosition;
                _startX = layer.x;
                _startY = layer.y;
              }
            : null,
        onPanUpdate: selected && !layer.locked
            ? (details) {
                if (_dragStart == null || _startX == null || _startY == null) {
                  return;
                }

                final delta = details.globalPosition - _dragStart!;

                setState(() {
                  layer.x = _startX! + delta.dx;
                  layer.y = _startY! + delta.dy;
                });

                widget.onMove?.call(delta);
              }
            : null,
        onPanEnd: selected && !layer.locked
            ? (_) {
                _dragStart = null;
                _startX = null;
                _startY = null;
              }
            : null,
        child: Transform.rotate(
          angle: layer.rotation,
          child: Opacity(
            opacity: layer.opacity.clamp(0.0, 1.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: _layerContent(layer),
                ),
                if (selected)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (selected) ..._buildHandles(layer),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHandles(CanvasLayer layer) {
    const size = 12.0;

    Widget handle({
      required double? left,
      required double? right,
      required double? top,
      required double? bottom,
    }) {
      return Positioned(
        left: left,
        right: right,
        top: top,
        bottom: bottom,
        child: IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.black,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }

    return [
      handle(
        left: -6,
        top: -6,
        right: null,
        bottom: null,
      ),
      handle(
        left: null,
        top: -6,
        right: -6,
        bottom: null,
      ),
      handle(
        left: -6,
        top: null,
        right: null,
        bottom: -6,
      ),
      handle(
        left: null,
        top: null,
        right: -6,
        bottom: -6,
      ),
    ];
  }

  Widget _layerContent(CanvasLayer layer) {
    if (layer.type == LayerType.text) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Text(
          layer.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (layer.bytes == null) {
      return const Center(
        child: Icon(
          Icons.image_outlined,
          size: 42,
          color: Colors.white54,
        ),
      );
    }

    return Image.memory(
      layer.bytes!,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
          ),
        );
      },
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 16.0;

    final light = Paint()..color = const Color(0xFF25252E);

    final dark = Paint()..color = const Color(0xFF1D1D25);

    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final even = ((x / cell).floor() + (y / cell).floor()) % 2 == 0;

        canvas.drawRect(
          Rect.fromLTWH(x, y, cell, cell),
          even ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
