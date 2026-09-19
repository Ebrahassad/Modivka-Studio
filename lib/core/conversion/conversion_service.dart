import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../models/workspace_item.dart';

class ConversionResult {
  final Uint8List bytes;
  final String extension;
  final String fileName;

  const ConversionResult({
    required this.bytes,
    required this.extension,
    required this.fileName,
  });
}

class ConversionService {
  const ConversionService();

  Future<ConversionResult> convert({
    required WorkspaceType type,
    required String inputPath,
    Uint8List? inputBytes,
    required String outputExtension,
    required String baseName,
    int quality = 85,
  }) async {
    switch (type) {
      case WorkspaceType.image:
        return _convertImage(
          inputPath: inputPath,
          inputBytes: inputBytes,
          outputExtension: outputExtension,
          baseName: baseName,
          quality: quality,
        );
      case WorkspaceType.text:
        return _convertText(
          inputPath: inputPath,
          inputBytes: inputBytes,
          outputExtension: outputExtension,
          baseName: baseName,
        );
      case WorkspaceType.video:
        return _convertVideo(
          inputPath: inputPath,
          outputExtension: outputExtension,
          baseName: baseName,
          quality: quality,
        );
    }
  }

  Future<ConversionResult> _convertImage({
    required String inputPath,
    required Uint8List? inputBytes,
    required String outputExtension,
    required String baseName,
    required int quality,
  }) async {
    final bytes = inputBytes ?? await File(inputPath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('The selected image could not be decoded.');
    }

    final ext = outputExtension.toLowerCase();
    late final List<int> encoded;

    switch (ext) {
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
        throw FormatException('Unsupported image output: .$ext');
    }

    return ConversionResult(
      bytes: Uint8List.fromList(encoded),
      extension: ext,
      fileName: '$baseName.$ext',
    );
  }

  Future<ConversionResult> _convertText({
    required String inputPath,
    required Uint8List? inputBytes,
    required String outputExtension,
    required String baseName,
  }) async {
    final bytes = inputBytes ?? await File(inputPath).readAsBytes();
    final ext = outputExtension.toLowerCase();
    return ConversionResult(
      bytes: bytes,
      extension: ext,
      fileName: '$baseName.$ext',
    );
  }

  Future<ConversionResult> _convertVideo({
    required String inputPath,
    required String outputExtension,
    required String baseName,
    required int quality,
  }) async {
    if (inputPath.isEmpty) {
      throw const FileSystemException('A local video path is required.');
    }

    final temp = await getTemporaryDirectory();
    final outputPath = '${temp.path}/${_safeName(baseName)}.$outputExtension';
    final input = _shellQuote(inputPath);
    final output = _shellQuote(outputPath);
    final ext = outputExtension.toLowerCase();

    final command = _videoCommand(input, output, ext, quality);
    final session = await FFmpegKit.execute(command);
    final code = await session.getReturnCode();

    if (!ReturnCode.isSuccess(code) || !File(outputPath).existsSync()) {
      final logs = await session.getOutput();
      throw StateError(logs ?? 'Video conversion failed.');
    }

    final bytes = await File(outputPath).readAsBytes();
    return ConversionResult(
      bytes: bytes,
      extension: ext,
      fileName: '${_safeName(baseName)}.$ext',
    );
  }

  String _videoCommand(String input, String output, String ext, int quality) {
    switch (ext) {
      case 'gif':
        return '-y -i $input -vf "fps=12,scale=720:-2:flags=lanczos" -an $output';
      case 'mp3':
        return '-y -i $input -vn -c:a libmp3lame -q:a 4 $output';
      case 'm4a':
        return '-y -i $input -vn -c:a aac -b:a 160k $output';
      case 'wav':
        return '-y -i $input -vn -c:a pcm_s16le $output';
      case 'webm':
        return '-y -i $input -c:v libvpx-vp9 -crf ${_crf(quality)} -b:v 0 -c:a libopus $output';
      case 'mp4':
      case 'm4v':
      case 'mov':
      case 'mkv':
      case 'avi':
      case '3gp':
      case 'mpeg':
      case 'mpg':
      default:
        return '-y -i $input -c:v mpeg4 -q:v ${_qv(quality)} -c:a aac -b:a 128k $output';
    }
  }

  int _crf(int quality) => 34 - ((quality.clamp(40, 95) - 40) ~/ 4);

  int _qv(int quality) => 8 - ((quality.clamp(40, 95) - 40) ~/ 10);

  String _safeName(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');

  String _shellQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";
}
