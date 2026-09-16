import 'package:flutter/material.dart';

import '../core/models/workspace_item.dart';

class ItemStrip extends StatelessWidget {
  final List<WorkspaceItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const ItemStrip({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox(
        height: 76,
        child: Center(
          child: Text('No items', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return SizedBox(
      height: 82,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white12,
                  width: selected ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _preview(item),
            ),
          );
        },
      ),
    );
  }

  Widget _preview(WorkspaceItem item) {
    if (item.type == WorkspaceType.image && item.bytes != null) {
      return Image.memory(
        item.bytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fileIcon(),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _fileIcon(),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9),
          ),
        ),
      ],
    );
  }

  Widget _fileIcon() {
    return const Icon(Icons.insert_drive_file_outlined, size: 26);
  }
}
