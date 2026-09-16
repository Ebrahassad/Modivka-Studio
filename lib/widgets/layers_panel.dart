import 'package:flutter/material.dart';

import '../core/models/canvas_layer.dart';

class LayersPanel extends StatelessWidget {
  final List<CanvasLayer> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<int> onVisibilityChanged;
  final ValueChanged<int> onLockChanged;

  const LayersPanel({
    super.key,
    required this.layers,
    required this.selectedIndex,
    required this.onSelected,
    required this.onVisibilityChanged,
    required this.onLockChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        border: Border(
          left: BorderSide(
            color: Colors.white.withAlpha(18),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(Icons.layers_outlined, size: 19),
                SizedBox(width: 8),
                Text(
                  'Layers',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: layers.isEmpty
                ? const Center(
                    child: Text(
                      'No layers',
                      style: TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: layers.length,
                    itemBuilder: (context, index) {
                      final layer = layers[index];
                      final selected = index == selectedIndex;

                      return InkWell(
                        onTap: () => onSelected(index),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(45)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Visibility',
                                iconSize: 19,
                                onPressed: () => onVisibilityChanged(index),
                                icon: Icon(
                                  layer.visible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      layer.type == LayerType.image
                                          ? Icons.image_outlined
                                          : Icons.text_fields_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        layer.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Lock',
                                iconSize: 18,
                                onPressed: () => onLockChanged(index),
                                icon: Icon(
                                  layer.locked
                                      ? Icons.lock_outline
                                      : Icons.lock_open_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
