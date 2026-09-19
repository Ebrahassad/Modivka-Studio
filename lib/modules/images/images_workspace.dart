import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/canvas_layer.dart';
import '../../core/models/workspace_item.dart';
import '../../widgets/image_canvas.dart';
import '../../widgets/item_strip.dart';
import '../../widgets/layer_properties.dart';
import '../../widgets/layers_strip.dart';
import '../../widgets/tool_bar.dart';

class ImagesWorkspace extends StatefulWidget {
  final List<WorkspaceItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAddImage;
  final VoidCallback onAddLayer;
  final VoidCallback onSave;
  final VoidCallback onConvert;
  final VoidCallback onCompress;

  const ImagesWorkspace({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onAddImage,
    required this.onAddLayer,
    required this.onSave,
    required this.onConvert,
    required this.onCompress,
  });

  @override
  State<ImagesWorkspace> createState() => _ImagesWorkspaceState();
}

class _ImagesWorkspaceState extends State<ImagesWorkspace> {
  CanvasLayer? _copiedLayer;
  final FocusNode _workspaceFocusNode = FocusNode();

  final List<List<CanvasLayer>> _undoStack = [];
  final List<List<CanvasLayer>> _redoStack = [];
  final List<CanvasLayer> _layers = [];

  int _selectedLayer = -1;

  static const int _maxHistoryEntries = 80;

  @override
  void initState() {
    super.initState();
    _syncLayers();
  }

