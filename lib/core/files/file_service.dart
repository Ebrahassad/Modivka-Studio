import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/workspace_item.dart';

class FileService {
  const FileService();

  Future<List<WorkspaceItem>> openFiles({required WorkspaceType type}) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _extensions(type),
    );

    final items = <WorkspaceItem>[];
    for (final file in files) {
      items.add(
        WorkspaceItem(
          name: file.name,
          path: _pathOf(file),
          type: type,
          bytes: await file.readAsBytes(),
        ),
      );
    }
    return items;
  }

  Future<WorkspaceItem?> openSingleImage() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: _extensions(WorkspaceType.image),
    );

    if (file == null) {
      return null;
    }

    return WorkspaceItem(
      name: file.name,
      path: _pathOf(file),
      type: WorkspaceType.image,
      bytes: await file.readAsBytes(),
    );
  }

  String _pathOf(PlatformFile file) {
    final path = file.path;
    if (path != null && path.isNotEmpty) {
      return path;
    }
    if (file.uri.scheme == 'file') {
      return file.uri.toFilePath();
    }
    return '';
  }

  Future<Uint8List?> readBytes(String path) async {
    if (path.isEmpty) return null;
    try {
      return await File(path).readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<String?> readText(String path) async {
    final bytes = await readBytes(path);
    if (bytes == null) return null;
    return String.fromCharCodes(bytes);
  }

  Future<Uint8List?> readBytesFromFile(PlatformFile file) async {
    try {
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  List<String> _extensions(WorkspaceType type) {
    switch (type) {
      case WorkspaceType.image:
        return ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif', 'tiff', 'tga', 'ico'];
      case WorkspaceType.text:
        return ['txt', 'md', 'html', 'css', 'json', 'xml', 'csv', 'yaml', 'log', 'sql', 'dart', 'js', 'ts'];
      case WorkspaceType.video:
        return ['mp4', 'mov', 'mkv', 'webm', 'avi', 'm4v', '3gp', 'mpeg', 'mpg', 'm3u8'];
    }
  }
}
