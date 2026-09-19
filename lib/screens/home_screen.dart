import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/models/canvas_layer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<CanvasLayer> _layers = [];

  String? _selectedLayerId;
  String? _mainDocumentName;
  Uint8List? _mainDocumentBytes;

  bool _showProperties = true;
  bool _showLayers = true;

  CanvasLayer? get _selectedLayer {
    for (final layer in _layers) {
      if (layer.id == _selectedLayerId) {
        return layer;
      }
    }
    return null;
  }

  CanvasLayer? get _mainLayer {
    if (_layers.isEmpty) return null;
    return _layers.first;
  }

  bool get _hasDocument => _mainLayer != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF111318),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(theme),
            _buildActionBar(theme),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildWorkspace(theme)),
                  if (_showProperties) _buildPropertiesPanel(theme),
                ],
              ),
            ),
            if (_showLayers) _buildLayersPanel(theme),
            _buildStatusBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF181B22),
        border: Border(
          bottom: BorderSide(color: Color(0xFF30343D)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.auto_awesome,
            size: 20,
            color: Color(0xFF7C9CFF),
          ),
          const SizedBox(width: 8),
          const Text(
            'Modivka Studio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 20),
          _topButton('File', Icons.folder_open, _showFileMenu),
          _topButton('Edit', Icons.edit, _showEditMenu),
          _topButton('View', Icons.visibility, _showViewMenu),
          const Spacer(),
          if (_hasDocument)
            Text(
              _mainDocumentName ?? 'Untitled',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFB7BBC5),
                fontSize: 12,
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _topButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFD9DCE5),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        minimumSize: const Size(0, 36),
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFF20242C),
        border: Border(
          bottom: BorderSide(color: Color(0xFF343943)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _actionButton(
              Icons.note_add_outlined,
              'New',
              _newDocument,
            ),
            _actionButton(
              Icons.folder_open_outlined,
              'Open',
              _openFile,
            ),
            _actionButton(
              Icons.add_photo_alternate_outlined,
              'Add Layer',
              _openAsLayer,
            ),
            _actionButton(
              Icons.text_fields,
              'Text Layer',
              _addTextLayer,
            ),
            const VerticalDivider(
              width: 16,
              indent: 10,
              endIndent: 10,
              color: Color(0xFF454A55),
            ),
            _actionButton(
              Icons.save_outlined,
              'Save',
              _saveMainDocument,
            ),
            _actionButton(
              Icons.file_download_outlined,
              'Export',
              _exportDocument,
            ),
            const VerticalDivider(
              width: 16,
              indent: 10,
              endIndent: 10,
              color: Color(0xFF454A55),
            ),
            _actionButton(
              Icons.layers_outlined,
              'Layers',
              () {
                setState(() => _showLayers = !_showLayers);
              },
            ),
            _actionButton(
              Icons.tune,
              'Properties',
              () {
                setState(() => _showProperties = !_showProperties);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: label,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFE1E4EA),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            minimumSize: const Size(0, 40),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspace(ThemeData theme) {
    return Container(
      color: const Color(0xFF0D0F13),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!_hasDocument) {
            return _buildEmptyWorkspace();
          }

          return InteractiveViewer(
            minScale: 0.25,
            maxScale: 3.0,
            boundaryMargin: const EdgeInsets.all(300),
            child: Center(
              child: SizedBox(
                width: 900,
                height: 650,
                child: _buildCanvas(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyWorkspace() {
    return Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF181B22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF30343D),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.dashboard_customize_outlined,
              size: 58,
              color: Color(0xFF667085),
            ),
            const SizedBox(height: 18),
            const Text(
              'Modivka Workspace',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open a file to create the Main Document.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF9AA1AE),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _openFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open File'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242832),
        border: Border.all(
          color: const Color(0xFF454B57),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 28,
            color: Colors.black54,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _buildMainDocument(),
          ),
          for (final layer in _layers.skip(1).where((e) => e.visible))
            _buildDraggableLayer(layer),
        ],
      ),
    );
  }

  Widget _buildMainDocument() {
    final layer = _mainLayer;

    if (layer == null) {
      return const SizedBox.shrink();
    }

    if (layer.type == LayerType.image && layer.bytes != null) {
      return Image.memory(
        layer.bytes!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }

    if (layer.type == LayerType.text) {
      return Center(
        child: Text(
          layer.text,
          textAlign: _textAlign(layer.textAlignment),
          style: TextStyle(
            color: Color(layer.textColor.value),
            fontSize: layer.fontSize,
            fontFamily: layer.fontFamily,
            fontWeight: layer.bold ? FontWeight.bold : FontWeight.normal,
            fontStyle: layer.italic ? FontStyle.italic : FontStyle.normal,
            decoration: _textDecoration(layer),
          ),
        ),
      );
    }

    return _videoPlaceholder(layer, main: true);
  }

  Widget _buildDraggableLayer(CanvasLayer layer) {
    final selected = layer.id == _selectedLayerId;

    return Positioned(
      left: layer.x,
      top: layer.y,
      width: layer.width,
      height: layer.height,
      child: GestureDetector(
        onTap: () => _selectLayer(layer.id),
        onPanUpdate: layer.locked
            ? null
            : (details) {
                setState(() {
                  layer.x += details.delta.dx;
                  layer.y += details.delta.dy;
                });
              },
        child: Opacity(
          opacity: layer.opacity.clamp(0.0, 1.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: _buildLayerContent(layer),
              ),
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF6D8CFF),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              if (selected)
                Positioned(
                  top: -24,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF536DFE),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      layer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayerContent(CanvasLayer layer) {
    switch (layer.type) {
      case LayerType.image:
        if (layer.bytes != null) {
          return Image.memory(
            layer.bytes!,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          );
        }
        return const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white54,
        );

      case LayerType.text:
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: Text(
            layer.text,
            textAlign: _textAlign(layer.textAlignment),
            style: TextStyle(
              color: Color(layer.textColor.value),
              fontSize: layer.fontSize,
              fontFamily: layer.fontFamily,
              fontWeight: layer.bold ? FontWeight.bold : FontWeight.normal,
              fontStyle: layer.italic ? FontStyle.italic : FontStyle.normal,
              decoration: _textDecoration(layer),
              letterSpacing: layer.letterSpacing,
              height: layer.lineHeight,
            ),
          ),
        );

      case LayerType.video:
        return _videoPlaceholder(layer);
    }
  }

  Widget _videoPlaceholder(
    CanvasLayer layer, {
    bool main = false,
  }) {
    return Container(
      color: main ? const Color(0xFF20242C) : const Color(0xCC171A20),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: main ? 72 : 52,
            color: const Color(0xFF8EA5FF),
          ),
          const SizedBox(height: 8),
          Text(
            layer.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayersPanel(ThemeData theme) {
    return Container(
      height: 170,
      decoration: const BoxDecoration(
        color: Color(0xFF181B22),
        border: Border(
          top: BorderSide(color: Color(0xFF343943)),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 38,
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(
                  Icons.layers,
                  size: 17,
                  color: Color(0xFF9CA8C8),
                ),
                const SizedBox(width: 7),
                const Text(
                  'Layers',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Add Layer',
                  onPressed: _openAsLayer,
                  icon: const Icon(Icons.add, size: 19),
                  color: const Color(0xFFDDE2EF),
                ),
              ],
            ),
          ),
          Expanded(
            child: _layers.isEmpty
                ? const Center(
                    child: Text(
                      'No document',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    itemCount: _layers.length,
                    onReorderItem: _reorderLayer,
                    itemBuilder: (context, index) {
                      final layer = _layers[index];

                      return _LayerCard(
                        key: ValueKey(layer.id),
                        layer: layer,
                        selected: layer.id == _selectedLayerId,
                        isMain: index == 0,
                        onTap: () => _selectLayer(layer.id),
                        onToggleVisible: () {
                          setState(() {
                            layer.visible = !layer.visible;
                          });
                        },
                        onToggleLock: () {
                          setState(() {
                            layer.locked = !layer.locked;
                          });
                        },
                        onDelete:
                            index == 0 ? null : () => _deleteLayer(layer.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesPanel(ThemeData theme) {
    final layer = _selectedLayer;

    return Container(
      width: 235,
      decoration: const BoxDecoration(
        color: Color(0xFF181B22),
        border: Border(
          left: BorderSide(color: Color(0xFF343943)),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF343943)),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Properties',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() => _showProperties = false);
                  },
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.white60,
                ),
              ],
            ),
          ),
          Expanded(
            child: layer == null
                ? const Center(
                    child: Text(
                      'Select a layer',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: _buildLayerProperties(layer),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerProperties(CanvasLayer layer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          layer.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          layer.type.name.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF7C9CFF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        _numberField(
          'X',
          layer.x,
          (value) => setState(() => layer.x = value),
        ),
        _numberField(
          'Y',
          layer.y,
          (value) => setState(() => layer.y = value),
        ),
        _numberField(
          'Width',
          layer.width,
          (value) => setState(() => layer.width = value),
        ),
        _numberField(
          'Height',
          layer.height,
          (value) => setState(() => layer.height = value),
        ),
        _numberField(
          'Rotation',
          layer.rotation,
          (value) => setState(() => layer.rotation = value),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Visible',
            style: TextStyle(color: Colors.white70),
          ),
          value: layer.visible,
          onChanged: (value) {
            setState(() => layer.visible = value);
          },
        ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Locked',
            style: TextStyle(color: Colors.white70),
          ),
          value: layer.locked,
          onChanged: (value) {
            setState(() => layer.locked = value);
          },
        ),
        if (layer.type == LayerType.text) ...[
          const Divider(color: Color(0xFF343943)),
          const SizedBox(height: 8),
          const Text(
            'Text',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: layer.text),
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Text'),
            onChanged: (value) {
              layer.text = value;
            },
          ),
          const SizedBox(height: 8),
          _numberField(
            'Font Size',
            layer.fontSize,
            (value) => setState(() => layer.fontSize = value),
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Bold',
              style: TextStyle(color: Colors.white70),
            ),
            value: layer.bold,
            onChanged: (value) {
              setState(() => layer.bold = value);
            },
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Italic',
              style: TextStyle(color: Colors.white70),
            ),
            value: layer.italic,
            onChanged: (value) {
              setState(() => layer.italic = value);
            },
          ),
        ],
      ],
    );
  }

  Widget _numberField(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value.toStringAsFixed(1),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        decoration: _inputDecoration(label),
        onFieldSubmitted: (text) {
          final parsed = double.tryParse(text);
          if (parsed != null) {
            onChanged(parsed);
          }
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF101217),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF343943)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF343943)),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
    );
  }

  Widget _buildStatusBar(ThemeData theme) {
    final selected = _selectedLayer;

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFF111318),
      child: Row(
        children: [
          Text(
            _hasDocument
                ? '${_layers.length} layer${_layers.length == 1 ? '' : 's'}'
                : 'No document',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
          const Spacer(),
          if (selected != null)
            Text(
              selected.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (files.isEmpty) return;

    final file = files.first;
    await _addFileFromPlatformFile(file);
  }

  Future<void> _openAsLayer() async {
    if (!_hasDocument) {
      await _openFile();
      return;
    }

    final files = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (files.isEmpty) return;

    for (final file in files) {
      await _addFileFromPlatformFile(
        file,
        forceLayer: true,
      );
    }
  }

  Future<void> _addFileFromPlatformFile(
    PlatformFile file, {
    bool forceLayer = false,
  }) async {
    final path = file.path;

    if (path == null || path.isEmpty) {
      _showMessage('Unable to access selected file.');
      return;
    }

    try {
      final bytes = await File(path).readAsBytes();
      final id = '${DateTime.now().microsecondsSinceEpoch}-${file.name}';

      if (!_hasDocument && !forceLayer) {
        final type = _layerTypeFromFile(file.name);

        final main = CanvasLayer(
          id: 'main-document',
          name: file.name,
          type: type,
          bytes: bytes,
          path: path,
          width: 900,
          height: 650,
        );

        setState(() {
          _layers.clear();
          _layers.add(main);
          _selectedLayerId = main.id;
          _mainDocumentName = file.name;
          _mainDocumentBytes = bytes;
        });

        _showMessage('Main Document opened.');
        return;
      }

      final layer = CanvasLayer(
        id: id,
        name: file.name,
        type: _layerTypeFromFile(file.name),
        bytes: bytes,
        path: path,
        x: 80 + (_layers.length * 12),
        y: 70 + (_layers.length * 12),
        width: 300,
        height: 300,
      );

      setState(() {
        _layers.add(layer);
        _selectedLayerId = layer.id;
      });

      _showMessage('Layer added: ${file.name}');
    } catch (e) {
      _showMessage('Unable to open file: $e');
    }
  }

  Future<void> _addTextLayer() async {
    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Text Layer'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Text',
              hintText: 'Enter your text...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (text == null || text.isEmpty) return;

    if (!_hasDocument) {
      _showMessage('Open a Main Document first.');
      return;
    }

    final layer = CanvasLayer(
      id: 'text-${DateTime.now().microsecondsSinceEpoch}',
      name: 'Text Layer',
      type: LayerType.text,
      text: text,
      x: 120,
      y: 100,
      width: 420,
      height: 150,
      fontSize: 42,
    );

    setState(() {
      _layers.add(layer);
      _selectedLayerId = layer.id;
    });
  }

  Future<void> _saveMainDocument() async {
    if (_mainDocumentBytes == null) {
      _showMessage('There is no Main Document to save.');
      return;
    }

    final name = _mainDocumentName ?? 'modivka-document';

    final uri = await FilePicker.saveFile(
      dialogTitle: 'Save Main Document',
      fileName: name,
      bytes: _mainDocumentBytes!,
    );

    if (uri == null) return;

    _showMessage('Main Document saved.');
  }

  Future<void> _exportDocument() async {
    if (_mainDocumentBytes == null) {
      _showMessage('There is no Main Document to export.');
      return;
    }

    final uri = await FilePicker.saveFile(
      dialogTitle: 'Export Document',
      fileName: _mainDocumentName ?? 'modivka-export',
      bytes: _mainDocumentBytes!,
    );

    if (uri != null) {
      _showMessage('Export completed.');
    }
  }

  void _newDocument() {
    if (_layers.isEmpty) {
      _showMessage('Workspace is already empty.');
      return;
    }

    setState(() {
      _layers.clear();
      _selectedLayerId = null;
      _mainDocumentName = null;
      _mainDocumentBytes = null;
    });

    _showMessage('New workspace created.');
  }

  void _selectLayer(String id) {
    setState(() {
      _selectedLayerId = id;
    });
  }

  void _deleteLayer(String id) {
    if (id == 'main-document') return;

    setState(() {
      _layers.removeWhere((layer) => layer.id == id);

      if (_selectedLayerId == id) {
        _selectedLayerId = _layers.isNotEmpty ? _layers.first.id : null;
      }
    });
  }

  void _reorderLayer(int oldIndex, int newIndex) {
    if (oldIndex == 0 || newIndex == 0) {
      return;
    }

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    setState(() {
      final layer = _layers.removeAt(oldIndex);
      _layers.insert(newIndex, layer);
    });
  }

  LayerType _layerTypeFromFile(String name) {
    final extension = _extension(name).toLowerCase();

    const imageExtensions = {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'bmp',
      'tif',
      'tiff',
      'heic',
      'heif',
      'avif',
    };

    const videoExtensions = {
      'mp4',
      'mov',
      'm4v',
      'avi',
      'mkv',
      'webm',
      '3gp',
      'mpeg',
      'mpg',
    };

    if (imageExtensions.contains(extension)) {
      return LayerType.image;
    }

    if (videoExtensions.contains(extension)) {
      return LayerType.video;
    }

    return LayerType.text;
  }

  String _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) {
      return '';
    }
    return name.substring(dot + 1);
  }

  TextAlign _textAlign(TextAlignment alignment) {
    switch (alignment) {
      case TextAlignment.left:
        return TextAlign.left;
      case TextAlignment.center:
        return TextAlign.center;
      case TextAlignment.right:
        return TextAlign.right;
    }
  }

  TextDecoration _textDecoration(CanvasLayer layer) {
    if (layer.underline && layer.strikethrough) {
      return TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
    }

    if (layer.underline) {
      return TextDecoration.underline;
    }

    if (layer.strikethrough) {
      return TextDecoration.lineThrough;
    }

    return TextDecoration.none;
  }

  void _showFileMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1E25),
      builder: (context) {
        return _MenuSheet(
          items: [
            _MenuItem(
              Icons.note_add_outlined,
              'New',
              _newDocument,
            ),
            _MenuItem(
              Icons.folder_open_outlined,
              'Open',
              _openFile,
            ),
            _MenuItem(
              Icons.save_outlined,
              'Save',
              _saveMainDocument,
            ),
            _MenuItem(
              Icons.file_download_outlined,
              'Export',
              _exportDocument,
            ),
          ],
        );
      },
    );
  }

  void _showEditMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1E25),
      builder: (context) {
        return _MenuSheet(
          items: [
            _MenuItem(
              Icons.text_fields,
              'Add Text Layer',
              _addTextLayer,
            ),
            _MenuItem(
              Icons.delete_outline,
              'Delete Selected Layer',
              () {
                final id = _selectedLayerId;
                if (id != null) {
                  _deleteLayer(id);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showViewMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1E25),
      builder: (context) {
        return _MenuSheet(
          items: [
            _MenuItem(
              Icons.layers_outlined,
              _showLayers ? 'Hide Layers' : 'Show Layers',
              () {
                setState(() => _showLayers = !_showLayers);
              },
            ),
            _MenuItem(
              Icons.tune,
              _showProperties ? 'Hide Properties' : 'Show Properties',
              () {
                setState(
                  () => _showProperties = !_showProperties,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _LayerCard extends StatelessWidget {
  const _LayerCard({
    super.key,
    required this.layer,
    required this.selected,
    required this.isMain,
    required this.onTap,
    required this.onToggleVisible,
    required this.onToggleLock,
    required this.onDelete,
  });

  final CanvasLayer layer;
  final bool selected;
  final bool isMain;
  final VoidCallback onTap;
  final VoidCallback onToggleVisible;
  final VoidCallback onToggleLock;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2A3450) : const Color(0xFF22262E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF718BFF) : const Color(0xFF343943),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: double.infinity,
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF12151A),
                borderRadius: BorderRadius.circular(5),
              ),
              child: _thumbnail(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMain ? 'MAIN' : layer.type.name.toUpperCase(),
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF9EB0FF)
                            : const Color(0xFF777F90),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      layer.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        InkWell(
                          onTap: onToggleVisible,
                          child: Icon(
                            layer.visible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 15,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onToggleLock,
                          child: Icon(
                            layer.locked ? Icons.lock : Icons.lock_open,
                            size: 14,
                            color: Colors.white54,
                          ),
                        ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onDelete,
                            child: const Icon(
                              Icons.delete_outline,
                              size: 15,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 5),
              child: Icon(
                Icons.drag_indicator,
                size: 17,
                color: Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail() {
    if (layer.type == LayerType.image && layer.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.memory(
          layer.bytes!,
          fit: BoxFit.cover,
        ),
      );
    }

    IconData icon;

    switch (layer.type) {
      case LayerType.image:
        icon = Icons.image_outlined;
        break;
      case LayerType.text:
        icon = Icons.text_fields;
        break;
      case LayerType.video:
        icon = Icons.movie_outlined;
        break;
    }

    return Icon(
      icon,
      color: const Color(0xFF8799D8),
      size: 22,
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.title, this.onTap);

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}

class _MenuSheet extends StatelessWidget {
  const _MenuSheet({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          for (final item in items)
            ListTile(
              leading: Icon(
                item.icon,
                color: const Color(0xFF9EB0FF),
              ),
              title: Text(
                item.title,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                item.onTap();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
