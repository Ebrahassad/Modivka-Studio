import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'export_result.dart';

typedef ExportProgressCallback = void Function(
  int current,
  int total,
);

class ExportService {
  const ExportService();

  Future<Directory> moduleDirectory(String module) async {
    Directory root;

    if (Platform.isAndroid) {
      root = Directory('/storage/emulated/0/Modivka Studio');
    } else {
      root = await getApplicationDocumentsDirectory();
    }

    final directory = Directory(
      '${root.path}/$module',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<ExportResult> exportBytes({
    required String module,
    required List<Uint8List> files,
    required String extension,
    String prefix = 'Export',
    ExportProgressCallback? onProgress,
  }) async {
    final directory = await moduleDirectory(module);

    final savedPaths = <String>[];

    for (var i = 0; i < files.length; i++) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final file = File(
        '${directory.path}/${prefix}_${timestamp}_$i.$extension',
      );

      try {
        await file.writeAsBytes(files[i]);
        savedPaths.add(file.path);
      } catch (_) {
        // Continue with the remaining files.
      }

      onProgress?.call(i + 1, files.length);
    }

    return ExportResult(
      successCount: savedPaths.length,
      totalCount: files.length,
      outputDirectory: directory.path,
      savedPaths: savedPaths,
    );
  }
}
