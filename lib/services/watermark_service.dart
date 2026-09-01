import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/watermark_config.dart';

class WatermarkService {
  static Future<String> getOutputDirectoryPath() async {
    Directory? extDir;
    if (Platform.isAndroid) {
      extDir = Directory('/storage/emulated/0/Pictures/WatermarkPro');
      if (!await extDir.exists()) {
        await extDir.create(recursive: true);
      }
    } else {
      extDir = await getApplicationDocumentsDirectory();
    }
    return extDir.path;
  }

  static img.Image processLogoBackground(img.Image logoImage) {
    img.Image processedLogo = logoImage.convert(numChannels: 4);
    int width = processedLogo.width;
    int height = processedLogo.height;

    List<img.Pixel> cornerSamples = [
      processedLogo.getPixel(0, 0),
      processedLogo.getPixel(width - 1, 0),
      processedLogo.getPixel(0, height - 1),
      processedLogo.getPixel(width - 1, height - 1),
    ];

    for (var pixel in processedLogo) {
      int r = pixel.r.toInt();
      int g = pixel.g.toInt();
      int b = pixel.b.toInt();

      bool isBackground = false;
      for (var sample in cornerSamples) {
        int diffR = (r - sample.r.toInt()).abs();
        int diffG = (g - sample.g.toInt()).abs();
        int diffB = (b - sample.b.toInt()).abs();

        if ((diffR + diffG + diffB < 35) ||
            (r > 240 && g > 240 && b > 240 && sample.r > 240)) {
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

  static Future<Uint8List?> generateLogoPreviewBytes(
    File logoFile,
    bool removeBg,
  ) async {
    try {
      final logoBytes = await logoFile.readAsBytes();
      img.Image? logoImage = img.decodeImage(logoBytes);
      if (logoImage == null) return null;

      img.Image processedLogo = removeBg
          ? processLogoBackground(logoImage)
          : logoImage.convert(numChannels: 4);

      return Uint8List.fromList(img.encodePng(processedLogo));
    } catch (e) {
      return null;
    }
  }

  static Future<File?> processImage({
    required File targetImageFile,
    required File logoFile,
    required WatermarkConfig config,
  }) async {
    try {
      final targetBytes = await targetImageFile.readAsBytes();
      final logoBytes = await logoFile.readAsBytes();

      img.Image? originalImage = img.decodeImage(targetBytes);
      img.Image? logoImage = img.decodeImage(logoBytes);

      if (originalImage == null || logoImage == null) return null;

      if (config.removeLogoBg) {
        logoImage = processLogoBackground(logoImage);
      } else {
        logoImage = logoImage.convert(numChannels: 4);
      }

      int targetLogoWidth = (originalImage.width * config.scaleRatio).toInt();
      if (targetLogoWidth < 20) targetLogoWidth = 20;

      img.Image resizedLogo = img.copyResize(logoImage, width: targetLogoWidth);

      // تحويل زاوية التدوير من راديان إلى درجات (Degrees) لتتطابق تماماً مع المعاينة البصرية والحفظ
      if (config.rotation != 0) {
        double degrees = config.rotation * (180 / math.pi);
        resizedLogo = img.copyRotate(resizedLogo, angle: degrees);
      }

      if (config.opacity < 1.0) {
        for (var pixel in resizedLogo) {
          pixel.a = (pixel.a * config.opacity).toInt();
        }
      }

      int dstX = (originalImage.width * config.customXRatio).toInt() -
          (resizedLogo.width ~/ 2);
      int dstY = (originalImage.height * config.customYRatio).toInt() -
          (resizedLogo.height ~/ 2);

      int maxX = (originalImage.width - resizedLogo.width)
          .clamp(0, originalImage.width);
      int maxY = (originalImage.height - resizedLogo.height)
          .clamp(0, originalImage.height);
      dstX = dstX.clamp(0, maxX);
      dstY = dstY.clamp(0, maxY);

      img.compositeImage(
        originalImage,
        resizedLogo,
        dstX: dstX,
        dstY: dstY,
        blend: img.BlendMode.alpha,
      );

      final outDir = await getOutputDirectoryPath();
      final ext = config.exportFormat == ExportFormat.png ? 'png' : 'jpg';
      final fileName = 'WM_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final resultFile = File('$outDir/$fileName');

      final List<int> encodedBytes = config.exportFormat == ExportFormat.png
          ? img.encodePng(originalImage)
          : img.encodeJpg(originalImage, quality: config.quality);

      await resultFile.writeAsBytes(encodedBytes);
      return resultFile;
    } catch (e) {
      return null;
    }
  }
}
