import 'package:flutter/material.dart';

import '../core/models/canvas_layer.dart';

class LayerProperties extends StatelessWidget {
  final CanvasLayer? layer;
  final VoidCallback? onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final ValueChanged<double> onXChanged;
  final ValueChanged<double> onYChanged;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onRotationChanged;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<bool> onLockChanged;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<String>? onFontFamilyChanged;
  final ValueChanged<double>? onFontSizeChanged;
  final ValueChanged<bool>? onBoldChanged;
  final ValueChanged<bool>? onItalicChanged;
  final ValueChanged<ColorValue>? onTextColorChanged;
  final ValueChanged<TextAlignment>? onTextAlignmentChanged;

  const LayerProperties({
    super.key,
    required this.layer,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onXChanged,
    required this.onYChanged,
    required this.onWidthChanged,
    required this.onHeightChanged,
    required this.onRotationChanged,
    required this.onOpacityChanged,
    required this.onLockChanged,
    required this.onTextChanged,
    this.onFontFamilyChanged,
    this.onFontSizeChanged,
    this.onBoldChanged,
    this.onItalicChanged,
    this.onTextColorChanged,
    this.onTextAlignmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final current = layer;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101016),
        border: Border(
          left: BorderSide(
            color: Colors.white.withAlpha(18),
          ),
        ),
      ),
      child: current == null
          ? const Center(
              child: Text(
                'Select a layer',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            )
          : ListView(
              children: [
                const Text(
                  'Layer Properties',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  current.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                if (current.type == LayerType.text) ...[
                  TextField(
                    controller: TextEditingController(
                      text: current.text,
                    ),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Text',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onTextChanged,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: current.fontFamily,
                    decoration: const InputDecoration(
                      labelText: 'Font',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Roboto',
                        child: Text('Roboto'),
                      ),
                      DropdownMenuItem(
                        value: 'sans-serif',
                        child: Text('Sans Serif'),
                      ),
                      DropdownMenuItem(
                        value: 'serif',
                        child: Text('Serif'),
                      ),
                      DropdownMenuItem(
                        value: 'monospace',
                        child: Text('Monospace'),
                      ),
                    ],
                    onChanged: onFontFamilyChanged == null
                        ? null
                        : (value) {
                            if (value != null) {
                              onFontFamilyChanged!(value);
                            }
                          },
                  ),
                  const SizedBox(height: 10),
                  _numberField(
                    label: 'Font Size',
                    value: current.fontSize,
                    onChanged: onFontSizeChanged ?? (_) {},
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bold'),
                    value: current.bold,
                    onChanged: onBoldChanged,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Italic'),
                    value: current.italic,
                    onChanged: onItalicChanged,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Text Alignment',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SegmentedButton<TextAlignment>(
                    segments: const [
                      ButtonSegment(
                        value: TextAlignment.left,
                        icon: Icon(Icons.format_align_left_rounded),
                      ),
                      ButtonSegment(
                        value: TextAlignment.center,
                        icon: Icon(Icons.format_align_center_rounded),
                      ),
                      ButtonSegment(
                        value: TextAlignment.right,
                        icon: Icon(Icons.format_align_right_rounded),
                      ),
                    ],
                    selected: {current.textAlignment},
                    onSelectionChanged: onTextAlignmentChanged == null
                        ? null
                        : (selection) {
                            onTextAlignmentChanged!(selection.first);
                          },
                  ),
                  const SizedBox(height: 14),
                ],
                _numberField(
                  label: 'X',
                  value: current.x,
                  onChanged: onXChanged,
                ),
                _numberField(
                  label: 'Y',
                  value: current.y,
                  onChanged: onYChanged,
                ),
                _numberField(
                  label: 'Width',
                  value: current.width,
                  onChanged: onWidthChanged,
                ),
                _numberField(
                  label: 'Height',
                  value: current.height,
                  onChanged: onHeightChanged,
                ),
                _numberField(
                  label: 'Rotation',
                  value: current.rotation * 180 / 3.141592653589793,
                  onChanged: (value) {
                    onRotationChanged(
                      value * 3.141592653589793 / 180,
                    );
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  'Opacity ${(current.opacity * 100).round()}%',
                ),
                Slider(
                  value: current.opacity.clamp(0.0, 1.0),
                  onChanged: onOpacityChanged,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lock'),
                  value: current.locked,
                  onChanged: onLockChanged,
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onMoveUp,
                        icon: const Icon(
                          Icons.arrow_upward_rounded,
                          size: 18,
                        ),
                        label: const Text('Up'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onMoveDown,
                        icon: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 18,
                        ),
                        label: const Text('Down'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                    ),
                    label: const Text('Delete Layer'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _numberField({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value.toStringAsFixed(1),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onFieldSubmitted: (text) {
          final parsed = double.tryParse(text);

          if (parsed != null) {
            onChanged(parsed);
          }
        },
      ),
    );
  }
}
