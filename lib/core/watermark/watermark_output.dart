import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/watermark_config.dart';

class WatermarkOutput {
  static Future<File?> save(
    Uint8List bytes,
    ExportFormat format,
  ) async {
    try {
      Directory? outDir;

      if (Platform.isAndroid) {
        outDir = Directory(
          '/storage/emulated/0/Pictures/WatermarkPro',
        );

        if (!await outDir.exists()) {
          await outDir.create(recursive: true);
        }
      } else {
        outDir = await getApplicationDocumentsDirectory();
      }

      final extension =
          format == ExportFormat.png ? 'png' : 'jpg';

      final fileName =
          'WM_${DateTime.now().millisecondsSinceEpoch}.$extension';

      final file = File('${outDir.path}/$fileName');

      await file.writeAsBytes(bytes);

      return file;
    } catch (_) {
      return null;
    }
  }
}
