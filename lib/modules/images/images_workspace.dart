import 'package:flutter/material.dart';

import '../../core/models/canvas_layer.dart';
import '../../core/models/workspace_item.dart';
import '../../widgets/image_canvas.dart';
import '../../widgets/item_strip.dart';
import '../../widgets/layer_properties.dart';
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

    setState(() {
      layer.x = x;
      layer.y = y;
    });
  }

  void _setX(double value) {
    final layer = _currentLayer;

    if (layer == null || layer.locked) {
      return;
    }

    setState(() {
      layer.x = value;
    });
  }

  void _setY(double value) {
    final layer = _currentLayer;

    if (layer == null || layer.locked) {
      return;
    }

    setState(() {
      layer.y = value;
    });
  }

  void _setWidth(double value) {
    final layer = _currentLayer;

    if (layer == null || layer.locked) {
      return;
    }

    setState(() {
      layer.width = value.clamp(20.0, 2000.0);
    });
  }

  void _setHeight(double value) {
    final layer = _currentLayer;

    if (layer == null || layer.locked) {
      return;
    }

    setState(() {
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

    setState(() {
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

    setState(() {
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

    setState(() {
      layer.rotation = value;
    });
  }

  void _setOpacity(double value) {
    final layer = _currentLayer;

    if (layer == null) {
      return;
    }

    setState(() {
      layer.opacity = value.clamp(0.0, 1.0);
    });
  }

  void _setText(String value) {
    final layer = _currentLayer;

    if (layer == null || layer.type != LayerType.text) {
      return;
    }

    setState(() {
      layer.text = value;
      layer.name = value.trim().isEmpty ? 'Text Layer' : value.trim();
    });
  }

  void _setFontFamily(String value) {
    final layer = _currentLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    setState(() {
      layer.fontFamily = value;
    });
  }

  void _setFontSize(double value) {
    final layer = _currentLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    setState(() {
      layer.fontSize = value.clamp(6.0, 300.0);
    });
  }

  void _setBold(bool value) {
    final layer = _currentLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    setState(() {
      layer.bold = value;
    });
  }

  void _setItalic(bool value) {
    final layer = _currentLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    setState(() {
      layer.italic = value;
    });
  }

  void _setUnderline(bool value) {
    final layer = _currentLayer;

    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    setState(() {
      layer.underline = value;
    });
  }

  void _setStrikethrough(bool value) {
    final layer = _currentLayer;

    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    setState(() {
      layer.strikethrough = value;
    });
  }

  void _setLetterSpacing(double value) {
    final layer = _currentLayer;

    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    setState(() {
      layer.letterSpacing = value.clamp(-10.0, 50.0);
    });
  }

  void _setLineHeight(double value) {
    final layer = _currentLayer;

    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    setState(() {
      layer.lineHeight = value.clamp(0.5, 3.0);
    });
  }

  void _setTextColor(ColorValue value) {
    final layer = _currentLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    setState(() {
      layer.textColor = value;
    });
  }

  void _setTextAlignment(TextAlignment value) {
    final layer = _currentLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) {
      return;
    }

    setState(() {
      layer.textAlignment = value;
    });
  }

  void _alignLeft() {
    final layer = _currentLayer;
    if (layer == null || layer.locked) return;

    setState(() {
      layer.x = 0;
    });
  }

  void _alignCenterHorizontal() {
    final layer = _currentLayer;
    if (layer == null || layer.locked) return;

    setState(() {
      layer.x = (1200 - layer.width) / 2;
    });
  }

  void _alignRight() {
    final layer = _currentLayer;
    if (layer == null || layer.locked) return;

    setState(() {
      layer.x = 1200 - layer.width;
    });
  }

  void _alignTop() {
    final layer = _currentLayer;
    if (layer == null || layer.locked) return;

    setState(() {
      layer.y = 0;
    });
  }

  void _alignCenterVertical() {
    final layer = _currentLayer;
    if (layer == null || layer.locked) return;

    setState(() {
      layer.y = (800 - layer.height) / 2;
    });
  }

  void _alignBottom() {
    final layer = _currentLayer;
    if (layer == null || layer.locked) return;

    setState(() {
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

    setState(() {
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

    setState(() {
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

    setState(() {
      layer.locked = value;
    });
  }

  void _deleteSelected() {
    if (_selectedLayer < 0 || _selectedLayer >= _layers.length) {
      return;
    }

    setState(() {
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

    final copy = CanvasLayer(
      id: '${layer.id}-copy-${DateTime.now().microsecondsSinceEpoch}',
      name: '${layer.name} Copy',
      type: layer.type,
      bytes: layer.bytes,
      text: layer.text,
      x: layer.x + 24,
      y: layer.y + 24,
      width: layer.width,
      height: layer.height,
      rotation: layer.rotation,
      opacity: layer.opacity,
      visible: layer.visible,
      locked: false,
    );

    setState(() {
      _layers.insert(0, copy);
      _selectedLayer = 0;
    });
  }

  void _moveUp() {
    if (_selectedLayer <= 0) {
      return;
    }

    setState(() {
      final layer = _layers.removeAt(_selectedLayer);
      _layers.insert(_selectedLayer - 1, layer);
      _selectedLayer--;
    });
  }

  void _moveDown() {
    if (_selectedLayer < 0 || _selectedLayer >= _layers.length - 1) {
      return;
    }

    setState(() {
      final layer = _layers.removeAt(_selectedLayer);
      _layers.insert(_selectedLayer + 1, layer);
      _selectedLayer++;
    });
  }

  void _toggleVisibility(int index) {
    setState(() {
      _layers[index].visible = !_layers[index].visible;
    });
  }

  void _toggleLayerLock(int index) {
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
                  onResize: _resizeSelected,
                  onRotate: _rotateSelected,
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
                onLockChanged: _toggleLayerLock,
                onAdd: _addTextLayer,
                onDelete: _deleteSelected,
                onDuplicate: _duplicateSelected,
                onMoveUp: _moveUp,
                onMoveDown: _moveDown,
              ),
              LayerProperties(
                layer: _currentLayer,
                onDelete: _deleteSelected,
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
