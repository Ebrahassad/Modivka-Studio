import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/watermark_config.dart';

class WatermarkEngine {
  const WatermarkEngine();

  /// Removes pixels that are sufficiently similar to the logo's corner
  /// colors. The result always has an alpha channel.
  img.Image removeBackground(img.Image logoImage) {
    final processedLogo = logoImage.convert(numChannels: 4);

    final width = processedLogo.width;
    final height = processedLogo.height;

    if (width == 0 || height == 0) {
      return processedLogo;
    }

    final cornerSamples = <img.Pixel>[
      processedLogo.getPixel(0, 0),
      processedLogo.getPixel(width - 1, 0),
      processedLogo.getPixel(0, height - 1),
      processedLogo.getPixel(width - 1, height - 1),
    ];

    for (final pixel in processedLogo) {
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      var isBackground = false;

      for (final sample in cornerSamples) {
        final diffR = (r - sample.r.toInt()).abs();
        final diffG = (g - sample.g.toInt()).abs();
        final diffB = (b - sample.b.toInt()).abs();

        if ((diffR + diffG + diffB < 35) ||
            (r > 240 &&
                g > 240 &&
                b > 240 &&
                sample.r > 240 &&
                sample.g > 240 &&
                sample.b > 240)) {
          isBackground = true;
          break;
        }
      }

      if (isBackground) {
        pixel.a = 0;
      }
    }

    return processedLogo;
  }

  /// Creates a transparent PNG preview of the logo.
  Uint8List? generateLogoPreview(
    Uint8List logoBytes, {
    bool removeBg = false,
  }) {
    try {
      final logoImage = img.decodeImage(logoBytes);
      if (logoImage == null) return null;

      final processedLogo = removeBg
          ? removeBackground(logoImage)
          : logoImage.convert(numChannels: 4);

      return Uint8List.fromList(img.encodePng(processedLogo));
    } catch (_) {
      return null;
    }
  }

  /// Processes one target image completely in memory.
  ///
  /// No files, paths, Flutter widgets, or platform APIs are used here.
  /// Input and output are raw image bytes, making this suitable as a
  /// reusable Modivka Core.
  Uint8List? process({
    required Uint8List targetBytes,
    required Uint8List logoBytes,
    required WatermarkConfig config,
  }) {
    try {
      final originalImage = img.decodeImage(targetBytes);
      var logoImage = img.decodeImage(logoBytes);

      if (originalImage == null || logoImage == null) {
        return null;
      }

      logoImage = config.removeLogoBg
          ? removeBackground(logoImage)
          : logoImage.convert(numChannels: 4);

      var targetLogoWidth =
          (originalImage.width * config.scaleRatio).toInt();

      if (targetLogoWidth < 20) {
        targetLogoWidth = 20;
      }

      var resizedLogo = img.copyResize(
        logoImage,
        width: targetLogoWidth,
      );

      if (config.rotation != 0) {
        final degrees = config.rotation * (180 / math.pi);
        resizedLogo = img.copyRotate(
          resizedLogo,
          angle: degrees,
        );
      }

      if (config.opacity < 1.0) {
        final opacity = config.opacity.clamp(0.0, 1.0);

        for (final pixel in resizedLogo) {
          pixel.a = (pixel.a * opacity).toInt();
        }
      }

      final dstX =
          (originalImage.width * config.customXRatio).toInt() -
          (resizedLogo.width ~/ 2);

      final dstY =
          (originalImage.height * config.customYRatio).toInt() -
          (resizedLogo.height ~/ 2);

      final maxX =
          (originalImage.width - resizedLogo.width)
              .clamp(0, originalImage.width);

      final maxY =
          (originalImage.height - resizedLogo.height)
              .clamp(0, originalImage.height);

      final safeX = dstX.clamp(0, maxX);
      final safeY = dstY.clamp(0, maxY);

      img.compositeImage(
        originalImage,
        resizedLogo,
        dstX: safeX,
        dstY: safeY,
        blend: img.BlendMode.alpha,
      );

      final encodedBytes = config.exportFormat == ExportFormat.png
          ? img.encodePng(originalImage)
          : img.encodeJpg(
              originalImage,
              quality: config.quality.clamp(0, 100),
            );

      return Uint8List.fromList(encodedBytes);
    } catch (_) {
      return null;
    }
  }
}
