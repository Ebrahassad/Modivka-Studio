import 'package:flutter/material.dart';
import 'package:open_folder/open_folder.dart';
import 'package:share_plus/share_plus.dart';

import '../core/export/export_result.dart';

class ExportSuccessDialog extends StatelessWidget {
  final ExportResult result;

  const ExportSuccessDialog({
    super.key,
    required this.result,
  });

  static Future<void> show(
    BuildContext context,
    ExportResult result,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExportSuccessDialog(
        result: result,
      ),
    );
  }

  Future<void> _openFolder(BuildContext context) async {
    try {
      await OpenFolder.openFolder(result.outputDirectory);
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open folder'),
        ),
      );
    }
  }

  Future<void> _share(BuildContext context) async {
    if (result.savedPaths.isEmpty) return;

    try {
      await Share.shareXFiles(
        result.savedPaths.map((path) => XFile(path)).toList(),
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to share files'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Export Complete',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${result.successCount} / ${result.totalCount} files exported successfully.',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Saved to:',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                result.outputDirectory,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => _openFolder(context),
          icon: const Icon(
            Icons.folder_open_rounded,
          ),
          label: const Text('Open Folder'),
        ),
        OutlinedButton.icon(
          onPressed: () => _share(context),
          icon: const Icon(
            Icons.share_rounded,
          ),
          label: const Text('Share'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
