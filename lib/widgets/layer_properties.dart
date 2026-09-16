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
