import 'package:flutter/material.dart';

import '../core/models/canvas_layer.dart';

class LayersPanel extends StatelessWidget {
  final List<CanvasLayer> layers;
  final int selectedIndex;

  final ValueChanged<int> onSelected;
  final ValueChanged<int> onVisibilityChanged;
  final ValueChanged<int> onLockChanged;

  final VoidCallback? onAdd;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const LayersPanel({
    super.key,
    required this.layers,
    required this.selectedIndex,
    required this.onSelected,
    required this.onVisibilityChanged,
    required this.onLockChanged,
    this.onAdd,
    this.onDelete,
    this.onDuplicate,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLayer = selectedIndex >= 0 && selectedIndex < layers.length
        ? layers[selectedIndex]
        : null;

    return Container(
      width: 250,
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
          _buildHeader(context),
          const Divider(height: 1),
          _buildActions(context, selectedLayer),
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
                : _buildLayerList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(
              Icons.layers_outlined,
              size: 19,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Layers',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (onAdd != null)
              IconButton(
                tooltip: 'Add layer',
                iconSize: 20,
                onPressed: onAdd,
                icon: const Icon(
                  Icons.add_rounded,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    CanvasLayer? selectedLayer,
  ) {
    final hasSelection = selectedLayer != null;

    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionButton(
            tooltip: 'Move up',
            icon: Icons.keyboard_arrow_up_rounded,
            enabled: hasSelection && onMoveUp != null,
            onPressed: hasSelection && onMoveUp != null ? onMoveUp : null,
          ),
          _actionButton(
            tooltip: 'Move down',
            icon: Icons.keyboard_arrow_down_rounded,
            enabled: hasSelection && onMoveDown != null,
            onPressed: hasSelection && onMoveDown != null ? onMoveDown : null,
          ),
          _actionButton(
            tooltip: 'Duplicate',
            icon: Icons.copy_outlined,
            enabled: hasSelection && onDuplicate != null,
            onPressed: hasSelection && onDuplicate != null ? onDuplicate : null,
          ),
          _actionButton(
            tooltip: 'Delete',
            icon: Icons.delete_outline_rounded,
            enabled: hasSelection && onDelete != null,
            onPressed: hasSelection && onDelete != null ? onDelete : null,
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String tooltip,
    required IconData icon,
    required bool enabled,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      iconSize: 19,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
    );
  }

  Widget _buildLayerList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: layers.length,
      itemBuilder: (context, index) {
        final layer = layers[index];
        final selected = index == selectedIndex;

        return _buildLayerTile(
          context,
          layer,
          index,
          selected,
        );
      },
    );
  }

  Widget _buildLayerTile(
    BuildContext context,
    CanvasLayer layer,
    int index,
    bool selected,
  ) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: selected ? primary.withAlpha(48) : Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(index),
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: layer.visible ? 'Hide layer' : 'Show layer',
                  iconSize: 19,
                  onPressed: () => onVisibilityChanged(index),
                  icon: Icon(
                    layer.visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: layer.visible ? null : Colors.white38,
                  ),
                ),
                _thumbnail(layer),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        layer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        layer.type == LayerType.image ? 'Image' : 'Text',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: layer.locked ? 'Unlock layer' : 'Lock layer',
                  iconSize: 18,
                  onPressed: () => onLockChanged(index),
                  icon: Icon(
                    layer.locked
                        ? Icons.lock_outline
                        : Icons.lock_open_outlined,
                    color:
                        layer.locked ? Colors.amber.shade300 : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(CanvasLayer layer) {
    if (layer.type == LayerType.image && layer.bytes != null) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: Colors.white.withAlpha(25),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          layer.bytes!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const Icon(
              Icons.broken_image_outlined,
              size: 18,
            );
          },
        ),
      );
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.white.withAlpha(25),
        ),
      ),
      child: Icon(
        layer.type == LayerType.text
            ? Icons.text_fields_rounded
            : Icons.image_outlined,
        size: 19,
        color: Colors.white70,
      ),
    );
  }
}
