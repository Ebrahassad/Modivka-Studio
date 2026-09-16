import 'package:flutter/material.dart';

import '../../core/models/workspace_item.dart';
import '../../core/files/file_service.dart';
import '../../widgets/item_strip.dart';
import '../../widgets/tool_bar.dart';

class TextWorkspace extends StatefulWidget {
  final List<WorkspaceItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onOpen;

  const TextWorkspace({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onOpen,
  });

  @override
  State<TextWorkspace> createState() => _TextWorkspaceState();
}

class _TextWorkspaceState extends State<TextWorkspace> {
  final _fileService = const FileService();
  String? _content;

  @override
  void didUpdateWidget(covariant TextWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedIndex != oldWidget.selectedIndex ||
        widget.items.length != oldWidget.items.length) {
      _loadCurrent();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    if (widget.items.isEmpty ||
        widget.selectedIndex < 0 ||
        widget.selectedIndex >= widget.items.length) {
      setState(() {
        _content = null;
      });
      return;
    }

    final item = widget.items[widget.selectedIndex];

    String? content;

    if (item.path.isNotEmpty) {
      content = await _fileService.readText(item.path);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _content = content;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModivkaToolBar(
          tools: [
            ToolDefinition(
              icon: Icons.note_add_outlined,
              name: 'New Text',
              onPressed: () {},
            ),
            ToolDefinition(
              icon: Icons.folder_open_outlined,
              name: 'Open Text',
              onPressed: widget.onOpen,
            ),
            const ToolDefinition(icon: Icons.format_bold_rounded, name: 'Bold'),
            const ToolDefinition(
              icon: Icons.format_italic_rounded,
              name: 'Italic',
            ),
            const ToolDefinition(
              icon: Icons.format_align_left_rounded,
              name: 'Align',
            ),
            const ToolDefinition(icon: Icons.undo_rounded, name: 'Undo'),
            const ToolDefinition(icon: Icons.redo_rounded, name: 'Redo'),
          ],
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: widget.items.isEmpty
                ? Center(
                    child: FilledButton.icon(
                      onPressed: widget.onOpen,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Open Text File'),
                    ),
                  )
                : SingleChildScrollView(
                    child: SelectableText(
                      _content ?? widget.items[widget.selectedIndex].name,
                      style: const TextStyle(fontSize: 15, height: 1.6),
                    ),
                  ),
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
