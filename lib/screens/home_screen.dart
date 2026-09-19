import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/compression/compression_service.dart';
import '../core/conversion/conversion_service.dart';
import '../core/conversion/format_catalog.dart';
import '../core/export/export_service.dart';
import '../core/files/file_service.dart';
import '../core/models/workspace_item.dart';
import '../modules/images/images_workspace.dart';
import '../modules/text/text_workspace.dart';
import '../modules/video/video_workspace.dart';
import '../widgets/format_actions.dart';
import '../widgets/module_tabs.dart';
import '../widgets/top_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fileService = const FileService();
  final _exportService = const ExportService();
  final _conversionService = const ConversionService();
  final _compressionService = CompressionService();

  int _moduleIndex = 0;
  final List<WorkspaceItem> _images = [];
  final List<WorkspaceItem> _texts = [];
  final List<WorkspaceItem> _videos = [];

  int _selectedImage = 0;
  int _selectedText = 0;
  int _selectedVideo = 0;
  bool _showStatus = true;

  List<WorkspaceItem> get _activeItems {
    switch (_moduleIndex) {
      case 0:
        return _images;
      case 1:
        return _texts;
      case 2:
        return _videos;
      default:
        return const [];
    }
  }

  int get _activeSelectedIndex {
    switch (_moduleIndex) {
      case 0:
        return _selectedImage;
      case 1:
        return _selectedText;
      case 2:
        return _selectedVideo;
      default:
        return 0;
    }
  }

  WorkspaceType get _activeType => WorkspaceType.values[_moduleIndex];

  WorkspaceItem? get _currentItem {
    final items = _activeItems;
    final index = _activeSelectedIndex;
    if (index < 0 || index >= items.length) return null;
    return items[index];
  }

  void _setSelected(int index) {
    setState(() {
      switch (_moduleIndex) {
        case 0:
          _selectedImage = index;
          break;
        case 1:
          _selectedText = index;
          break;
        case 2:
          _selectedVideo = index;
          break;
      }
    });
  }

  Future<void> _openActive() async {
    final items = await _fileService.openFiles(type: _activeType);
    if (!mounted || items.isEmpty) return;

    setState(() {
      switch (_activeType) {
        case WorkspaceType.image:
          _images.addAll(items);
          _selectedImage = _images.length - items.length;
          break;
        case WorkspaceType.text:
          _texts.addAll(items);
          _selectedText = _texts.length - items.length;
          break;
        case WorkspaceType.video:
          _videos.addAll(items);
          _selectedVideo = _videos.length - items.length;
          break;
      }
    });
    _message('${items.length} file${items.length == 1 ? '' : 's'} opened.');
  }

  Future<void> _addImageLayer() async {
    final item = await _fileService.openSingleImage();
    if (!mounted || item == null) return;
    setState(() {
      _images.add(item);
      _selectedImage = _images.length - 1;
    });
    _message('${item.name} added.');
  }

  void _newProject() {
    setState(() {
      _images.clear();
      _texts.clear();
      _videos.clear();
      _selectedImage = 0;
      _selectedText = 0;
      _selectedVideo = 0;
    });
    _message('New project created.');
  }

  Future<void> _saveCurrent() async {
    final item = _currentItem;
    if (item == null) {
      _message('Nothing is selected.');
      return;
    }

    final bytes = await _bytesFor(item);
    if (bytes == null) {
      _message('This file cannot be saved from the current workspace.');
      return;
    }

    final extension = _extensionOf(item.name);
    final format = FormatCatalog.forType(item.type).firstWhere(
      (f) => f.extension == extension,
      orElse: () => FormatCatalog.forType(item.type).first,
    );

    final saved = await _exportService.saveBytes(
      bytes: bytes,
      fileName: item.name,
      mimeType: format.mimeType,
      allowedExtensions: [format.extension],
    );

    if (!mounted || saved == null) return;
    _message('${saved.fileName} saved.');
  }

  Future<void> _exportConvert() async {
    final item = _currentItem;
    if (item == null) {
      _message('Open or select a file first.');
      return;
    }

    final config = await showFormatActionSheet(
      context,
      type: item.type,
      initialName: item.name,
      title: 'Export / Convert ${_labelFor(item.type)}',
    );
    if (config == null) return;

    if (item.type == WorkspaceType.video && item.path.isEmpty) {
      _message('Video conversion needs a local file path.');
      return;
    }

    try {
      _showBusy('Preparing output…');
      final result = await _conversionService.convert(
        type: item.type,
        inputPath: item.path,
        inputBytes: item.bytes,
        outputExtension: config.format.extension,
        baseName: config.fileName,
        quality: config.quality,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      final saved = await _exportService.saveBytes(
        bytes: result.bytes,
        fileName: result.fileName,
        mimeType: config.format.mimeType,
        allowedExtensions: [config.format.extension],
      );
      if (!mounted || saved == null) return;
      _message('${saved.fileName} saved.');
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _message('Conversion failed: $e');
    }
  }

  Future<void> _compressCurrent() async {
    final item = _currentItem;
    if (item == null) {
      _message('Open or select a file first.');
      return;
    }

    if (item.path.isEmpty) {
      _message('Compression needs a local file path.');
      return;
    }

    try {
      final zip = await _compressionService.zipFiles([item.path]);
      final saved = await _exportService.saveBytes(
        bytes: zip,
        fileName: '${_baseName(item.name)}.zip',
        mimeType: 'application/zip',
        allowedExtensions: const ['zip'],
      );
      if (!mounted || saved == null) return;
      _message('${saved.fileName} saved.');
    } catch (e) {
      _message('Compression failed: $e');
    }
  }

  Future<void> _compressPickedFiles() async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) {
      return;
    }

    final temp = Directory.systemTemp;
    final paths = <String>[];

    for (final file in picked) {
      if (file.path != null && file.path!.isNotEmpty) {
        paths.add(file.path!);
      } else {
        final bytes = await file.readAsBytes();
        final tempFile = File('${temp.path}/modivka_${DateTime.now().microsecondsSinceEpoch}_${file.name}');
        await tempFile.writeAsBytes(bytes, flush: true);
        paths.add(tempFile.path);
      }
    }

    final zip = await _compressionService.zipFiles(paths);
    if (!mounted) return;
    final saved = await _exportService.saveBytes(
      bytes: zip,
      fileName: 'Modivka-Compressed-${DateTime.now().millisecondsSinceEpoch}.zip',
      mimeType: 'application/zip',
      allowedExtensions: const ['zip'],
    );
    if (!mounted || saved == null) return;
    _message('${picked.length} files compressed into ${saved.fileName}.');
  }

  Future<void> _universalConverter() async {
    final file = await FilePicker.pickFile();
    if (!mounted || file == null) return;

    final type = _typeFromExtension(file.name);
    if (type == null) {
      _message('Format not supported by the built-in converter.');
      return;
    }

    final config = await showFormatActionSheet(
      context,
      type: type,
      initialName: file.name,
      title: 'Universal converter',
    );
    if (config == null) return;

    try {
      _showBusy('Converting ${file.name}…');
      final result = await _conversionService.convert(
        type: type,
        inputPath: file.path ?? file.uri.toFilePath(),
        inputBytes: type == WorkspaceType.video ? null : await file.readAsBytes(),
        outputExtension: config.format.extension,
        baseName: config.fileName,
        quality: config.quality,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      final saved = await _exportService.saveBytes(
        bytes: result.bytes,
        fileName: result.fileName,
        mimeType: config.format.mimeType,
        allowedExtensions: [config.format.extension],
      );
      if (!mounted || saved == null) return;
      _message('${saved.fileName} saved.');
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _message('Conversion failed: $e');
    }
  }

  Future<Uint8List?> _bytesFor(WorkspaceItem item) async {
    if (item.bytes != null) return item.bytes;
    if (item.path.isEmpty) return null;
    try {
      return await File(item.path).readAsBytes();
    } catch (_) {
      return null;
    }
  }

  WorkspaceType? _typeFromExtension(String name) {
    final ext = _extensionOf(name);
    if (FormatCatalog.image.any((f) => f.extension == ext)) return WorkspaceType.image;
    if (FormatCatalog.text.any((f) => f.extension == ext)) return WorkspaceType.text;
    if (FormatCatalog.video.any((f) => f.extension == ext)) return WorkspaceType.video;
    if (['m3u8', 'ts'].contains(ext)) return WorkspaceType.video;
    return null;
  }

  String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(dot + 1).toLowerCase() : '';
  }

  String _baseName(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  String _labelFor(WorkspaceType type) {
    switch (type) {
      case WorkspaceType.image:
        return 'images';
      case WorkspaceType.text:
        return 'text';
      case WorkspaceType.video:
        return 'media';
    }
  }

  void _settings() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: const Color(0xFF10101A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Studio Settings', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _showStatus,
                  onChanged: (value) {
                    setSheetState(() {});
                    setState(() => _showStatus = value);
                  },
                  title: const Text('Workspace status bar'),
                  subtitle: const Text('Show active file and tool hints.'),
                ),
                const ListTile(
                  leading: Icon(Icons.grid_4x4_rounded),
                  title: Text('Canvas helpers'),
                  subtitle: Text('Smart guides, snapping and safe bounds are enabled.'),
                ),
                const ListTile(
                  leading: Icon(Icons.palette_outlined),
                  title: Text('Theme'),
                  subtitle: Text('Dark neon workspace optimized for editing.'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _about() {
    showAboutDialog(
      context: context,
      applicationName: 'Modivka Studio',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset('assets/modivka_icon.png', width: 48, height: 48),
      children: const [
        Text('Create, edit, convert, export and compress images, text and video in one workspace.'),
      ],
    );
  }

  void _showBusy(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
              const SizedBox(width: 14),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ModivkaTopBar(
              onNew: _newProject,
              onOpen: _openActive,
              onSave: _saveCurrent,
              onConvert: _exportConvert,
              onCompress: _compressPickedFiles,
              onSettings: _settings,
              onAbout: _about,
            ),
            ModuleTabs(
              selectedIndex: _moduleIndex,
              onChanged: (index) => setState(() => _moduleIndex = index),
            ),
            Expanded(
              child: IndexedStack(
                index: _moduleIndex,
                children: [
                  ImagesWorkspace(
                    items: _images,
                    selectedIndex: _selectedImage,
                    onSelected: _setSelected,
                    onAddImage: _openActive,
                    onAddLayer: _addImageLayer,
                    onSave: _saveCurrent,
                    onConvert: _exportConvert,
                    onCompress: _compressCurrent,
                  ),
                  TextWorkspace(
                    items: _texts,
                    selectedIndex: _selectedText,
                    onSelected: _setSelected,
                    onOpen: _openActive,
                  ),
                  VideoWorkspace(
                    items: _videos,
                    selectedIndex: _selectedVideo,
                    onSelected: _setSelected,
                    onOpen: _openActive,
                  ),
                ],
              ),
            ),
            if (_showStatus)
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: const Color(0xFF0A0910),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 7, color: const Color(0xFF7868FF)),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _currentItem == null
                            ? '${_labelFor(_activeType).toUpperCase()} • Ready'
                            : '${_currentItem!.name} • ${_activeItems.length} open',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ),
                    InkWell(
                      onTap: _universalConverter,
                      child: const Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 15, color: Colors.white54),
                          SizedBox(width: 4),
                          Text('Universal converter', style: TextStyle(fontSize: 10, color: Colors.white54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
