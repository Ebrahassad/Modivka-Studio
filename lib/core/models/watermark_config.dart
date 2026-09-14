enum WatermarkType { single, tile }

enum PositioningMode { auto, manual }

enum AutoPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}

enum ExportFormat { jpg, png }

class WatermarkConfig {
  final WatermarkType type;
  final PositioningMode mode;
  final AutoPosition autoPosition;
  final ExportFormat exportFormat;
  final int quality;
  final double customXRatio;
  final double customYRatio;
  final double scaleRatio;
  final double rotation;
  final double opacity;
  final int tileSpacing;
  final bool removeLogoBg;

  const WatermarkConfig({
    this.type = WatermarkType.single,
    this.mode = PositioningMode.auto,
    this.autoPosition = AutoPosition.bottomRight,
    this.exportFormat = ExportFormat.jpg,
    this.quality = 95,
    this.customXRatio = 0.85,
    this.customYRatio = 0.85,
    this.scaleRatio = 0.15,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.tileSpacing = 120,
    this.removeLogoBg = false,
  });

  WatermarkConfig copyWith({
    WatermarkType? type,
    PositioningMode? mode,
    AutoPosition? autoPosition,
    ExportFormat? exportFormat,
    int? quality,
    double? customXRatio,
    double? customYRatio,
    double? scaleRatio,
    double? rotation,
    double? opacity,
    int? tileSpacing,
    bool? removeLogoBg,
  }) {
    return WatermarkConfig(
      type: type ?? this.type,
      mode: mode ?? this.mode,
      autoPosition: autoPosition ?? this.autoPosition,
      exportFormat: exportFormat ?? this.exportFormat,
      quality: quality ?? this.quality,
      customXRatio: customXRatio ?? this.customXRatio,
      customYRatio: customYRatio ?? this.customYRatio,
      scaleRatio: scaleRatio ?? this.scaleRatio,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      tileSpacing: tileSpacing ?? this.tileSpacing,
      removeLogoBg: removeLogoBg ?? this.removeLogoBg,
    );
  }
}
