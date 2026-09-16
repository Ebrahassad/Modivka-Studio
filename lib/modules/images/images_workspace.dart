import 'package:flutter/material.dart';

import '../../core/models/workspace_item.dart';
import '../../widgets/item_strip.dart';
import '../../widgets/tool_bar.dart';

class ImagesWorkspace extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final current =
        items.isNotEmpty && selectedIndex >= 0 && selectedIndex < items.length
            ? items[selectedIndex]
            : null;

    return Column(
      children: [
        ModivkaToolBar(
          tools: [
            ToolDefinition(
              icon: Icons.add_photo_alternate_outlined,
              name: 'Add Image',
              onPressed: onAddImage,
            ),
            ToolDefinition(
              icon: Icons.layers_outlined,
              name: 'Add Image / Logo Layer',
              onPressed: onAddLayer,
            ),
            const ToolDefinition(icon: Icons.content_cut_rounded, name: 'Crop'),
            const ToolDefinition(
              icon: Icons.rotate_right_rounded,
              name: 'Rotate',
            ),
            const ToolDefinition(icon: Icons.flip_rounded, name: 'Flip'),
            const ToolDefinition(icon: Icons.zoom_in_rounded, name: 'Zoom In'),
            const ToolDefinition(
              icon: Icons.zoom_out_rounded,
              name: 'Zoom Out',
            ),
            const ToolDefinition(icon: Icons.opacity_rounded, name: 'Opacity'),
            const ToolDefinition(
              icon: Icons.auto_fix_high_rounded,
              name: 'Remove Background',
            ),
            const ToolDefinition(
              icon: Icons.photo_size_select_large_outlined,
              name: 'Resize',
            ),
            const ToolDefinition(
              icon: Icons.wb_sunny_outlined,
              name: 'Brightness',
            ),
            const ToolDefinition(
              icon: Icons.contrast_rounded,
              name: 'Contrast',
            ),
            const ToolDefinition(
              icon: Icons.palette_outlined,
              name: 'Color / Saturation',
            ),
            const ToolDefinition(
              icon: Icons.filter_vintage_outlined,
              name: 'Filters',
            ),
            const ToolDefinition(icon: Icons.undo_rounded, name: 'Undo'),
            const ToolDefinition(icon: Icons.redo_rounded, name: 'Redo'),
          ],
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child:
                current == null ? _emptyState(context) : _imageState(current),
          ),
        ),
        const Divider(height: 1),
        ItemStrip(
          items: items,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onAddImage,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Open Image'),
      ),
    );
  }

  Widget _imageState(WorkspaceItem item) {
    if (item.bytes == null) {
      return Center(
        child: Text(
          item.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Center(
      child: InteractiveViewer(
        minScale: 0.25,
        maxScale: 6,
        child: Image.memory(item.bytes!, fit: BoxFit.contain),
      ),
    );
  }
}
