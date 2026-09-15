import 'dart:typed_data';

import '../export/export_result.dart';
import '../export/export_service.dart';
import '../models/watermark_config.dart';

/// Legacy compatibility wrapper.
///
/// New modules should use ExportService directly.
/// Watermark keeps this wrapper so the old core API remains available
/// without writing to Pictures/WatermarkPro.
class WatermarkOutput {
  static Future<ExportResult?> save(
    Uint8List bytes,
    ExportFormat format,
  ) async {
    final extension = format == ExportFormat.png ? 'png' : 'jpg';

    return const ExportService().exportBytes(
      module: 'Watermark',
      files: [bytes],
      extension: extension,
      prefix: 'Watermark',
    );
  }
}
