import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/models/canvas_layer.dart';
import 'transform_handles.dart';

class ImageCanvas extends StatelessWidget {
  final List<CanvasLayer> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Offset>? onResize;
  final ValueChanged<double>? onRotate;

  const ImageCanvas({
    super.key,
    required this.layers,
    required this.selectedIndex,
    required this.onSelected,
    required this.onMove,
    this.onResize,
    this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF17171B),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Container(
                  width: mathMin(constraints.maxWidth - 40, 900),
                  height: mathMin(constraints.maxHeight - 40, 650),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (int i = 0; i < layers.length; i++)
                        _buildLayer(
                          context,
                          layers[i],
                          i,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLayer(
    BuildContext context,
    CanvasLayer layer,
    int index,
  ) {
    if (!layer.visible) {
      return const SizedBox.shrink();
    }

    final selected = index == selectedIndex;

    final widget = Positioned(
      left: layer.x,
      top: layer.y,
      width: layer.width,
      height: layer.height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => onSelected(index),
        onPanStart: (_) => onSelected(index),
        onPanUpdate: layer.locked
            ? null
            : (details) {
                onSelected(index);
                onMove(details.delta);
              },
        child: Transform.rotate(
          angle: layer.rotation,
          child: Opacity(
            opacity: layer.opacity.clamp(0.0, 1.0),
            child: _layerContent(layer),
          ),
        ),
      ),
    );

    if (!selected) {
      return widget;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget,
        Positioned(
          left: layer.x,
          top: layer.y,
          width: layer.width,
          height: layer.height,
          child: TransformHandles(
            rect: Rect.fromLTWH(
              0,
              0,
              layer.width,
              layer.height,
            ),
            rotation: layer.rotation,
            locked: layer.locked,
            onMove: layer.locked ? null : onMove,
            onResize: layer.locked ? null : onResize,
            onRotate: layer.locked ? null : onRotate,
          ),
        ),
      ],
    );
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
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final Uint8List? bytes = layer.bytes;

    if (bytes == null || bytes.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border.all(
            color: Colors.grey.shade400,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ClipRect(
      child: Image.memory(
        bytes,
        fit: BoxFit.contain,
      ),
    );
  }
}

double mathMin(double a, double b) {
  return a < b ? a : b;
}
