import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/workspace_item.dart';

class FileService {
  const FileService();

  Future<List<WorkspaceItem>> openFiles({required WorkspaceType type}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: _extensions(type),
    );

    if (result == null) {
      return const [];
    }

    return result.files.map((file) {
      final bytes = file.bytes;

      return WorkspaceItem(
        name: file.name,
        path: file.path ?? '',
        type: type,
        bytes: bytes,
      );
    }).toList();
  }

  Future<WorkspaceItem?> openSingleImage() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: _extensions(WorkspaceType.image),
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;

    return WorkspaceItem(
      name: file.name,
      path: file.path ?? '',
      type: WorkspaceType.image,
      bytes: file.bytes,
    );
  }

  List<String> _extensions(WorkspaceType type) {
    switch (type) {
      case WorkspaceType.image:
        return ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'];

      case WorkspaceType.text:
        return ['txt', 'md', 'json', 'xml', 'csv', 'log'];

      case WorkspaceType.video:
        return ['mp4', 'mov', 'mkv', 'webm', 'avi', '3gp'];
    }
  }

  Future<String?> readText(String path) async {
    if (path.isEmpty) {
      return null;
    }

    try {
      return await File(path).readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> readBytes(String path) async {
    if (path.isEmpty) {
      return null;
    }

    try {
      return await File(path).readAsBytes();
    } catch (_) {
      return null;
    }
  }
}
