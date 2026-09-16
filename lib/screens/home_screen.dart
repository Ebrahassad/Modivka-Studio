import 'package:flutter/material.dart';

import '../core/export/export_service.dart';
import '../core/files/file_service.dart';
import '../core/models/workspace_item.dart';
import '../modules/images/images_workspace.dart';
import '../modules/text/text_workspace.dart';
import '../modules/video/video_workspace.dart';
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

  int _moduleIndex = 0;

  final List<WorkspaceItem> _images = [];
  final List<WorkspaceItem> _texts = [];
  final List<WorkspaceItem> _videos = [];

  int _selectedImage = 0;
  int _selectedText = 0;
  int _selectedVideo = 0;

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
    final type = WorkspaceType.values[_moduleIndex];

    final items = await _fileService.openFiles(type: type);

    if (items.isEmpty || !mounted) {
      return;
    }

    setState(() {
      switch (type) {
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
  }

  Future<void> _addImageLayer() async {
    final item = await _fileService.openSingleImage();

    if (item == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "${item.name}" as an image layer.')),
    );
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
  }

  Future<void> _save() async {
    final item =
        _activeItems.isNotEmpty && _activeSelectedIndex < _activeItems.length
            ? _activeItems[_activeSelectedIndex]
            : null;

    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There is nothing to save yet.')),
      );
      return;
    }

    if (item.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This item does not have export data yet.'),
        ),
      );
      return;
    }

    final result = await _exportService.saveBytes(
      bytes: item.bytes!,
      fileName: 'Modivka-${item.name}',
    );

    if (!mounted) {
      return;
    }

    await _showSavedDialog(result);
  }

  Future<void> _showSavedDialog(ExportResult result) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline),
              SizedBox(width: 8),
              Text('Saved'),
            ],
          ),
          content: SelectableText(result.path),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await _exportService.shareFile(result.path);
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  void _settings() {
    showDialog<void>(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Settings'),
        content: Text('Modivka Studio settings will be built here.'),
      ),
    );
  }

  void _about() {
    showAboutDialog(
      context: context,
      applicationName: 'Modivka Studio',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.auto_awesome_rounded, size: 38),
      children: const [Text('A modular workspace for images, text and video.')],
    );
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
              onSave: _save,
              onSettings: _settings,
              onAbout: _about,
            ),
            ModuleTabs(
              selectedIndex: _moduleIndex,
              onChanged: (index) {
                setState(() {
                  _moduleIndex = index;
                });
              },
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
          ],
        ),
      ),
    );
  }
}
