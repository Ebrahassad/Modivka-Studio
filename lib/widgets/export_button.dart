import 'package:flutter/material.dart';

class ExportButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool processing;
  final int current;
  final int total;
  final String label;

  const ExportButton({
    super.key,
    required this.onPressed,
    this.processing = false,
    this.current = 0,
    this.total = 0,
    this.label = 'Export',
  });

  @override
  Widget build(BuildContext context) {
    final disabled = processing || onPressed == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: disabled ? null : onPressed,
          icon: processing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.download_rounded,
                ),
          label: Text(
            processing && total > 0 ? '$label $current/$total' : label,
          ),
        ),
        if (processing && total > 0) ...[
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: (current / total).clamp(0.0, 1.0),
              minHeight: 5,
            ),
          ),
        ],
      ],
    );
  }
}
