import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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

  Future<ExportResult?> saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    List<String>? allowedExtensions,
  }) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Save with Modivka Studio',
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (uri == null) {
      return null;
    }

    return ExportResult(
      path: uri.scheme == 'file' ? uri.toFilePath() : uri.toString(),
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
