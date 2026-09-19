import 'package:flutter/material.dart';

import '../core/conversion/format_catalog.dart';
import '../core/models/workspace_item.dart';

class FormatActionConfig {
  final FormatOption format;
  final int quality;
  final String fileName;

  const FormatActionConfig({
    required this.format,
    required this.quality,
    required this.fileName,
  });
}

Future<FormatActionConfig?> showFormatActionSheet(
  BuildContext context, {
  required WorkspaceType type,
  required String initialName,
  String title = 'Export / Convert',
}) async {
  final options = FormatCatalog.forType(type);
  final currentExtension = _extensionOf(initialName);
  var selected = options.firstWhere(
    (item) => item.extension == currentExtension,
    orElse: () => options.first,
  );
  var quality = 85.0;
  final controller = TextEditingController(
    text: _baseName(initialName),
  );

  final result = await showModalBottomSheet<FormatActionConfig>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0E0D17),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final showQuality = type != WorkspaceType.text;
          return FractionallySizedBox(
            heightFactor: 0.84,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5546FF), Color(0xFF9B42FF)],
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.file_upload_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'File name',
                      suffixText: '.${selected.extension}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<FormatOption>(
                    initialValue: selected,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Output format',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: options
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              '.${item.extension.toUpperCase()} — ${item.label}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => selected = value);
                    },
                  ),
                  if (showQuality) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Text(
                          'Quality',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Text('${quality.round()}%'),
                      ],
                    ),
                    Slider(
                      min: 40,
                      max: 100,
                      value: quality,
                      onChanged: (value) => setSheetState(() => quality = value),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final rawName = controller.text.trim();
                        final name = rawName.isEmpty
                            ? 'Modivka-${DateTime.now().millisecondsSinceEpoch}'
                            : _baseName(rawName);
                        Navigator.pop(
                          sheetContext,
                          FormatActionConfig(
                            format: selected,
                            quality: quality.round(),
                            fileName: name,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  controller.dispose();
  return result;
}

String _extensionOf(String name) {
  final parts = name.split('.');
  return parts.length > 1 ? parts.last.toLowerCase() : '';
}

String _baseName(String name) {
  final index = name.lastIndexOf('.');
  return index > 0 ? name.substring(0, index) : name;
}
