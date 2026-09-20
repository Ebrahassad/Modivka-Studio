import 'canvas_layer.dart';

class StudioSession {
  StudioSession({
    required this.id,
    required this.name,
    List<CanvasLayer>? layers,
    this.dirty = false,
    this.savedAt,
    this.selectedLayerId,
  }) : layers = layers ?? <CanvasLayer>[];

  final String id;
  String name;
  final List<CanvasLayer> layers;
  bool dirty;
  DateTime? savedAt;
  String? selectedLayerId;

  bool get hasDocument => layers.isNotEmpty;
  CanvasLayer? get mainLayer => layers.isEmpty ? null : layers.first;
}
