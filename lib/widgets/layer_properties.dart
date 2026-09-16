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
  final ValueChanged<bool>? onUnderlineChanged;
  final ValueChanged<bool>? onStrikethroughChanged;
  final ValueChanged<double>? onLetterSpacingChanged;
  final ValueChanged<double>? onLineHeightChanged;
  final ValueChanged<ColorValue>? onTextColorChanged;
  final ValueChanged<TextAlignment>? onTextAlignmentChanged;
  final VoidCallback? onAlignLeft;
  final VoidCallback? onAlignCenterHorizontal;
  final VoidCallback? onAlignRight;
  final VoidCallback? onAlignTop;
  final VoidCallback? onAlignCenterVertical;
  final VoidCallback? onAlignBottom;

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
    this.onUnderlineChanged,
    this.onStrikethroughChanged,
    this.onLetterSpacingChanged,
    this.onLineHeightChanged,
    this.onTextColorChanged,
    this.onTextAlignmentChanged,
    this.onAlignLeft,
    this.onAlignCenterHorizontal,
    this.onAlignRight,
    this.onAlignTop,
    this.onAlignCenterVertical,
    this.onAlignBottom,
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Underline'),
                    value: current.underline,
                    onChanged: onUnderlineChanged,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Strikethrough'),
                    value: current.strikethrough,
                    onChanged: onStrikethroughChanged,
                  ),
                  _numberField(
                    label: 'Letter Spacing',
                    value: current.letterSpacing,
                    onChanged: onLetterSpacingChanged ?? (_) {},
                  ),
                  _numberField(
                    label: 'Line Height',
                    value: current.lineHeight,
                    onChanged: onLineHeightChanged ?? (_) {},
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
                  const SizedBox(height: 12),
                  _colorField(
                    context,
                    label: 'Text Color',
                    value: current.textColor,
                    onChanged: onTextColorChanged,
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
                const Text(
                  'Align Layer',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: IconButton(
                        tooltip: 'Align left',
                        onPressed: current.locked ? null : onAlignLeft,
                        icon: const Icon(Icons.align_horizontal_left_rounded),
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        tooltip: 'Center horizontally',
                        onPressed:
                            current.locked ? null : onAlignCenterHorizontal,
                        icon: const Icon(
                          Icons.align_horizontal_center_rounded,
                        ),
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        tooltip: 'Align right',
                        onPressed: current.locked ? null : onAlignRight,
                        icon: const Icon(
                          Icons.align_horizontal_right_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: IconButton(
                        tooltip: 'Align top',
                        onPressed: current.locked ? null : onAlignTop,
                        icon: const Icon(Icons.align_vertical_top_rounded),
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        tooltip: 'Center vertically',
                        onPressed:
                            current.locked ? null : onAlignCenterVertical,
                        icon: const Icon(
                          Icons.align_vertical_center_rounded,
                        ),
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        tooltip: 'Align bottom',
                        onPressed: current.locked ? null : onAlignBottom,
                        icon: const Icon(
                          Icons.align_vertical_bottom_rounded,
                        ),
                      ),
                    ),
                  ],
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

  Widget _colorField(
    BuildContext context, {
    required String label,
    required ColorValue value,
    required ValueChanged<ColorValue>? onChanged,
  }) {
    final color = Color(value.value);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onChanged == null
          ? null
          : () async {
              final result = await showDialog<ColorValue>(
                context: context,
                builder: (dialogContext) {
                  return _TextColorDialog(
                    initialColor: value,
                  );
                },
              );

              if (result != null) {
                onChanged(result);
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withAlpha(35),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: Colors.white.withAlpha(55),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '#${value.red.toRadixString(16).padLeft(2, '0').toUpperCase()}'
              '${value.green.toRadixString(16).padLeft(2, '0').toUpperCase()}'
              '${value.blue.toRadixString(16).padLeft(2, '0').toUpperCase()}',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
            ),
          ],
        ),
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

class _TextColorDialog extends StatefulWidget {
  final ColorValue initialColor;

  const _TextColorDialog({
    required this.initialColor,
  });

  @override
  State<_TextColorDialog> createState() => _TextColorDialogState();
}

class _TextColorDialogState extends State<_TextColorDialog> {
  late double red;
  late double green;
  late double blue;

  @override
  void initState() {
    super.initState();
    red = widget.initialColor.red.toDouble();
    green = widget.initialColor.green.toDouble();
    blue = widget.initialColor.blue.toDouble();
  }

  ColorValue get colorValue => ColorValue(
        red.round(),
        green.round(),
        blue.round(),
      );

  Color get color => Color(colorValue.value);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Text Color'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 72,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withAlpha(45),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _channelSlider(
              label: 'Red',
              value: red,
              onChanged: (value) {
                setState(() => red = value);
              },
            ),
            _channelSlider(
              label: 'Green',
              value: green,
              onChanged: (value) {
                setState(() => green = value);
              },
            ),
            _channelSlider(
              label: 'Blue',
              value: blue,
              onChanged: (value) {
                setState(() => blue = value);
              },
            ),
            const SizedBox(height: 8),
            Text(
              '#${colorValue.red.toRadixString(16).padLeft(2, '0').toUpperCase()}'
              '${colorValue.green.toRadixString(16).padLeft(2, '0').toUpperCase()}'
              '${colorValue.blue.toRadixString(16).padLeft(2, '0').toUpperCase()}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(colorValue);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _channelSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(label),
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            value: value,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
