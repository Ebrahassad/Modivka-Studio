import 'dart:typed_data';

enum LayerType {
  image,
  text,
}

class CanvasLayer {
  final String id;
  String name;
  final LayerType type;
  final Uint8List? bytes;

  String text;

  double x;
  double y;
  double width;
  double height;
  double rotation;
  double opacity;

  bool visible;
  bool locked;

  CanvasLayer({
    required this.id,
    required this.name,
    required this.type,
    this.bytes,
    this.text = '',
    this.x = 0,
    this.y = 0,
    this.width = 300,
    this.height = 300,
    this.rotation = 0,
    this.opacity = 1,
    this.visible = true,
    this.locked = false,
  });
}
