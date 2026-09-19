import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

class CompressionService {
  CompressionService();

  Future<Uint8List> zipFiles(List<String> paths, {int level = 6}) async {
    if (paths.isEmpty) {
      throw ArgumentError('No files selected.');
    }

    final temp = await getTemporaryDirectory();
    final zipPath = '${temp.path}/modivka_bundle_${DateTime.now().millisecondsSinceEpoch}.zip';
    final encoder = ZipFileEncoder();
    encoder.create(zipPath, level: level);

    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        await encoder.addFile(file, file.uri.pathSegments.last, level);
      }
    }

    await encoder.close();
    return File(zipPath).readAsBytes();
  }
}
