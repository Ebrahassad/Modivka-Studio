import 'dart:typed_data';

class ColorValue {
  final int red;
  final int green;
  final int blue;

  const ColorValue(this.red, this.green, this.blue);

  int get value =>
      (0xFF << 24) |
      ((red & 0xFF) << 16) |
      ((green & 0xFF) << 8) |
      (blue & 0xFF);
}

enum TextAlignment {
  left,
  center,
  right,
}

enum LayerType {
  image,
  text,
  video,
}

class CanvasLayer {
  final String id;
  String name;
  final LayerType type;
  final Uint8List? bytes;
  final String? path;

  String text;

  String fontFamily;
  double fontSize;
  bool bold;
  bool italic;
  bool underline;
  bool strikethrough;
  double letterSpacing;
  double lineHeight;
  ColorValue textColor;
  TextAlignment textAlignment;

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
    this.path,
    this.text = '',
    this.fontFamily = 'Roboto',
    this.fontSize = 32,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.letterSpacing = 0,
    this.lineHeight = 1.2,
    this.textColor = const ColorValue(255, 255, 255),
    this.textAlignment = TextAlignment.left,
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
