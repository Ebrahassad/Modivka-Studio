import '../models/workspace_item.dart';

enum OutputKind { image, text, video }

class FormatOption {
  final String extension;
  final String label;
  final String mimeType;
  final OutputKind kind;

  const FormatOption({
    required this.extension,
    required this.label,
    required this.mimeType,
    required this.kind,
  });
}

class FormatCatalog {
  static const image = <FormatOption>[
    FormatOption(
        extension: 'png',
        label: 'PNG',
        mimeType: 'image/png',
        kind: OutputKind.image),
    FormatOption(
        extension: 'jpg',
        label: 'JPG',
        mimeType: 'image/jpeg',
        kind: OutputKind.image),
    FormatOption(
        extension: 'jpeg',
        label: 'JPEG',
        mimeType: 'image/jpeg',
        kind: OutputKind.image),
    FormatOption(
        extension: 'webp',
        label: 'WebP',
        mimeType: 'image/webp',
        kind: OutputKind.image),
    FormatOption(
        extension: 'gif',
        label: 'GIF',
        mimeType: 'image/gif',
        kind: OutputKind.image),
    FormatOption(
        extension: 'bmp',
        label: 'BMP',
        mimeType: 'image/bmp',
        kind: OutputKind.image),
    FormatOption(
        extension: 'tiff',
        label: 'TIFF',
        mimeType: 'image/tiff',
        kind: OutputKind.image),
    FormatOption(
        extension: 'tga',
        label: 'TGA',
        mimeType: 'image/x-tga',
        kind: OutputKind.image),
    FormatOption(
        extension: 'ico',
        label: 'ICO',
        mimeType: 'image/x-icon',
        kind: OutputKind.image),
  ];

  static const text = <FormatOption>[
    FormatOption(
        extension: 'txt',
        label: 'TXT',
        mimeType: 'text/plain',
        kind: OutputKind.text),
    FormatOption(
        extension: 'md',
        label: 'Markdown',
        mimeType: 'text/markdown',
        kind: OutputKind.text),
    FormatOption(
        extension: 'html',
        label: 'HTML',
        mimeType: 'text/html',
        kind: OutputKind.text),
    FormatOption(
        extension: 'css',
        label: 'CSS',
        mimeType: 'text/css',
        kind: OutputKind.text),
    FormatOption(
        extension: 'json',
        label: 'JSON',
        mimeType: 'application/json',
        kind: OutputKind.text),
    FormatOption(
        extension: 'xml',
        label: 'XML',
        mimeType: 'application/xml',
        kind: OutputKind.text),
    FormatOption(
        extension: 'csv',
        label: 'CSV',
        mimeType: 'text/csv',
        kind: OutputKind.text),
    FormatOption(
        extension: 'yaml',
        label: 'YAML',
        mimeType: 'application/yaml',
        kind: OutputKind.text),
    FormatOption(
        extension: 'log',
        label: 'LOG',
        mimeType: 'text/plain',
        kind: OutputKind.text),
    FormatOption(
        extension: 'sql',
        label: 'SQL',
        mimeType: 'text/plain',
        kind: OutputKind.text),
    FormatOption(
        extension: 'dart',
        label: 'Dart',
        mimeType: 'text/plain',
        kind: OutputKind.text),
    FormatOption(
        extension: 'js',
        label: 'JavaScript',
        mimeType: 'text/javascript',
        kind: OutputKind.text),
    FormatOption(
        extension: 'ts',
        label: 'TypeScript',
        mimeType: 'text/plain',
        kind: OutputKind.text),
  ];

  static const video = <FormatOption>[
    FormatOption(
        extension: 'mp4',
        label: 'MP4',
        mimeType: 'video/mp4',
        kind: OutputKind.video),
    FormatOption(
        extension: 'mov',
        label: 'MOV',
        mimeType: 'video/quicktime',
        kind: OutputKind.video),
    FormatOption(
        extension: 'mkv',
        label: 'MKV',
        mimeType: 'video/x-matroska',
        kind: OutputKind.video),
    FormatOption(
        extension: 'webm',
        label: 'WebM',
        mimeType: 'video/webm',
        kind: OutputKind.video),
    FormatOption(
        extension: 'avi',
        label: 'AVI',
        mimeType: 'video/x-msvideo',
        kind: OutputKind.video),
    FormatOption(
        extension: 'm4v',
        label: 'M4V',
        mimeType: 'video/x-m4v',
        kind: OutputKind.video),
    FormatOption(
        extension: '3gp',
        label: '3GP',
        mimeType: 'video/3gpp',
        kind: OutputKind.video),
    FormatOption(
        extension: 'mpeg',
        label: 'MPEG',
        mimeType: 'video/mpeg',
        kind: OutputKind.video),
    FormatOption(
        extension: 'mpg',
        label: 'MPG',
        mimeType: 'video/mpeg',
        kind: OutputKind.video),
    FormatOption(
        extension: 'gif',
        label: 'GIF',
        mimeType: 'image/gif',
        kind: OutputKind.video),
    FormatOption(
        extension: 'mp3',
        label: 'MP3 audio',
        mimeType: 'audio/mpeg',
        kind: OutputKind.video),
    FormatOption(
        extension: 'm4a',
        label: 'M4A audio',
        mimeType: 'audio/mp4',
        kind: OutputKind.video),
    FormatOption(
        extension: 'wav',
        label: 'WAV audio',
        mimeType: 'audio/wav',
        kind: OutputKind.video),
  ];

  static List<FormatOption> forType(WorkspaceType type) {
    switch (type) {
      case WorkspaceType.image:
        return image;
      case WorkspaceType.text:
        return text;
      case WorkspaceType.video:
        return video;
    }
  }
}
