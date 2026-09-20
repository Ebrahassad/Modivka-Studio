import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../conversion/format_catalog.dart';
import '../models/canvas_layer.dart';
import '../models/studio_session.dart';

class UnifiedExportResult {
  const UnifiedExportResult({
    required this.path,
    required this.fileName,
    required this.outputKind,
    this.note,
  });

  final String path;
  final String fileName;
  final OutputKind outputKind;
  final String? note;
}

class UnifiedExportService {
  const UnifiedExportService();

  Future<UnifiedExportResult> exportToDirectory({
    required StudioSession session,
    required String directoryPath,
    required FormatOption format,
    required String baseName,
    int quality = 85,
  }) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    switch (format.kind) {
      case OutputKind.image:
        final bytes = await renderImage(session);
        final resultBytes = await _encodeImage(
          bytes,
          format.extension,
          quality,
        );
        final path =
            '${directory.path}/${_safeName(baseName)}.${format.extension}';
        await File(path).writeAsBytes(resultBytes, flush: true);
        return UnifiedExportResult(
          path: path,
          fileName: File(path).uri.pathSegments.last,
          outputKind: format.kind,
          note: _staticExportNote(session),
        );

      case OutputKind.text:
        final bytes = Uint8List.fromList(
          _encodeText(
            session,
            format.extension,
          ),
        );
        final path =
            '${directory.path}/${_safeName(baseName)}.${format.extension}';
        await File(path).writeAsBytes(bytes, flush: true);
        return UnifiedExportResult(
          path: path,
          fileName: File(path).uri.pathSegments.last,
          outputKind: format.kind,
          note: _textExportNote(session),
        );

      case OutputKind.video:
        final outputPath = await _exportVideo(
          session,
          directory,
          format,
          baseName,
          quality,
        );
        return UnifiedExportResult(
          path: outputPath,
          fileName: File(outputPath).uri.pathSegments.last,
          outputKind: format.kind,
          note: _videoExportNote(session),
        );
    }
  }

  Future<Uint8List> renderImage(StudioSession session) async {
    const width = 1200.0;
    const height = 800.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final images = <ui.Image>[];

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );

    try {
      final main = session.mainLayer;
      if (main != null) {
        if (main.type == LayerType.image && main.bytes != null) {
          final image = await _decodeImage(main.bytes!);
          images.add(image);
          _drawImageFit(
              canvas, image, const Rect.fromLTWH(0, 0, width, height));
        } else if (main.type == LayerType.text) {
          await _drawLayer(canvas, main, images);
        } else if (main.type == LayerType.video && main.path != null) {
          final frame = await _captureVideoFrame(main.path!);
          if (frame != null) {
            final image = await _decodeImage(frame);
            images.add(image);
            _drawImageFit(
                canvas, image, const Rect.fromLTWH(0, 0, width, height));
          }
        }
      }

      for (final layer in session.layers.where((layer) => layer.visible)) {
        if (layer == main || layer.type == LayerType.video) {
          continue;
        }
        await _drawLayer(canvas, layer, images);
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      for (final image in images) {
        image.dispose();
      }
    }
  }

  Future<Uint8List> _encodeImage(
    Uint8List pngBytes,
    String extension,
    int quality,
  ) async {
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) {
      throw const FormatException('Unable to encode exported image.');
    }

    late List<int> encoded;
    switch (extension.toLowerCase()) {
      case 'png':
        encoded = img.encodePng(decoded);
        break;
      case 'jpg':
      case 'jpeg':
        encoded = img.encodeJpg(decoded, quality: quality);
        break;
      case 'webp':
        encoded = img.encodeWebP(decoded, quality: quality, lossless: false);
        break;
      case 'gif':
        encoded = img.encodeGif(decoded);
        break;
      case 'bmp':
        encoded = img.encodeBmp(decoded);
        break;
      case 'tiff':
        encoded = img.encodeTiff(decoded);
        break;
      case 'tga':
        encoded = img.encodeTga(decoded);
        break;
      case 'ico':
        encoded = img.encodeIco(decoded);
        break;
      default:
        throw FormatException('Unsupported image output: .$extension');
    }

    return Uint8List.fromList(encoded);
  }

  Future<void> _drawLayer(
    Canvas canvas,
    CanvasLayer layer,
    List<ui.Image> images,
  ) async {
    canvas.save();
    canvas.translate(layer.x + layer.width / 2, layer.y + layer.height / 2);
    canvas.rotate(layer.rotation);
    canvas.scale(
      layer.flipHorizontal ? -1 : 1,
      layer.flipVertical ? -1 : 1,
    );
    canvas.translate(-layer.width / 2, -layer.height / 2);

    if (layer.type == LayerType.image && layer.bytes != null) {
      final image = await _decodeImage(layer.bytes!);
      images.add(image);
      final paint = Paint()
        ..filterQuality = FilterQuality.high
        ..color = Colors.white.withAlpha((layer.opacity * 255).round());
      _drawImageFit(
        canvas,
        image,
        Rect.fromLTWH(0, 0, layer.width, layer.height),
        paint: paint,
      );
    } else if (layer.type == LayerType.text) {
      final painter = TextPainter(
        text: TextSpan(
          text: layer.text.isEmpty ? layer.name : layer.text,
          style: TextStyle(
            color: Color(layer.textColor.value)
                .withAlpha((layer.opacity * 255).round()),
            fontFamily: layer.fontFamily,
            fontSize: layer.fontSize,
            fontWeight: layer.bold ? FontWeight.w700 : FontWeight.w400,
            fontStyle: layer.italic ? FontStyle.italic : FontStyle.normal,
            letterSpacing: layer.letterSpacing,
            height: layer.lineHeight,
            decoration: _decoration(layer),
          ),
        ),
        textAlign: _textAlign(layer.textAlignment),
        textDirection: TextDirection.ltr,
        maxLines: null,
      )..layout(maxWidth: layer.width);
      painter.paint(canvas, const Offset(0, 0));
    }

    canvas.restore();
  }

  void _drawImageFit(
    Canvas canvas,
    ui.Image image,
    Rect destination, {
    Paint? paint,
  }) {
    final srcWidth = image.width.toDouble();
    final srcHeight = image.height.toDouble();
    final scale = math.min(
      destination.width / srcWidth,
      destination.height / srcHeight,
    );
    final drawWidth = srcWidth * scale;
    final drawHeight = srcHeight * scale;
    final left = destination.left + (destination.width - drawWidth) / 2;
    final top = destination.top + (destination.height - drawHeight) / 2;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, srcWidth, srcHeight),
      Rect.fromLTWH(left, top, drawWidth, drawHeight),
      paint ?? Paint()
        ..filterQuality = FilterQuality.high,
    );
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<Uint8List?> _captureVideoFrame(String path) async {
    final temporary = await getTemporaryDirectory();
    final output =
        '${temporary.path}/modivka_frame_${DateTime.now().microsecondsSinceEpoch}.png';
    final session = await FFmpegKit.execute(
      '-y -ss 0 -i ${_quote(path)} -frames:v 1 -f image2 ${_quote(output)}',
    );
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code) || !File(output).existsSync()) {
      return null;
    }
    try {
      return await File(output).readAsBytes();
    } finally {
      try {
        await File(output).delete();
      } catch (_) {
        // Temporary frame cleanup is best-effort.
      }
    }
  }

  Future<String> _exportVideo(
    StudioSession session,
    Directory directory,
    FormatOption format,
    String baseName,
    int quality,
  ) async {
    final videoLayers = session.layers.where(
      (layer) =>
          layer.visible &&
          layer.type == LayerType.video &&
          layer.path != null &&
          layer.path!.isNotEmpty,
    );

    final base = videoLayers.isNotEmpty ? videoLayers.first : null;
    if (base == null) {
      throw StateError(
        'A visible local video layer is required for video export.',
      );
    }

    final extension = format.extension.toLowerCase();
    final output = File(
      '${directory.path}/${_safeName(baseName)}.$extension',
    );

    if ({'mp3', 'm4a', 'wav'}.contains(extension)) {
      final command = switch (extension) {
        'mp3' =>
          '-y -i ${_quote(base.path!)} -vn -c:a libmp3lame -q:a 4 ${_quote(output.path)}',
        'm4a' =>
          '-y -i ${_quote(base.path!)} -vn -c:a aac -b:a 160k ${_quote(output.path)}',
        _ =>
          '-y -i ${_quote(base.path!)} -vn -c:a pcm_s16le ${_quote(output.path)}',
      };
      await _runFfmpeg(command, output.path);
      return output.path;
    }

    final overlayBytes = await _renderVideoOverlay(session, base.id);
    final temp = await getTemporaryDirectory();
    final overlayPath =
        '${temp.path}/modivka_overlay_${DateTime.now().microsecondsSinceEpoch}.png';
    await File(overlayPath).writeAsBytes(overlayBytes, flush: true);

    try {
      final filter = '[1:v][0:v]scale2ref=w=main_w:h=main_h[overlay][base];'
          '[base][overlay]overlay=0:0:shortest=1[outv]';

      final encoding = _videoEncoding(extension, quality);
      final command =
          '-y -i ${_quote(base.path!)} -loop 1 -i ${_quote(overlayPath)} '
          '-filter_complex "$filter" -map "[outv]" -map 0:a? '
          '$encoding -shortest ${_quote(output.path)}';

      await _runFfmpeg(command, output.path);
      return output.path;
    } finally {
      try {
        await File(overlayPath).delete();
      } catch (_) {
        // Temporary overlay cleanup is best-effort.
      }
    }
  }

  Future<Uint8List> _renderVideoOverlay(
    StudioSession session,
    String baseVideoId,
  ) async {
    const width = 1200.0;
    const height = 800.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final images = <ui.Image>[];

    try {
      for (final layer in session.layers.where((layer) => layer.visible)) {
        if (layer.id == baseVideoId || layer.type == LayerType.video) {
          continue;
        }
        await _drawLayer(canvas, layer, images);
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      for (final image in images) {
        image.dispose();
      }
    }
  }

  Future<void> _runFfmpeg(String command, String outputPath) async {
    final session = await FFmpegKit.execute(command);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code) || !File(outputPath).existsSync()) {
      final logs = await session.getOutput();
      throw StateError(logs ?? 'Video export failed.');
    }
  }

  String _videoEncoding(String extension, int quality) {
    final crf = 34 - ((quality.clamp(40, 95) - 40) ~/ 4);
    final qv = 8 - ((quality.clamp(40, 95) - 40) ~/ 10);

    switch (extension) {
      case 'webm':
        return '-c:v libvpx-vp9 -crf $crf -b:v 0 -c:a libopus';
      case 'gif':
        return '-an -r 12 -vf "fps=12,scale=720:-2:flags=lanczos"';
      default:
        return '-c:v mpeg4 -q:v $qv -pix_fmt yuv420p -c:a aac -b:a 128k';
    }
  }

  List<int> _encodeText(StudioSession session, String extension) {
    final texts = session.layers
        .where((layer) => layer.visible && layer.type == LayerType.text)
        .map((layer) => layer.text.isEmpty ? layer.name : layer.text)
        .toList();
    final plain = texts.join('\n\n');
    final name = session.name.replaceAll(RegExp(r'"'), '\\"');

    switch (extension.toLowerCase()) {
      case 'json':
        return utf8.encode(
          jsonEncode(<String, dynamic>{
            'document': name,
            'layers': texts,
          }),
        );
      case 'html':
        return utf8.encode(
          '<!doctype html><html><head><meta charset="utf-8">'
          '<title>$name</title></head><body>'
          '${texts.map(_htmlEscape).map((value) => '<p>$value</p>').join()}'
          '</body></html>',
        );
      case 'xml':
        return utf8.encode(
          '<modivka document="$name">'
          '${texts.map((value) => '<text>${_xmlEscape(value)}</text>').join()}'
          '</modivka>',
        );
      case 'csv':
        final csvRows = texts.asMap().entries.map((entry) {
          final value = entry.value.replaceAll('"', '""');
          return '${entry.key + 1},"$value"';
        }).join('\n');

        return utf8.encode('layer,text\n$csvRows');
      case 'yaml':
        return utf8.encode(
          'document: "$name"\nlayers:\n${texts.map((value) => '  - "${value.replaceAll('"', '\\"')}"').join('\n')}',
        );
      default:
        return utf8.encode(plain);
    }
  }

  String _htmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  TextDecoration _decoration(CanvasLayer layer) {
    final decorations = <TextDecoration>[];
    if (layer.underline) decorations.add(TextDecoration.underline);
    if (layer.strikethrough) decorations.add(TextDecoration.lineThrough);
    return switch (decorations.length) {
      0 => TextDecoration.none,
      1 => decorations.first,
      _ => TextDecoration.combine(decorations),
    };
  }

  TextAlign _textAlign(TextAlignment alignment) {
    switch (alignment) {
      case TextAlignment.left:
        return TextAlign.left;
      case TextAlignment.center:
        return TextAlign.center;
      case TextAlignment.right:
        return TextAlign.right;
    }
  }

  String? _staticExportNote(StudioSession session) {
    if (session.layers
        .any((layer) => layer.visible && layer.type == LayerType.video)) {
      return 'Video layers are omitted from a still-image export.';
    }
    return null;
  }

  String? _textExportNote(StudioSession session) {
    if (session.layers.any((layer) =>
        layer.visible &&
        (layer.type == LayerType.image || layer.type == LayerType.video))) {
      return 'Media layers are omitted from a text export.';
    }
    return null;
  }

  String? _videoExportNote(StudioSession session) {
    final count = session.layers
        .where(
          (layer) => layer.visible && layer.type == LayerType.video,
        )
        .length;
    if (count > 1) {
      return 'The first visible video layer is used as the video base; image and text layers are composited over it.';
    }
    return null;
  }

  String _safeName(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');

  String _quote(String value) => "'${value.replaceAll("'", "'\\''")}'";
}