  @override
  void didUpdateWidget(
    covariant ImagesWorkspace oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.length != oldWidget.items.length) {
      _syncLayers();
    }
  }

  void _syncLayers() {
    if (_layers.isEmpty) {
      _layers.add(
        CanvasLayer(
          id: 'text-default',
          name: 'Modivka Studio',
          type: LayerType.text,
          text: 'Modivka Studio',
          x: 360,
          y: 335,
          width: 480,
          height: 100,
          fontSize: 56,
          bold: true,
          textAlignment: TextAlignment.center,
        ),
      );
    }

    for (final item in widget.items) {
      final id =
          item.path.isEmpty ? '${item.name}-${item.hashCode}' : item.path;

      final exists = _layers.any(
        (layer) => layer.id == id,
      );

      if (!exists && item.bytes != null) {
        _layers.insert(
          0,
          CanvasLayer(
            id: id,
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

  CanvasLayer? get _currentLayer {
    if (_selectedLayer < 0 || _selectedLayer >= _layers.length) {
      return null;
    }

    return _layers[_selectedLayer];
  }

  List<CanvasLayer> _cloneLayers(List<CanvasLayer> source) {
    return source
        .map(
          (layer) => _cloneLayer(
            layer,
            offsetX: 0,
            offsetY: 0,
          ),
        )
        .toList();
  }

  void _saveHistory() {
    _undoStack.add(_cloneLayers(_layers));

    if (_undoStack.length > _maxHistoryEntries) {
      _undoStack.removeAt(0);
    }

    _redoStack.clear();
  }

  bool get _canUndo => _undoStack.isNotEmpty;

  bool get _canRedo => _redoStack.isNotEmpty;

  void _restoreLayers(List<CanvasLayer> snapshot) {
    _layers
      ..clear()
      ..addAll(_cloneLayers(snapshot));

    if (_layers.isEmpty) {
      _selectedLayer = -1;
    } else {
      _selectedLayer = _selectedLayer.clamp(0, _layers.length - 1);
    }
  }

  void _undo() {
    if (!_canUndo) {
      return;
    }

    final current = _cloneLayers(_layers);
    final previous = _undoStack.removeLast();

    _redoStack.add(current);

    setState(() {
      _restoreLayers(previous);
    });

    _workspaceFocusNode.requestFocus();
  }

  void _redo() {
    if (!_canRedo) {
      return;
    }

    final current = _cloneLayers(_layers);
    final next = _redoStack.removeLast();

    _undoStack.add(current);

    setState(() {
      _restoreLayers(next);
    });

    _workspaceFocusNode.requestFocus();
  }

  void _mutateWithHistory(VoidCallback mutation) {
    _saveHistory();

    setState(() {
      mutation();
    });
  }

  void _moveSelected(Offset delta) {
    final layer = _currentLayer;

    if (layer == null || layer.locked) {
      return;
    }

    const canvasWidth = 1200.0;
    const canvasHeight = 800.0;
    const snapDistance = 8.0;

    double x = layer.x + delta.dx;
    double y = layer.y + delta.dy;

    // Keep the layer inside the workspace.
    // A small portion may touch the edge, but the layer cannot
    // be moved completely outside the 1200 x 800 canvas.
    final maxX = canvasWidth - layer.width;
    final maxY = canvasHeight - layer.height;

    if (maxX >= 0) {
      x = x.clamp(0.0, maxX);
    } else {
      x = 0.0;
    }

    if (maxY >= 0) {
      y = y.clamp(0.0, maxY);
    } else {
      y = 0.0;
    }

    final centerX = x + layer.width / 2;
    final centerY = y + layer.height / 2;
    final right = x + layer.width;
    final bottom = y + layer.height;

    double? snapX;
    double? snapY;

    void checkX(double value, double target) {
      if ((value - target).abs() <= snapDistance) {
        snapX = target;
      }
    }

    void checkY(double value, double target) {
      if ((value - target).abs() <= snapDistance) {
        snapY = target;
      }
    }

    // Canvas guides.
    checkX(x, 0);
    checkX(centerX, canvasWidth / 2);
    checkX(right, canvasWidth);

    checkY(y, 0);
    checkY(centerY, canvasHeight / 2);
    checkY(bottom, canvasHeight);

    // Other visible layers.
    for (var i = 0; i < _layers.length; i++) {
      if (i == _selectedLayer) {
        continue;
      }

      final other = _layers[i];

      if (!other.visible) {
        continue;
      }

      final otherLeft = other.x;
      final otherCenterX = other.x + other.width / 2;
      final otherRight = other.x + other.width;

      final otherTop = other.y;
      final otherCenterY = other.y + other.height / 2;
      final otherBottom = other.y + other.height;

      checkX(x, otherLeft);
      checkX(x, otherCenterX);
      checkX(x, otherRight);

      checkX(centerX, otherLeft);
      checkX(centerX, otherCenterX);
      checkX(centerX, otherRight);

      checkX(right, otherLeft);
      checkX(right, otherCenterX);
      checkX(right, otherRight);

      checkY(y, otherTop);
      checkY(y, otherCenterY);
      checkY(y, otherBottom);

      checkY(centerY, otherTop);
      checkY(centerY, otherCenterY);
      checkY(centerY, otherBottom);

      checkY(bottom, otherTop);
      checkY(bottom, otherCenterY);
      checkY(bottom, otherBottom);
    }

    if (snapX != null) {
      if ((x - snapX!).abs() <= snapDistance) {
        x = snapX!;
      } else if ((centerX - snapX!).abs() <= snapDistance) {
        x = snapX! - layer.width / 2;
      } else if ((right - snapX!).abs() <= snapDistance) {
        x = snapX! - layer.width;
      }
    }

    if (snapY != null) {
      if ((y - snapY!).abs() <= snapDistance) {
        y = snapY!;
      } else if ((centerY - snapY!).abs() <= snapDistance) {
        y = snapY! - layer.height / 2;
      } else if ((bottom - snapY!).abs() <= snapDistance) {
        y = snapY! - layer.height;
      }
    }

    _mutateWithHistory(() {
      layer.x = x;
      layer.y = y;
    });
  }

  void _setX(double value) {
    final layer = _currentLayer;

    if (layer == null || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.x = value;
    });
  }

  void _setY(double value) {
    final layer = _currentLayer;

    if (layer == null || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.y = value;
    });
  }

  void _setWidth(double value) {
    final layer = _currentLayer;

    if (layer == null || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.width = value.clamp(20.0, 2000.0);
    });
  }

  void _setHeight(double value) {
    final layer = _currentLayer;

    if (layer == null || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.height = value.clamp(20.0, 2000.0);
    });
  }

  void _resizeSelected(Offset delta) {
    if (_selectedLayer < 0 || _selectedLayer >= _layers.length) {
      return;
    }

    final layer = _layers[_selectedLayer];

    if (layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      final newWidth = (layer.width + delta.dx).clamp(40.0, 2000.0);
      final newHeight = (layer.height + delta.dy).clamp(40.0, 2000.0);

      // Do not resize beyond the right/bottom edges of the canvas.
      final maxWidth = 1200.0 - layer.x;
      final maxHeight = 800.0 - layer.y;

      layer.width = newWidth.clamp(
        40.0,
        maxWidth < 40.0 ? 40.0 : maxWidth,
      );

      layer.height = newHeight.clamp(
        40.0,
        maxHeight < 40.0 ? 40.0 : maxHeight,
      );
    });
  }

  void _rotateSelected(double delta) {
    if (_selectedLayer < 0 || _selectedLayer >= _layers.length) {
      return;
    }

    final layer = _layers[_selectedLayer];

    if (layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.rotation += delta * 0.01;

      // Keep rotation normalized to one full turn.
      while (layer.rotation > 3.141592653589793) {
        layer.rotation -= 6.283185307179586;
      }

      while (layer.rotation < -3.141592653589793) {
        layer.rotation += 6.283185307179586;
      }
    });
  }

  void _setRotation(double value) {
    final layer = _currentLayer;

    if (layer == null || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.rotation = value;
    });
  }

  void _setOpacity(double value) {
    final layer = _currentLayer;

    if (layer == null) {
      return;
    }

    _mutateWithHistory(() {
      layer.opacity = value.clamp(0.0, 1.0);
    });
  }

  void _setText(String value) {
    final layer = _currentLayer;

    if (layer == null || layer.type != LayerType.text) {
      return;
    }

    _mutateWithHistory(() {
      layer.text = value;
      layer.name = value.trim().isEmpty ? 'Text Layer' : value.trim();
    });
  }

  void _setFontFamily(String value) {
    final layer = _currentLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.fontFamily = value;
    });
  }

  void _setFontSize(double value) {
    final layer = _currentLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.fontSize = value.clamp(6.0, 300.0);
    });
  }

  void _setBold(bool value) {
    final layer = _currentLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.bold = value;
    });
  }

  void _setItalic(bool value) {
    final layer = _currentLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.italic = value;
    });
  }

  void _setUnderline(bool value) {
    final layer = _currentLayer;

    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.underline = value;
    });
  }

  void _setStrikethrough(bool value) {
    final layer = _currentLayer;

    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.strikethrough = value;
    });
  }

  void _setLetterSpacing(double value) {
    final layer = _currentLayer;

    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.letterSpacing = value.clamp(-10.0, 50.0);
    });
  }

  void _setLineHeight(double value) {
    final layer = _currentLayer;

    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.lineHeight = value.clamp(0.5, 3.0);
    });
  }

  void _setTextColor(ColorValue value) {
    final layer = _currentLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.textColor = value;
    });
  }

  void _setTextAlignment(TextAlignment value) {
    final layer = _currentLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    _mutateWithHistory(() {
      layer.textAlignment = value;
    });
  }

  void _alignLeft() {
    final layer = _currentLayer;
    if (layer == null || layer.locked) return;

    _mutateWithHistory(() {
      layer.x = 0;
    });
  }

  void _alignCenterHorizontal() {
    final layer = _currentLayer;
    if (layer == null || layer.locked) return;

    _mutateWithHistory(() {
      layer.x = (1200 - layer.width) / 2;
    });
  }

  void _alignRight() {
    final layer = _currentLayer;
    if (layer == null || layer.locked) return;

    _mutateWithHistory(() {
      layer.x = 1200 - layer.width;
    });
  }

  void _alignTop() {
    final layer = _currentLayer;
    if (layer == null || layer.locked) return;

    _mutateWithHistory(() {
      layer.y = 0;
    });
  }

  void _alignCenterVertical() {
    final layer = _currentLayer;
    if (layer == null || layer.locked) return;

    _mutateWithHistory(() {
      layer.y = (800 - layer.height) / 2;
    });
  }

  void _alignBottom() {
    final layer = _currentLayer;
    if (layer == null || layer.locked) return;

    _mutateWithHistory(() {
      layer.y = 800 - layer.height;
    });
  }

  void _distributeHorizontal() {
    final movable =
        _layers.where((layer) => layer.visible && !layer.locked).toList();

    if (movable.length < 3) {
      return;
    }

    movable.sort((a, b) => a.x.compareTo(b.x));

    final first = movable.first;
    final last = movable.last;

    final start = first.x;
    final end = last.x + last.width;
    final totalWidth =
        movable.fold<double>(0, (sum, layer) => sum + layer.width);
    final gap = (end - start - totalWidth) / (movable.length - 1);

    _mutateWithHistory(() {
      double x = start;

      for (final layer in movable) {
        layer.x = x;
        x += layer.width + gap;
      }
    });
  }

  void _distributeVertical() {
    final movable =
        _layers.where((layer) => layer.visible && !layer.locked).toList();

    if (movable.length < 3) {
      return;
    }

    movable.sort((a, b) => a.y.compareTo(b.y));

    final first = movable.first;
    final last = movable.last;

    final start = first.y;
    final end = last.y + last.height;
    final totalHeight =
        movable.fold<double>(0, (sum, layer) => sum + layer.height);
    final gap = (end - start - totalHeight) / (movable.length - 1);

    _mutateWithHistory(() {
      double y = start;

      for (final layer in movable) {
        layer.y = y;
        y += layer.height + gap;
      }
    });
  }

  void _toggleLock(bool value) {
    final layer = _currentLayer;

    if (layer == null) {
      return;
    }

    _mutateWithHistory(() {
      layer.locked = value;
    });
  }

  void _deleteSelected() {
    if (_selectedLayer < 0 || _selectedLayer >= _layers.length) {
      return;
    }

    _mutateWithHistory(() {
      _layers.removeAt(_selectedLayer);

      if (_layers.isEmpty) {
        _selectedLayer = -1;
      } else if (_selectedLayer >= _layers.length) {
        _selectedLayer = _layers.length - 1;
      }
    });
  }

  void _duplicateSelected() {
    final layer = _currentLayer;

    if (layer == null) {
      return;
    }

    final copy = _cloneLayer(layer);

    _mutateWithHistory(() {
      _layers.insert(0, copy);
      _selectedLayer = 0;
    });
  }

  void _moveUp() {
    if (_selectedLayer <= 0) {
      return;
    }

    _mutateWithHistory(() {
      final layer = _layers.removeAt(_selectedLayer);
      _layers.insert(_selectedLayer - 1, layer);
      _selectedLayer--;
    });
  }

  void _moveDown() {
    if (_selectedLayer < 0 || _selectedLayer >= _layers.length - 1) {
      return;
    }

    _mutateWithHistory(() {
      final layer = _layers.removeAt(_selectedLayer);
      _layers.insert(_selectedLayer + 1, layer);
      _selectedLayer++;
    });
  }

  void _toggleVisibility(int index) {
    _mutateWithHistory(() {
      _layers[index].visible = !_layers[index].visible;
    });
  }

  void _toggleLayerLock(int index) {
    _mutateWithHistory(() {
      _layers[index].locked = !_layers[index].locked;
    });
  }

  void _addTextLayer() {
    _mutateWithHistory(() {
      _layers.insert(
        0,
        CanvasLayer(
          id: 'text-${DateTime.now().microsecondsSinceEpoch}',
          name: 'Text Layer',
          type: LayerType.text,
          text: 'Modivka',
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
  void dispose() {
    _workspaceFocusNode.dispose();
    super.dispose();
  }

  void _nudgeSelected(Offset delta) {
    final layer = _currentLayer;

    if (layer == null || layer.locked) {
      return;
    }

    _moveSelected(delta);
  }

  CanvasLayer _cloneLayer(
    CanvasLayer layer, {
    double offsetX = 24,
    double offsetY = 24,
  }) {
    return CanvasLayer(
      id: '${layer.id}-copy-${DateTime.now().microsecondsSinceEpoch}',
      name: '${layer.name} Copy',
      type: layer.type,
      bytes: layer.bytes,
      text: layer.text,
      fontFamily: layer.fontFamily,
      fontSize: layer.fontSize,
      bold: layer.bold,
      italic: layer.italic,
      underline: layer.underline,
      strikethrough: layer.strikethrough,
      letterSpacing: layer.letterSpacing,
      lineHeight: layer.lineHeight,
      textColor: layer.textColor,
      textAlignment: layer.textAlignment,
      x: layer.x + offsetX,
      y: layer.y + offsetY,
      width: layer.width,
      height: layer.height,
      rotation: layer.rotation,
      opacity: layer.opacity,
      visible: layer.visible,
      locked: false,
    );
  }

  void _copySelected() {
    final layer = _currentLayer;

    if (layer == null) {
      return;
    }

    setState(() {
      _copiedLayer = _cloneLayer(
        layer,
        offsetX: 0,
        offsetY: 0,
      );
    });
  }

  void _pasteCopied() {
    final copied = _copiedLayer;

    if (copied == null) {
      return;
    }

    final pasted = _cloneLayer(copied);

    _mutateWithHistory(() {
      _layers.insert(0, pasted);
      _selectedLayer = 0;
    });

    _workspaceFocusNode.requestFocus();
  }

  void _handleWorkspaceKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return;
    }

    final keyboard = HardwareKeyboard.instance;
    final ctrl = keyboard.isControlPressed || keyboard.isMetaPressed;
    final shift = keyboard.isShiftPressed;

    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyC) {
      _copySelected();
      return;
    }

    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyV) {
      _pasteCopied();
      return;
    }

    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
      if (shift) {
        _redo();
      } else {
        _undo();
      }
      return;
    }

    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyY) {
      _redo();
      return;
    }

    final step = shift ? 10.0 : 1.0;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _nudgeSelected(Offset(-step, 0));
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _nudgeSelected(Offset(step, 0));
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _nudgeSelected(Offset(0, -step));
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _nudgeSelected(Offset(0, step));
    }
  }

  Future<void> _showProperties() async {
    if (_currentLayer == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0F0E18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayerProperties(
                  layer: _currentLayer,
                  onDelete: () {
                    Navigator.pop(sheetContext);
                    _deleteSelected();
                  },
                  onMoveUp: _moveUp,
                  onMoveDown: _moveDown,
                  onXChanged: _setX,
                  onYChanged: _setY,
                  onWidthChanged: _setWidth,
                  onHeightChanged: _setHeight,
                  onRotationChanged: _setRotation,
                  onOpacityChanged: _setOpacity,
                  onLockChanged: _toggleLock,
                  onTextChanged: _setText,
                  onFontFamilyChanged: _setFontFamily,
                  onFontSizeChanged: _setFontSize,
                  onBoldChanged: _setBold,
                  onItalicChanged: _setItalic,
                  onUnderlineChanged: _setUnderline,
                  onStrikethroughChanged: _setStrikethrough,
                  onLetterSpacingChanged: _setLetterSpacing,
                  onLineHeightChanged: _setLineHeight,
                  onTextColorChanged: _setTextColor,
                  onTextAlignmentChanged: _setTextAlignment,
                  onAlignLeft: _alignLeft,
                  onAlignCenterHorizontal: _alignCenterHorizontal,
                  onAlignRight: _alignRight,
                  onAlignTop: _alignTop,
                  onAlignCenterVertical: _alignCenterVertical,
                  onAlignBottom: _alignBottom,
                  onDistributeHorizontal: _distributeHorizontal,
                  onDistributeVertical: _distributeVertical,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _workspaceFocusNode,
      onKeyEvent: _handleWorkspaceKey,
      child: Column(
        children: [
          ModivkaToolBar(
            tools: [
              ToolDefinition(
                icon: Icons.add_photo_alternate_outlined,
                name: 'Add image',
                onPressed: widget.onAddImage,
              ),
              ToolDefinition(
                icon: Icons.image_outlined,
                name: 'Image layer',
                onPressed: widget.onAddLayer,
              ),
              ToolDefinition(
                icon: Icons.save_outlined,
                name: 'Save / export',
                onPressed: widget.onSave,
              ),
              ToolDefinition(
                icon: Icons.transform_rounded,
                name: 'Convert',
                onPressed: widget.onConvert,
              ),
              ToolDefinition(
                icon: Icons.compress_rounded,
                name: 'Compress',
                onPressed: widget.onCompress,
              ),
              ToolDefinition(
                icon: Icons.text_fields_rounded,
                name: 'Add text',
                onPressed: _addTextLayer,
              ),
              ToolDefinition(
                icon: Icons.tune_rounded,
                name: 'Layer properties',
                onPressed: _currentLayer == null ? null : _showProperties,
              ),
              const ToolDefinition(
                icon: Icons.crop_rounded,
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
                icon: Icons.auto_fix_high_rounded,
                name: 'Enhance',
              ),
              ToolDefinition(
                icon: Icons.undo_rounded,
                name: 'Undo',
                onPressed: _canUndo ? _undo : null,
              ),
              ToolDefinition(
                icon: Icons.redo_rounded,
                name: 'Redo',
                onPressed: _canRedo ? _redo : null,
              ),
            ],
          ),
          LayersStrip(
            layers: _layers,
            selectedIndex: _selectedLayer,
            onSelected: (index) {
              setState(() => _selectedLayer = index);
              _workspaceFocusNode.requestFocus();
            },
            onVisibilityChanged: _toggleVisibility,
            onLockChanged: _toggleLayerLock,
            onAdd: _addTextLayer,
            onDelete: _deleteSelected,
            onDuplicate: _duplicateSelected,
            onMoveUp: _moveUp,
            onMoveDown: _moveDown,
            onProperties: _showProperties,
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              decoration: BoxDecoration(
                color: const Color(0xFF05050A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withAlpha(12)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _workspaceFocusNode.requestFocus,
                child: ImageCanvas(
                  layers: _layers,
                  selectedIndex: _selectedLayer,
                  onSelected: (index) {
                    setState(() => _selectedLayer = index);
                  },
                  onMove: _moveSelected,
                  onResize: _resizeSelected,
                  onRotate: _rotateSelected,
                ),
              ),
            ),
          ),
          ItemStrip(
            items: widget.items,
            selectedIndex: widget.selectedIndex,
            onSelected: widget.onSelected,
          ),
        ],
      ),
    );
  }
}
