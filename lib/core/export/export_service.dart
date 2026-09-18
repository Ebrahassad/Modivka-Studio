import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportResult {
  final String path;
  final String fileName;

  const ExportResult({
    required this.path,
    required this.fileName,
  });
}

class ExportService {
  const ExportService();

  Future<ExportResult> saveBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(bytes, flush: true);

    return ExportResult(
      path: file.path,
      fileName: fileName,
    );
  }

  Future<void> shareFile(String path) async {
    if (path.isEmpty) {
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'Modivka Studio',
      ),
    );
  }
}
