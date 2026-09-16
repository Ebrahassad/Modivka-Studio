import 'package:flutter/material.dart';

import '../core/models/canvas_layer.dart';

class ImageCanvas extends StatelessWidget {
  final List<CanvasLayer> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<Offset> onMove;

  const ImageCanvas({
    super.key,
    required this.layers,
    required this.selectedIndex,
    required this.onSelected,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF08080C),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasWidth = constraints.maxWidth.clamp(280.0, 900.0);
            final canvasHeight = (canvasWidth * 0.72).clamp(220.0, 650.0);

            return Container(
              width: canvasWidth,
              height: canvasHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(90),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (int i = 0; i < layers.length; i++)
                    if (layers[i].visible)
                      _buildLayer(
                        context,
                        layers[i],
                        i,
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLayer(
    BuildContext context,
    CanvasLayer layer,
    int index,
  ) {
    final selected = index == selectedIndex;

    Widget content;

    if (layer.type == LayerType.image && layer.bytes != null) {
      content = Image.memory(
        layer.bytes!,
        fit: BoxFit.contain,
      );
    } else {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            layer.text.isEmpty ? layer.name : layer.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: layer.x,
      top: layer.y,
      width: layer.width,
      height: layer.height,
      child: GestureDetector(
        onTap: () => onSelected(index),
        onPanUpdate: layer.locked
            ? null
            : (details) {
                onMove(details.delta);
              },
        child: Opacity(
          opacity: layer.opacity,
          child: Transform.rotate(
            angle: layer.rotation,
            child: Container(
              decoration: selected
                  ? BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    )
                  : null,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
