import 'package:flutter/material.dart';

import '../core/models/canvas_layer.dart';

class LayersStrip extends StatelessWidget {
  final List<CanvasLayer> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<int> onVisibilityChanged;
  final ValueChanged<int> onLockChanged;
  final VoidCallback onAdd;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onProperties;

  const LayersStrip({
    super.key,
    required this.layers,
    required this.selectedIndex,
    required this.onSelected,
    required this.onVisibilityChanged,
    required this.onLockChanged,
    required this.onAdd,
    required this.onDelete,
    required this.onDuplicate,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onProperties,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex >= 0 && selectedIndex < layers.length
        ? layers[selectedIndex]
        : null;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF11101A),
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(10)),
          bottom: BorderSide(color: Colors.white.withAlpha(14)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          PopupMenuButton<int>(
            tooltip: 'Layers',
            offset: const Offset(0, 58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: const Color(0xFF171526),
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                enabled: false,
                child: Row(
                  children: [
                    const Icon(Icons.layers_rounded, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Layers',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add layer',
                      onPressed: () {
                        Navigator.pop(context);
                        onAdd();
                      },
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
              if (layers.isEmpty)
                const PopupMenuItem<int>(
                  enabled: false,
                  child: Text('No layers'),
                ),
              ...List.generate(layers.length, (index) {
                final layer = layers[index];
                return PopupMenuItem<int>(
                  value: index,
                  child: _MenuLayerRow(
                    layer: layer,
                    selected: index == selectedIndex,
                    onVisibility: () => onVisibilityChanged(index),
                    onLock: () => onLockChanged(index),
                  ),
                );
              }),
              const PopupMenuDivider(),
              PopupMenuItem<int>(
                enabled: selected != null,
                onTap: onProperties,
                child: const Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 19),
                    SizedBox(width: 10),
                    Text('Layer properties'),
                  ],
                ),
              ),
            ],
            onSelected: onSelected,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: const Color(0xFF211C3A),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: const Color(0xFF6B5CFF).withAlpha(100)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.layers_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Layers',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
              itemCount: layers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final layer = layers[index];
                return _LayerChip(
                  layer: layer,
                  selected: index == selectedIndex,
                  onTap: () => onSelected(index),
                );
              },
            ),
          ),
          const VerticalDivider(width: 1, indent: 12, endIndent: 12),
          IconButton(
            tooltip: 'Layer properties',
            onPressed: selected == null ? null : onProperties,
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'Add layer',
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  final CanvasLayer layer;
  final bool selected;
  final VoidCallback onTap;

  const _LayerChip({
    required this.layer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF4C3BCB).withAlpha(150)
          : const Color(0xFF1A1925),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 142,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF7667FF)
                  : Colors.white.withAlpha(12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                layer.visible
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 17,
                color: layer.visible ? Colors.white : Colors.white38,
              ),
              const SizedBox(width: 7),
              _LayerIcon(layer: layer),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  layer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (layer.locked)
                const Icon(Icons.lock_rounded, size: 14, color: Colors.amber),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuLayerRow extends StatelessWidget {
  final CanvasLayer layer;
  final bool selected;
  final VoidCallback onVisibility;
  final VoidCallback onLock;

  const _MenuLayerRow({
    required this.layer,
    required this.selected,
    required this.onVisibility,
    required this.onLock,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          onPressed: onVisibility,
          icon: Icon(
            layer.visible
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            size: 18,
          ),
        ),
        _LayerIcon(layer: layer),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            layer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: selected ? FontWeight.w800 : null),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          onPressed: onLock,
          icon: Icon(
            layer.locked ? Icons.lock_rounded : Icons.lock_open_rounded,
            size: 17,
          ),
        ),
      ],
    );
  }
}

class _LayerIcon extends StatelessWidget {
  final CanvasLayer layer;

  const _LayerIcon({required this.layer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0C15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Icon(
        layer.type == LayerType.text
            ? Icons.text_fields_rounded
            : Icons.image_outlined,
        size: 18,
        color: Colors.white70,
      ),
    );
  }
}
