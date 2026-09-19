import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/compression/compression_service.dart';
import '../../core/conversion/conversion_service.dart';
import '../../core/export/export_service.dart';
import '../../core/files/file_service.dart';
import '../../core/models/workspace_item.dart';
import '../../widgets/format_actions.dart';
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
  final _exportService = const ExportService();
  final _conversionService = const ConversionService();
  final _compressionService = CompressionService();
  final _editor = TextEditingController();
  final _focusNode = FocusNode();

  bool _wordWrap = true;
  bool _dirty = false;
  int _lastItemsLength = -1;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void didUpdateWidget(covariant TextWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex ||
        widget.items.length != _lastItemsLength) {
      _loadCurrent();
    }
  }

  Future<void> _loadCurrent() async {
    if (widget.items.isEmpty ||
        widget.selectedIndex < 0 ||
        widget.selectedIndex >= widget.items.length) {
      _editor.text = '';
      if (mounted) setState(() => _dirty = false);
      return;
    }

    _lastItemsLength = widget.items.length;

    final item = widget.items[widget.selectedIndex];
    final content = item.path.isNotEmpty
        ? await _fileService.readText(item.path)
        : item.bytes == null
            ? null
            : utf8.decode(item.bytes!, allowMalformed: true);

    if (!mounted) return;
    _editor.text = content ?? '';
    setState(() => _dirty = false);
  }

  Future<void> _saveAs() async {
    final name = widget.items.isNotEmpty &&
            widget.selectedIndex >= 0 &&
            widget.selectedIndex < widget.items.length
        ? widget.items[widget.selectedIndex].name
        : 'Modivka-text.txt';
    final config = await showFormatActionSheet(
      context,
      type: WorkspaceType.text,
      initialName: name,
      title: 'Save text as',
    );
    if (config == null) return;

    final result = await _exportService.saveBytes(
      bytes: Uint8List.fromList(utf8.encode(_editor.text)),
      fileName: '${config.fileName}.${config.format.extension}',
      mimeType: config.format.mimeType,
      allowedExtensions: [config.format.extension],
    );
    if (!mounted || result == null) return;
    setState(() => _dirty = false);
    _showSaved(result.fileName);
  }

  Future<void> _convert() async {
    if (widget.items.isEmpty ||
        widget.selectedIndex < 0 ||
        widget.selectedIndex >= widget.items.length) {
      return;
    }
    final item = widget.items[widget.selectedIndex];
    final config = await showFormatActionSheet(
      context,
      type: WorkspaceType.text,
      initialName: item.name,
      title: 'Convert text format',
    );
    if (config == null) return;

    final result = await _conversionService.convert(
      type: WorkspaceType.text,
      inputPath: item.path,
      inputBytes: Uint8List.fromList(utf8.encode(_editor.text)),
      outputExtension: config.format.extension,
      baseName: config.fileName,
    );

    if (!mounted) return;
    final saved = await _exportService.saveBytes(
      bytes: result.bytes,
      fileName: result.fileName,
      mimeType: config.format.mimeType,
      allowedExtensions: [config.format.extension],
    );
    if (!mounted || saved == null) return;
    _showSaved(saved.fileName);
  }

  Future<void> _compress() async {
    if (widget.items.isEmpty ||
        widget.selectedIndex < 0 ||
        widget.selectedIndex >= widget.items.length) {
      return;
    }
    final item = widget.items[widget.selectedIndex];
    if (item.path.isEmpty) {
      _showMessage('The current text file has no local path.');
      return;
    }
    final bytes = await _compressionService.zipFiles([item.path]);
    if (!mounted) return;
    final saved = await _exportService.saveBytes(
      bytes: bytes,
      fileName: '${_baseName(item.name)}.zip',
      mimeType: 'application/zip',
      allowedExtensions: const ['zip'],
    );
    if (!mounted || saved == null) return;
    _showSaved(saved.fileName);
  }

  void _newText() {
    setState(() {
      _editor.clear();
      _dirty = true;
    });
    _focusNode.requestFocus();
  }

  void _showSaved(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name saved successfully.')),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _baseName(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  @override
  void dispose() {
    _editor.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModivkaToolBar(
          tools: [
            ToolDefinition(
                icon: Icons.note_add_outlined,
                name: 'New',
                onPressed: _newText),
            ToolDefinition(
                icon: Icons.folder_open_outlined,
                name: 'Open',
                onPressed: widget.onOpen),
            ToolDefinition(
                icon: Icons.save_outlined, name: 'Save as', onPressed: _saveAs),
            ToolDefinition(
                icon: Icons.transform_rounded,
                name: 'Convert',
                onPressed: _convert),
            ToolDefinition(
                icon: Icons.compress_rounded,
                name: 'Compress',
                onPressed: _compress),
            ToolDefinition(
                icon: Icons.wrap_text_rounded,
                name: 'Word wrap',
                onPressed: () => setState(() => _wordWrap = !_wordWrap)),
            const ToolDefinition(icon: Icons.search_rounded, name: 'Find'),
            const ToolDefinition(icon: Icons.format_bold_rounded, name: 'Bold'),
            const ToolDefinition(
                icon: Icons.format_italic_rounded, name: 'Italic'),
          ],
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF080810),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x267B68FF)),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: TextField(
                    controller: _editor,
                    focusNode: _focusNode,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      height: 1.55,
                    ),
                    onChanged: (_) => setState(() => _dirty = true),
                    decoration: InputDecoration(
                      hintText: 'Type or paste your text here…',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 42),
                      isCollapsed: !_wordWrap,
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF171425),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withAlpha(14)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      child: Text(
                        '${_editor.text.length} chars${_dirty ? ' • edited' : ''}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white60),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ItemStrip(
          items: widget.items,
          selectedIndex: widget.selectedIndex,
          onSelected: widget.onSelected,
        ),
      ],
    );
  }
}
