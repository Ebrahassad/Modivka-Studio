import 'dart:typed_data';

enum WorkspaceType { image, text, video }

class WorkspaceItem {
  final String name;
  final String path;
  final WorkspaceType type;
  final Uint8List? bytes;

  const WorkspaceItem({
    required this.name,
    required this.path,
    required this.type,
    this.bytes,
  });
}
