import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/workspace_item.dart';

class FileService {
  const FileService();

  Future<List<WorkspaceItem>> openFiles({
    required WorkspaceType type,
  }) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _extensions(type),
    );

    if (files.isEmpty) {
      return const [];
    }

    return files.map((file) {
      return WorkspaceItem(
        name: file.name,
        path: file.path ?? '',
        type: type,
        bytes: _readPlatformFileBytes(file),
      );
    }).toList();
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
      path: file.path ?? '',
      type: WorkspaceType.image,
      bytes: _readPlatformFileBytes(file),
    );
  }

  Uint8List? _readPlatformFileBytes(PlatformFile file) {
    if (file.path == null || file.path!.isEmpty) {
      return null;
    }

    try {
      return File(file.path!).readAsBytesSync();
    } catch (_) {
      return null;
    }
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
