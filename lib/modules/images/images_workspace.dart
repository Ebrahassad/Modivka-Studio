import 'package:flutter/material.dart';

import '../../core/models/canvas_layer.dart';
import '../../core/models/workspace_item.dart';
import '../../widgets/image_canvas.dart';
import '../../widgets/item_strip.dart';
import '../../widgets/layers_panel.dart';
import '../../widgets/tool_bar.dart';

class ImagesWorkspace extends StatefulWidget {
  final List<WorkspaceItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAddImage;
  final VoidCallback onAddLayer;

  const ImagesWorkspace({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onAddImage,
    required this.onAddLayer,
  });

  @override
  State<ImagesWorkspace> createState() => _ImagesWorkspaceState();
}

class _ImagesWorkspaceState extends State<ImagesWorkspace> {
  final List<CanvasLayer> _layers = [];
  int _selectedLayer = -1;

  @override
  void didUpdateWidget(
    covariant ImagesWorkspace oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.length != oldWidget.items.length) {
      _syncLayers();
    }
  }

  @override
  void initState() {
    super.initState();
    _syncLayers();
  }

  void _syncLayers() {
    for (final item in widget.items) {
      final exists = _layers.any(
        (layer) => layer.id == item.path && item.path.isNotEmpty,
      );

      if (!exists && item.bytes != null) {
        _layers.insert(
          0,
          CanvasLayer(
            id: item.path.isEmpty
                ? '${item.name}-${_layers.length}'
                : item.path,
            name: item.name,
            type: LayerType.image,
            bytes: item.bytes,
            x: 20,
            y: 20,
            width: 420,
            height: 300,
          ),
        );
      }
    }

    if (_layers.isNotEmpty && _selectedLayer < 0) {
      _selectedLayer = 0;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _moveSelected(Offset delta) {
    if (_selectedLayer < 0 || _selectedLayer >= _layers.length) {
      return;
    }

    final layer = _layers[_selectedLayer];

    if (layer.locked) {
      return;
    }

    setState(() {
      layer.x += delta.dx;
      layer.y += delta.dy;
    });
  }

  void _toggleVisibility(int index) {
    setState(() {
      _layers[index].visible = !_layers[index].visible;
    });
  }

  void _toggleLock(int index) {
    setState(() {
      _layers[index].locked = !_layers[index].locked;
    });
  }

  void _addTextLayer() {
    setState(() {
      _layers.insert(
        0,
        CanvasLayer(
          id: 'text-${DateTime.now().microsecondsSinceEpoch}',
          name: 'Text Layer',
          type: LayerType.text,
          x: 50,
          y: 50,
          width: 300,
          height: 90,
        ),
      );
      _selectedLayer = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModivkaToolBar(
          tools: [
            ToolDefinition(
              icon: Icons.add_photo_alternate_outlined,
              name: 'Add Image',
              onPressed: widget.onAddImage,
            ),
            ToolDefinition(
              icon: Icons.layers_outlined,
              name: 'Add Image Layer',
              onPressed: widget.onAddLayer,
            ),
            ToolDefinition(
              icon: Icons.text_fields_rounded,
              name: 'Add Text Layer',
              onPressed: _addTextLayer,
            ),
            const ToolDefinition(
              icon: Icons.content_cut_rounded,
              name: 'Crop',
            ),
            const ToolDefinition(
              icon: Icons.rotate_right_rounded,
              name: 'Rotate',
            ),
            const ToolDefinition(
              icon: Icons.flip_rounded,
              name: 'Flip',
            ),
            const ToolDefinition(
              icon: Icons.zoom_in_rounded,
              name: 'Zoom In',
            ),
            const ToolDefinition(
              icon: Icons.zoom_out_rounded,
              name: 'Zoom Out',
            ),
            const ToolDefinition(
              icon: Icons.auto_fix_high_rounded,
              name: 'Remove Background',
            ),
            const ToolDefinition(
              icon: Icons.undo_rounded,
              name: 'Undo',
            ),
            const ToolDefinition(
              icon: Icons.redo_rounded,
              name: 'Redo',
            ),
          ],
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ImageCanvas(
                  layers: _layers,
                  selectedIndex: _selectedLayer,
                  onSelected: (index) {
                    setState(() {
                      _selectedLayer = index;
                    });
                  },
                  onMove: _moveSelected,
                ),
              ),
              LayersPanel(
                layers: _layers,
                selectedIndex: _selectedLayer,
                onSelected: (index) {
                  setState(() {
                    _selectedLayer = index;
                  });
                },
                onVisibilityChanged: _toggleVisibility,
                onLockChanged: _toggleLock,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ItemStrip(
          items: widget.items,
          selectedIndex: widget.selectedIndex,
          onSelected: widget.onSelected,
        ),
      ],
    );
  }
}
