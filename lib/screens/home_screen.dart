import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/compression/compression_service.dart';
import '../core/conversion/format_catalog.dart';
import '../core/export/unified_export_service.dart';
import '../core/models/canvas_layer.dart';
import '../core/models/studio_session.dart';
import '../core/models/workspace_item.dart';
import '../core/session/session_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _LayerDragData {
  const _LayerDragData({
    required this.sessionId,
    required this.layerId,
  });

  final String sessionId;
  final String layerId;
}

class _ExportRequest {
  const _ExportRequest({
    required this.format,
    required this.fileName,
    required this.quality,
    required this.compress,
  });

  final FormatOption format;
  final String fileName;
  final int quality;
  final bool compress;
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _sessionService = const SessionService();
  final _exportService = const UnifiedExportService();
  final _compressionService = CompressionService();
  final _canvasKey = GlobalKey();

  final List<StudioSession> _sessions = [];
  int _activeSessionIndex = 0;
  bool _loading = true;
  final bool _showLayers = true;
  bool _showProperties = false;

  final Map<String, VideoPlayerController> _videoControllers = {};
  final Set<String> _videoPreparing = {};

  StudioSession? get _session {
    if (_activeSessionIndex < 0 || _activeSessionIndex >= _sessions.length) {
      return null;
    }
    return _sessions[_activeSessionIndex];
  }

  CanvasLayer? get _selectedLayer {
    final session = _session;
    if (session == null) return null;

    for (final layer in session.layers) {
      if (layer.id == _selectedLayerId(session)) {
        return layer;
      }
    }
    return null;
  }

  String? _selectedLayerId(StudioSession session) {
    final selected = session.layers
        .where((layer) => layer.id == _selectionIds[session.id])
        .firstOrNull;
    return selected?.id;
  }

  final Map<String, String?> _selectionIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreSessions();
  }

  Future<void> _restoreSessions() async {
    final openSessions = await _sessionService.loadOpenSessions();
    final activeId = await _sessionService.loadActiveId();

    if (!mounted) return;

    if (openSessions.isEmpty) {
      _sessions.add(_createNewSession());
    } else {
      _sessions.addAll(openSessions);
      final index = activeId == null
          ? -1
          : _sessions.indexWhere((session) => session.id == activeId);
      _activeSessionIndex = index >= 0 ? index : 0;
    }

    for (final session in _sessions) {
      if (session.layers.isNotEmpty && _selectionIds[session.id] == null) {
        _selectionIds[session.id] =
            session.selectedLayerId ?? session.mainLayer?.id;
      }
    }

    setState(() => _loading = false);
    await _prepareSelectedVideo();
  }

  StudioSession _createNewSession() {
    final suffix = _sessions.length + 1;
    return StudioSession(
      id: '${DateTime.now().microsecondsSinceEpoch}-$suffix',
      name: 'Untitled $suffix',
      dirty: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _persistOpenState();
    }
  }

  void _persistOpenState() {
    final activeId = _session?.id;
    unawaited(_sessionService.updateOpenState(_sessions, activeId));
  }

  void _markDirty() {
    final session = _session;
    if (session == null) return;
    session.dirty = true;
    _persistOpenState();
    if (mounted) setState(() {});
  }

  void _selectLayer(String id) {
    final session = _session;
    if (session == null) return;

    setState(() {
      _selectionIds[session.id] = id;
      session.selectedLayerId = id;
      _showProperties = true;
    });
    unawaited(_prepareSelectedVideo());
  }

  Future<void> _openMedia() async {
    final session = _session;
    if (session == null) return;

    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return;

    for (final file in files) {
      await _addPickedFile(file, forceLayer: session.hasDocument);
    }
  }

  Future<void> _openAsLayers() async {
    final session = _session;
    if (session == null || !session.hasDocument) {
      await _openMedia();
      return;
    }

    final files = await FilePicker.pickFiles(type: FileType.any);
    for (final file in files) {
      await _addPickedFile(file, forceLayer: true);
    }
  }

  Future<void> _addPickedFile(
    PlatformFile file, {
    required bool forceLayer,
  }) async {
    final session = _session;
    if (session == null) return;

    final path = _pathOf(file);
    if (path == null || path.isEmpty) {
      _showMessage('The selected file has no accessible local path.');
      return;
    }

    final type = _layerType(file.name);
    Uint8List? bytes;
    String text = '';

    if (type == LayerType.image || type == LayerType.text) {
      try {
        bytes = await file.readAsBytes();
      } catch (e) {
        _showMessage('Could not read ${file.name}: $e');
        return;
      }
      if (type == LayerType.text) {
        text = utf8.decode(bytes, allowMalformed: true);
      }
    }

    final isMain = !forceLayer && !session.hasDocument;
    final layer = CanvasLayer(
      id: '${DateTime.now().microsecondsSinceEpoch}-${file.name}',
      name: file.name,
      type: type,
      bytes: bytes,
      path: path,
      text: text,
      x: isMain ? 0 : 80 + session.layers.length * 12,
      y: isMain ? 0 : 70 + session.layers.length * 12,
      width: isMain ? 1200 : 420,
      height: isMain ? 800 : 300,
    );

    if (isMain) {
      session.layers.insert(0, layer);
      session.name = _baseName(file.name);
    } else {
      session.layers.add(layer);
    }

    _selectionIds[session.id] = layer.id;
    session.selectedLayerId = layer.id;
    session.dirty = true;

    if (mounted) {
      setState(() {});
    }
    _persistOpenState();
    await _prepareSelectedVideo();
  }

  String? _pathOf(PlatformFile file) {
    if (file.path != null && file.path!.isNotEmpty) {
      return file.path;
    }
    if (file.uri.scheme == 'file') {
      return file.uri.toFilePath();
    }
    return null;
  }

  LayerType _layerType(String name) {
    final extension = _extension(name);
    const images = {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'bmp',
      'tif',
      'tiff',
      'heic',
      'heif',
      'avif',
      'tga',
      'ico',
    };
    const videos = {
      'mp4',
      'mov',
      'm4v',
      'avi',
      'mkv',
      'webm',
      '3gp',
      'mpeg',
      'mpg',
      'ts',
    };

    if (images.contains(extension)) return LayerType.image;
    if (videos.contains(extension)) return LayerType.video;
    return LayerType.text;
  }

  void _newSession() {
    setState(() {
      _sessions.add(_createNewSession());
      _activeSessionIndex = _sessions.length - 1;
    });
    _persistOpenState();
    unawaited(_prepareSelectedVideo());
  }

  Future<void> _disposeVideoController() async {
    final controllers = _videoControllers.values.toList();
    _videoControllers.clear();
    _videoPreparing.clear();

    for (final controller in controllers) {
      try {
        await controller.dispose();
      } catch (_) {
        // Controller cleanup is best-effort.
      }
    }
  }

  Future<void> _closeSession(int index) async {
    if (index < 0 || index >= _sessions.length) return;
    final session = _sessions[index];

    if (session.dirty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved changes'),
          content: Text('Save changes in "${session.name}" before closing?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (choice == null || choice == 'cancel') return;
      if (choice == 'save') {
        final previous = _activeSessionIndex;
        setState(() => _activeSessionIndex = index);
        await _saveSession();
        if (!mounted) return;
        if (previous != index && previous < _sessions.length) {
          setState(() => _activeSessionIndex = previous);
        }
      }
    }

    await _disposeVideoController();

    setState(() {
      _selectionIds.remove(session.id);
      _sessions.removeAt(index);
      if (_sessions.isEmpty) {
        _sessions.add(_createNewSession());
        _activeSessionIndex = 0;
      } else if (_activeSessionIndex >= _sessions.length) {
        _activeSessionIndex = _sessions.length - 1;
      } else if (index < _activeSessionIndex) {
        _activeSessionIndex--;
      } else if (_activeSessionIndex == index) {
        _activeSessionIndex = math.min(
          index,
          _sessions.length - 1,
        );
      }
    });

    _persistOpenState();
    unawaited(_prepareSelectedVideo());
  }

  void _switchSession(int index) {
    if (index == _activeSessionIndex ||
        index < 0 ||
        index >= _sessions.length) {
      return;
    }

    setState(() => _activeSessionIndex = index);
    _persistOpenState();
    unawaited(_prepareSelectedVideo());
  }

  Future<void> _saveSession() async {
    final session = _session;
    if (session == null) return;

    _showBusy('Saving session…');
    try {
      await _sessionService.saveSession(session);
      if (mounted) {
        Navigator.of(context).pop();
        setState(() {});
        _showMessage('Session saved.');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showMessage('Session save failed: $e');
      }
    }
    _persistOpenState();
  }

  Future<void> _openSavedSession() async {
    final summaries = await _sessionService.listSavedSessions();
    if (!mounted) return;

    if (summaries.isEmpty) {
      _showMessage('No saved sessions found.');
      return;
    }

    final selected = await showModalBottomSheet<SessionSummary>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.75,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: summaries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                final summary = summaries[index];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(summary.name),
                  subtitle: Text(
                    summary.savedAt == null
                        ? 'Saved session'
                        : 'Saved ${summary.savedAt}',
                  ),
                  onTap: () => Navigator.pop(context, summary),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    final existing = _sessions.indexWhere(
      (session) => session.id == selected.id,
    );
    if (existing >= 0) {
      _switchSession(existing);
      return;
    }

    final loaded = await _sessionService.loadSession(selected.id);
    if (loaded == null || !mounted) {
      _showMessage('Unable to open saved session.');
      return;
    }

    setState(() {
      _sessions.add(loaded);
      _selectionIds[loaded.id] = loaded.selectedLayerId ?? loaded.mainLayer?.id;
      _activeSessionIndex = _sessions.length - 1;
    });
    _persistOpenState();
    await _prepareSelectedVideo();
  }

  Future<void> _deleteSavedSession(String id) async {
    await _sessionService.deleteSavedSession(id);
  }

  Future<void> _openSessionManager() async {
    final summaries = await _sessionService.listSavedSessions();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, refresh) {
            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.75,
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.folder_special_outlined),
                      title: Text('Saved Sessions'),
                    ),
                    Expanded(
                      child: summaries.isEmpty
                          ? const Center(
                              child: Text('No saved sessions.'),
                            )
                          : ListView.builder(
                              itemCount: summaries.length,
                              itemBuilder: (context, index) {
                                final summary = summaries[index];
                                final open = _sessions.any(
                                  (session) => session.id == summary.id,
                                );
                                return ListTile(
                                  leading: const Icon(Icons.workspaces_outline),
                                  title: Text(summary.name),
                                  subtitle: Text(
                                    open ? 'Open' : 'Saved',
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await _openSavedBySummary(summary);
                                  },
                                  trailing: IconButton(
                                    tooltip: 'Delete saved session',
                                    onPressed: () async {
                                      await _deleteSavedSession(summary.id);
                                      refresh(() {});
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openSavedBySummary(SessionSummary summary) async {
    final existing = _sessions.indexWhere(
      (session) => session.id == summary.id,
    );
    if (existing >= 0) {
      _switchSession(existing);
      return;
    }

    final loaded = await _sessionService.loadSession(summary.id);
    if (loaded == null || !mounted) return;

    setState(() {
      _sessions.add(loaded);
      _selectionIds[loaded.id] = loaded.selectedLayerId ?? loaded.mainLayer?.id;
      _activeSessionIndex = _sessions.length - 1;
    });
    _persistOpenState();
    await _prepareSelectedVideo();
  }

  VideoPlayerController? _controllerForLayer(CanvasLayer layer) {
    return _videoControllers[layer.id];
  }

  Future<void> _prepareSelectedVideo() async {
    final session = _session;
    if (session == null) {
      await _disposeAllVideos();
      return;
    }

    final keepIds = <String>{};
    final main = session.mainLayer;
    if (main != null &&
        main.type == LayerType.video &&
        main.path != null &&
        main.path!.isNotEmpty) {
      keepIds.add(main.id);
    }

    final selected = _selectedLayer;
    if (selected != null &&
        selected.type == LayerType.video &&
        selected.path != null &&
        selected.path!.isNotEmpty) {
      keepIds.add(selected.id);
    }

    final stale =
        _videoControllers.keys.where((id) => !keepIds.contains(id)).toList();
    for (final id in stale) {
      await _disposeVideo(id);
    }

    for (final id in keepIds) {
      final layer = session.layers.firstWhereOrNull(
        (item) => item.id == id,
      );
      if (layer != null) {
        await _ensureVideoController(layer);
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _ensureVideoController(CanvasLayer layer) async {
    if (layer.type != LayerType.video ||
        layer.path == null ||
        layer.path!.isEmpty ||
        _videoControllers.containsKey(layer.id) ||
        _videoPreparing.contains(layer.id)) {
      return;
    }

    _videoPreparing.add(layer.id);
    final controller = VideoPlayerController.file(File(layer.path!));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(() {
        if (mounted && _selectedLayer?.id == layer.id) {
          setState(() {});
        }
      });
      _videoControllers[layer.id] = controller;
    } catch (_) {
      await controller.dispose();
    } finally {
      _videoPreparing.remove(layer.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _disposeVideo(String id) async {
    final controller = _videoControllers.remove(id);
    if (controller != null) {
      await controller.dispose();
    }
    _videoPreparing.remove(id);
  }

  Future<void> _disposeAllVideos() async {
    final ids = _videoControllers.keys.toList();
    for (final id in ids) {
      await _disposeVideo(id);
    }
  }

  Future<void> _replaceSelectedLayer() async {
    final session = _session;
    final current = _selectedLayer;
    if (session == null || current == null || current.locked) return;

    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return;

    final path = _pathOf(file);
    if (path == null || path.isEmpty) {
      _showMessage('The selected file has no accessible local path.');
      return;
    }

    final type = _layerType(file.name);
    Uint8List? bytes;
    String text = '';

    if (type != LayerType.video) {
      bytes = await file.readAsBytes();
      if (type == LayerType.text) {
        text = utf8.decode(bytes, allowMalformed: true);
      }
    }

    final replacement = CanvasLayer(
      id: current.id,
      name: file.name,
      type: type,
      bytes: bytes,
      path: path,
      text: text,
      fontFamily: current.fontFamily,
      fontSize: current.fontSize,
      bold: current.bold,
      italic: current.italic,
      underline: current.underline,
      strikethrough: current.strikethrough,
      letterSpacing: current.letterSpacing,
      lineHeight: current.lineHeight,
      textColor: current.textColor,
      textAlignment: current.textAlignment,
      x: current.x,
      y: current.y,
      width: current.width,
      height: current.height,
      rotation: current.rotation,
      opacity: current.opacity,
      visible: current.visible,
      locked: current.locked,
      flipHorizontal: current.flipHorizontal,
      flipVertical: current.flipVertical,
    );

    final index = session.layers.indexOf(current);
    if (index < 0) return;

    setState(() {
      session.layers[index] = replacement;
      _selectionIds[session.id] = replacement.id;
      session.dirty = true;
    });
    _persistOpenState();
    await _prepareSelectedVideo();
  }

  Future<void> _duplicateSelected() async {
    final session = _session;
    final layer = _selectedLayer;
    if (session == null || layer == null) return;

    final copy = _cloneLayer(layer);
    session.layers.add(copy);
    _selectionIds[session.id] = copy.id;
    session.selectedLayerId = copy.id;
    _markDirty();
  }

  void _deleteSelected() {
    final session = _session;
    final layer = _selectedLayer;
    if (session == null || layer == null) return;
    if (layer.id == session.mainLayer?.id) {
      _showMessage(
          'The Main Document layer cannot be deleted. Use New instead.');
      return;
    }

    setState(() {
      session.layers.removeWhere((item) => item.id == layer.id);
      session.selectedLayerId = session.layers.lastOrNull?.id;
      _selectionIds[session.id] = session.selectedLayerId;
      session.dirty = true;
    });
    _persistOpenState();
    unawaited(_prepareSelectedVideo());
  }

  void _reorderLayerById(String movingId, String targetId) {
    final session = _session;
    if (session == null || movingId == targetId) return;

    final from = session.layers.indexWhere((layer) => layer.id == movingId);
    final target = session.layers.indexWhere((layer) => layer.id == targetId);
    if (from < 0 || target < 0 || from == 0) return;

    setState(() {
      final moving = session.layers.removeAt(from);
      var targetAfterRemoval = target;
      if (from < targetAfterRemoval) {
        targetAfterRemoval--;
      }

      // Dropping onto a layer places the dragged layer directly above it.
      final newIndex =
          (targetAfterRemoval + 1).clamp(1, session.layers.length).toInt();
      session.layers.insert(newIndex, moving);
      session.dirty = true;
    });
    _persistOpenState();
  }

  void _moveSelectedUp() {
    final session = _session;
    final layer = _selectedLayer;
    if (session == null || layer == null) return;

    final index = session.layers.indexWhere((item) => item.id == layer.id);
    if (index < 1 || index >= session.layers.length - 1) return;

    setState(() {
      final moving = session.layers.removeAt(index);
      session.layers.insert(index + 1, moving);
      session.dirty = true;
    });
    _persistOpenState();
  }

  void _moveSelectedDown() {
    final session = _session;
    final layer = _selectedLayer;
    if (session == null || layer == null) return;

    final index = session.layers.indexWhere((item) => item.id == layer.id);
    if (index <= 1) return;

    setState(() {
      final moving = session.layers.removeAt(index);
      session.layers.insert(index - 1, moving);
      session.dirty = true;
    });
    _persistOpenState();
  }

  void _toggleVisible() {
    final layer = _selectedLayer;
    if (layer == null) return;
    setState(() {
      layer.visible = !layer.visible;
      _session?.dirty = true;
    });
    _persistOpenState();
  }

  void _toggleLock() {
    final layer = _selectedLayer;
    if (layer == null) return;
    setState(() {
      layer.locked = !layer.locked;
      _session?.dirty = true;
    });
    _persistOpenState();
  }

  void _rotateLayer() {
    final layer = _selectedLayer;
    if (layer == null || layer.locked) return;
    setState(() {
      layer.rotation += math.pi / 2;
      _session?.dirty = true;
    });
    _persistOpenState();
  }

  void _flipHorizontal() {
    final layer = _selectedLayer;
    if (layer == null || layer.locked) return;
    setState(() {
      layer.flipHorizontal = !layer.flipHorizontal;
      _session?.dirty = true;
    });
    _persistOpenState();
  }

  void _flipVertical() {
    final layer = _selectedLayer;
    if (layer == null || layer.locked) return;
    setState(() {
      layer.flipVertical = !layer.flipVertical;
      _session?.dirty = true;
    });
    _persistOpenState();
  }

  void _fitSelected() {
    final layer = _selectedLayer;
    final session = _session;
    if (layer == null || session == null || layer == session.mainLayer) return;
    if (layer.locked) return;

    setState(() {
      layer.width = 600;
      layer.height = 400;
      layer.x = 300;
      layer.y = 200;
      session.dirty = true;
    });
    _persistOpenState();
  }

  void _setSelectedOpacity(double value) {
    final layer = _selectedLayer;
    if (layer == null || layer.locked) return;
    setState(() {
      layer.opacity = value.clamp(0.0, 1.0).toDouble();
      _session?.dirty = true;
    });
    _persistOpenState();
  }

  void _editText() async {
    final layer = _selectedLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) return;

    final controller = TextEditingController(text: layer.text);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit text layer'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 7,
          decoration: const InputDecoration(labelText: 'Text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;

    setState(() {
      layer.text = value;
      layer.name = value.trim().isEmpty ? 'Text Layer' : value.trim();
      _session?.dirty = true;
    });
    _persistOpenState();
  }

  void _changeFontSize(double delta) {
    final layer = _selectedLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) return;
    setState(() {
      layer.fontSize = (layer.fontSize + delta).clamp(6.0, 300.0).toDouble();
      _session?.dirty = true;
    });
    _persistOpenState();
  }

  void _toggleTextStyle(String style) {
    final layer = _selectedLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) return;
    setState(() {
      switch (style) {
        case 'bold':
          layer.bold = !layer.bold;
          break;
        case 'italic':
          layer.italic = !layer.italic;
          break;
        case 'underline':
          layer.underline = !layer.underline;
          break;
        case 'strike':
          layer.strikethrough = !layer.strikethrough;
          break;
      }
      _session?.dirty = true;
    });
    _persistOpenState();
  }

  void _cycleAlignment() {
    final layer = _selectedLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) return;
    setState(() {
      layer.textAlignment = switch (layer.textAlignment) {
        TextAlignment.left => TextAlignment.center,
        TextAlignment.center => TextAlignment.right,
        TextAlignment.right => TextAlignment.left,
      };
      _session?.dirty = true;
    });
    _persistOpenState();
  }

  Future<void> _pickTextColor() async {
    final layer = _selectedLayer;
    if (layer == null || layer.type != LayerType.text || layer.locked) return;

    const colors = <ColorValue>[
      ColorValue(255, 255, 255),
      ColorValue(255, 80, 80),
      ColorValue(255, 190, 70),
      ColorValue(255, 235, 80),
      ColorValue(80, 220, 130),
      ColorValue(80, 180, 255),
      ColorValue(130, 110, 255),
      ColorValue(255, 100, 230),
      ColorValue(0, 0, 0),
    ];

    final value = await showDialog<ColorValue>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Text color'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors
              .map(
                (color) => InkWell(
                  onTap: () => Navigator.pop(context, color),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Color(color.value),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (value == null) return;
    setState(() {
      layer.textColor = value;
      _session?.dirty = true;
    });
    _persistOpenState();
  }

  Future<void> _showOpacityDialog() async {
    final layer = _selectedLayer;
    if (layer == null) return;
    var value = layer.opacity;

    final result = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Opacity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                min: 0,
                max: 1,
                value: value,
                onChanged: (next) => setLocalState(() => value = next),
              ),
              Text('${(value * 100).round()}%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, value),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      _setSelectedOpacity(result);
    }
  }

  Future<VideoPlayerController?> _selectedVideoController() async {
    final layer = _selectedLayer;
    if (layer == null || layer.type != LayerType.video) return null;
    await _ensureVideoController(layer);
    return _controllerForLayer(layer);
  }

  Future<void> _videoPlayPause() async {
    final controller = await _selectedVideoController();
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _videoMute() async {
    final controller = await _selectedVideoController();
    if (controller == null) return;
    await controller.setVolume(controller.value.volume > 0 ? 0 : 1);
    if (mounted) setState(() {});
  }

  Future<void> _videoSpeed(double speed) async {
    final controller = await _selectedVideoController();
    if (controller == null) return;
    await controller.setPlaybackSpeed(speed);
    if (mounted) setState(() {});
  }

  Future<void> _videoRestart() async {
    final controller = await _selectedVideoController();
    if (controller == null) return;
    await controller.seekTo(Duration.zero);
    if (!controller.value.isPlaying) {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _convertSelectedLayer() async {
    final layer = _selectedLayer;
    final session = _session;
    if (layer == null || session == null) return;

    final type = switch (layer.type) {
      LayerType.image => WorkspaceType.image,
      LayerType.text => WorkspaceType.text,
      LayerType.video => WorkspaceType.video,
    };
    final formats = FormatCatalog.forType(type);
    final request = await _showExportDialog(
      type,
      formats,
      initialName: layer.name,
      title: 'Convert selected layer',
      allowCompression: false,
    );
    if (request == null) return;

    final directory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose export folder',
    );
    if (directory == null || directory.isEmpty) return;

    _showBusy('Converting layer…');
    try {
      final temporarySession = StudioSession(
        id: 'temporary',
        name: _baseName(request.fileName),
        layers: [_cloneLayer(layer, preserveId: true)],
      );
      final result = await _exportService.exportToDirectory(
        session: temporarySession,
        directoryPath: directory,
        format: request.format,
        baseName: _baseName(request.fileName),
        quality: request.quality,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage('Layer exported: ${result.fileName}');
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showMessage('Conversion failed: $e');
      }
    }
  }

  Future<void> _compressSelectedLayer() async {
    final layer = _selectedLayer;
    if (layer == null) return;

    final path = layer.path;
    if (path == null || path.isEmpty || !await File(path).exists()) {
      _showMessage('This layer has no local source file to compress.');
      return;
    }

    final directory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose ZIP folder',
    );
    if (directory == null || directory.isEmpty) return;

    _showBusy('Creating ZIP…');
    try {
      final zipBytes = await _compressionService.zipFiles([path]);
      final zipPath =
          '${Directory(directory).path}/${_safeFileName(layer.name)}.zip';
      await File(zipPath).writeAsBytes(zipBytes, flush: true);
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage('ZIP created: ${File(zipPath).uri.pathSegments.last}');
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showMessage('Compression failed: $e');
      }
    }
  }

  Future<void> _exportWholeSession() async {
    final session = _session;
    final main = session?.mainLayer;
    if (session == null || main == null) {
      _showMessage('Open a Main Document first.');
      return;
    }

    final type = switch (main.type) {
      LayerType.image => WorkspaceType.image,
      LayerType.text => WorkspaceType.text,
      LayerType.video => WorkspaceType.video,
    };

    final request = await _showExportDialog(
      type,
      FormatCatalog.forType(type),
      initialName: main.name,
      title: 'Export complete workspace',
      allowCompression: true,
    );
    if (request == null) return;

    final directory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose export folder',
    );
    if (directory == null || directory.isEmpty) return;

    _showBusy('Exporting workspace…');
    try {
      final result = await _exportService.exportToDirectory(
        session: session,
        directoryPath: directory,
        format: request.format,
        baseName: _baseName(request.fileName),
        quality: request.quality,
      );

      String? zipName;
      if (request.compress) {
        final zipBytes = await _compressionService.zipFiles([result.path]);
        final zipPath =
            '${Directory(directory).path}/${_safeFileName(_baseName(request.fileName))}.zip';
        await File(zipPath).writeAsBytes(zipBytes, flush: true);
        zipName = File(zipPath).uri.pathSegments.last;
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      final note = result.note == null ? '' : ' • ${result.note}';
      _showMessage(
        zipName == null
            ? 'Exported ${result.fileName}$note'
            : 'Exported ${result.fileName} + $zipName$note',
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showMessage('Export failed: $e');
      }
    }
  }

  Future<_ExportRequest?> _showExportDialog(
    WorkspaceType type,
    List<FormatOption> formats, {
    required String initialName,
    required String title,
    required bool allowCompression,
  }) async {
    final controller = TextEditingController(text: _baseName(initialName));
    var selected = formats.first;
    var quality = 85.0;
    var compress = false;
    final showQuality = type != WorkspaceType.text;

    final result = await showDialog<_ExportRequest>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'File name',
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<FormatOption>(
                        initialValue: selected,
                        decoration: const InputDecoration(
                          labelText: 'Output format',
                        ),
                        items: formats
                            .map(
                              (format) => DropdownMenuItem(
                                value: format,
                                child: Text(
                                  '${format.label}  (.${format.extension})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setLocalState(() => selected = value);
                          }
                        },
                      ),
                      if (showQuality) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Quality'),
                            const Spacer(),
                            Text('${quality.round()}%'),
                          ],
                        ),
                        Slider(
                          min: 40,
                          max: 100,
                          value: quality,
                          onChanged: (value) =>
                              setLocalState(() => quality = value),
                        ),
                      ],
                      if (allowCompression)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Also create ZIP'),
                          subtitle: const Text(
                            'The exported file and a ZIP copy are saved in the selected folder.',
                          ),
                          value: compress,
                          onChanged: (value) =>
                              setLocalState(() => compress = value ?? false),
                        ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'The next step lets you choose the destination folder.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final name = controller.text.trim().isEmpty
                        ? 'Modivka-${DateTime.now().millisecondsSinceEpoch}'
                        : controller.text.trim();
                    Navigator.pop(
                      context,
                      _ExportRequest(
                        format: selected,
                        fileName: name,
                        quality: quality.round(),
                        compress: compress,
                      ),
                    );
                  },
                  icon: const Icon(Icons.folder_outlined),
                  label: const Text('Choose folder & export'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  Widget _buildLayerToolbar() {
    final layer = _selectedLayer;
    final session = _session;

    if (layer == null || session == null) {
      return _toolbarMessage('Open a file and select a layer');
    }

    final buttons = <Widget>[
      _toolButton(Icons.copy_outlined, 'Duplicate', _duplicateSelected),
      _toolButton(Icons.keyboard_arrow_up, 'Move up', _moveSelectedUp),
      _toolButton(Icons.keyboard_arrow_down, 'Move down', _moveSelectedDown),
      _toolButton(
        layer.visible ? Icons.visibility : Icons.visibility_off,
        layer.visible ? 'Hide' : 'Show',
        _toggleVisible,
      ),
      _toolButton(
        layer.locked ? Icons.lock : Icons.lock_open,
        layer.locked ? 'Unlock' : 'Lock',
        _toggleLock,
      ),
      _toolButton(Icons.delete_outline, 'Delete', _deleteSelected),
    ];

    switch (layer.type) {
      case LayerType.image:
        buttons.addAll([
          _toolButton(
              Icons.rotate_90_degrees_ccw_outlined, 'Rotate', _rotateLayer),
          _toolButton(Icons.flip, 'Flip H', _flipHorizontal),
          _toolButton(
              Icons.flip_camera_android_outlined, 'Flip V', _flipVertical),
          _toolButton(Icons.fit_screen_outlined, 'Fit', _fitSelected),
          _toolButton(Icons.opacity, 'Opacity', _showOpacityDialog),
          _toolButton(Icons.swap_horiz, 'Replace', _replaceSelectedLayer),
          _toolButton(Icons.transform, 'Convert', _convertSelectedLayer),
          _toolButton(
              Icons.archive_outlined, 'Compress', _compressSelectedLayer),
        ]);
        break;
      case LayerType.text:
        buttons.addAll([
          _toolButton(Icons.edit_outlined, 'Edit text', _editText),
          _toolButton(Icons.remove, 'Font -', () => _changeFontSize(-2)),
          _toolButton(Icons.add, 'Font +', () => _changeFontSize(2)),
          _toolButton(
              Icons.format_bold, 'Bold', () => _toggleTextStyle('bold')),
          _toolButton(
              Icons.format_italic, 'Italic', () => _toggleTextStyle('italic')),
          _toolButton(Icons.format_underlined, 'Underline',
              () => _toggleTextStyle('underline')),
          _toolButton(Icons.strikethrough_s, 'Strike',
              () => _toggleTextStyle('strike')),
          _fontButton(layer),
          _toolButton(Icons.format_align_center, 'Alignment', _cycleAlignment),
          _toolButton(Icons.palette_outlined, 'Color', _pickTextColor),
          _toolButton(Icons.swap_horiz, 'Replace', _replaceSelectedLayer),
          _toolButton(Icons.transform, 'Convert', _convertSelectedLayer),
          _toolButton(
              Icons.archive_outlined, 'Compress', _compressSelectedLayer),
        ]);
        break;
      case LayerType.video:
        buttons.addAll([
          _toolButton(
            _controllerForLayer(layer)?.value.isPlaying == true
                ? Icons.pause
                : Icons.play_arrow,
            _controllerForLayer(layer)?.value.isPlaying == true
                ? 'Pause'
                : 'Play',
            _videoPlayPause,
          ),
          _toolButton(
            _controllerForLayer(layer)?.value.volume == 0
                ? Icons.volume_off
                : Icons.volume_up,
            'Mute',
            _videoMute,
          ),
          _toolButton(Icons.replay, 'Restart', _videoRestart),
          _speedButton(),
          _toolButton(
              Icons.rotate_90_degrees_ccw_outlined, 'Rotate', _rotateLayer),
          _toolButton(Icons.opacity, 'Opacity', _showOpacityDialog),
          _toolButton(Icons.swap_horiz, 'Replace', _replaceSelectedLayer),
          _toolButton(Icons.transform, 'Convert', _convertSelectedLayer),
          _toolButton(
              Icons.archive_outlined, 'Compress', _compressSelectedLayer),
        ]);
        break;
    }

    return Container(
      height: 54,
      color: const Color(0xFF20242C),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        children: buttons,
      ),
    );
  }

  Widget _toolbarMessage(String message) {
    return Container(
      height: 54,
      color: const Color(0xFF20242C),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _toolButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(tooltip),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            minimumSize: const Size(0, 42),
          ),
        ),
      ),
    );
  }

  Widget _fontButton(CanvasLayer layer) {
    const fonts = <String>[
      'Roboto',
      'sans-serif',
      'serif',
      'monospace',
    ];
    return PopupMenuButton<String>(
      tooltip: 'Font family',
      initialValue: layer.fontFamily,
      onSelected: (value) {
        if (layer.locked) return;
        setState(() {
          layer.fontFamily = value;
          _session?.dirty = true;
        });
        _persistOpenState();
      },
      itemBuilder: (context) => [
        for (final font in fonts)
          PopupMenuItem<String>(
            value: font,
            child: Text(font),
          ),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.font_download_outlined, size: 19),
            SizedBox(width: 6),
            Text('Font'),
          ],
        ),
      ),
    );
  }

  Widget _speedButton() {
    return PopupMenuButton<double>(
      tooltip: 'Playback speed',
      onSelected: _videoSpeed,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 0.5, child: Text('0.5x')),
        PopupMenuItem(value: 1, child: Text('1x')),
        PopupMenuItem(value: 1.5, child: Text('1.5x')),
        PopupMenuItem(value: 2, child: Text('2x')),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed, size: 18),
            SizedBox(width: 6),
            Text('Speed'),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTabs() {
    return Container(
      height: 42,
      color: const Color(0xFF13161B),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                final active = index == _activeSessionIndex;
                return GestureDetector(
                  onTap: () => _switchSession(index),
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 150, maxWidth: 240),
                    margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                    padding: const EdgeInsets.only(left: 10, right: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF252B36)
                          : const Color(0xFF1A1E24),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? const Color(0xFF657AFF)
                            : const Color(0xFF2B3038),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (session.dirty)
                          const Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Icon(Icons.circle,
                                size: 6, color: Colors.amber),
                          ),
                        Expanded(
                          child: Text(
                            session.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _closeSession(index),
                          child: const Padding(
                            padding: EdgeInsets.all(5),
                            child: Icon(Icons.close, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'New session',
            onPressed: _newSession,
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 3),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF181B22),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF30343D)),
                ),
              ),
            ),
          ),
          Positioned(
            left: 7,
            child: PopupMenuButton<String>(
              tooltip: 'File',
              onSelected: (value) async {
                switch (value) {
                  case 'new':
                    _newSession();
                    break;
                  case 'open':
                    await _openMedia();
                    break;
                  case 'layers':
                    await _openAsLayers();
                    break;
                  case 'sessions':
                    await _openSessionManager();
                    break;
                  case 'save':
                    await _saveSession();
                    break;
                  case 'export':
                    await _exportWholeSession();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'new', child: Text('New Session')),
                PopupMenuItem(value: 'open', child: Text('Open Media')),
                PopupMenuItem(value: 'layers', child: Text('Open as Layers')),
                PopupMenuItem(value: 'sessions', child: Text('Saved Sessions')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'save', child: Text('Save Session')),
                PopupMenuItem(value: 'export', child: Text('Export Workspace')),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open, size: 18),
                    SizedBox(width: 5),
                    Text('File'),
                  ],
                ),
              ),
            ),
          ),
          const Center(
            child: Text(
              'Modivka Studio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Positioned(
            right: 7,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Save Session',
                  onPressed: _saveSession,
                  icon: const Icon(Icons.save_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Export',
                  onPressed: _exportWholeSession,
                  icon: const Icon(Icons.file_download_outlined, size: 20),
                ),
                IconButton(
                  tooltip:
                      _showProperties ? 'Hide Properties' : 'Show Properties',
                  onPressed: () {
                    setState(() => _showProperties = !_showProperties);
                  },
                  icon: Icon(
                    _showProperties ? Icons.tune : Icons.tune_outlined,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace() {
    return Container(
      color: const Color(0xFF0A0C10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_session == null || !_session!.hasDocument) {
            return _buildEmptyWorkspace();
          }

          return InteractiveViewer(
            minScale: 0.2,
            maxScale: 4,
            boundaryMargin: const EdgeInsets.all(400),
            child: Center(
              child: Container(
                key: _canvasKey,
                width: 1200,
                height: 800,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 28,
                      spreadRadius: 4,
                      color: Colors.black54,
                    ),
                  ],
                ),
                child: DragTarget<_LayerDragData>(
                  onWillAcceptWithDetails: (details) =>
                      details.data.sessionId == _session!.id,
                  onAcceptWithDetails: (details) {
                    final box = _canvasKey.currentContext?.findRenderObject()
                        as RenderBox?;
                    if (box == null) return;
                    final local = box.globalToLocal(details.offset);
                    _placeDroppedLayer(details.data.layerId, local);
                  },
                  builder: (context, candidates, rejected) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final layer in _session!.layers)
                          if (layer.visible) _buildCanvasLayer(layer),
                        if (candidates.isNotEmpty)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF6C7BFF),
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyWorkspace() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF171B22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF303642)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.dashboard_customize_outlined,
                size: 58,
                color: Color(0xFF6E7DAA),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unified Workspace',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Open any image, video or text file. The first file becomes the Main Document; every file after it becomes a Layer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _openMedia,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open File'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _openSavedSession,
                    icon: const Icon(Icons.history),
                    label: const Text('Open Session'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasLayer(CanvasLayer layer) {
    final selected = layer.id == _selectedLayerId(_session!);

    return Positioned(
      left: layer == _session!.mainLayer ? 0 : layer.x,
      top: layer == _session!.mainLayer ? 0 : layer.y,
      width: layer == _session!.mainLayer ? 1200 : layer.width,
      height: layer == _session!.mainLayer ? 800 : layer.height,
      child: GestureDetector(
        onTap: () => _selectLayer(layer.id),
        onPanUpdate: layer.locked || layer == _session!.mainLayer
            ? null
            : (details) {
                setState(() {
                  layer.x += details.delta.dx;
                  layer.y += details.delta.dy;
                  _session?.dirty = true;
                });
              },
        child: Opacity(
          opacity: layer.opacity.clamp(0.0, 1.0).toDouble(),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..rotateZ(layer.rotation)
              ..scaleByDouble(
                layer.flipHorizontal ? -1.0 : 1.0,
                layer.flipVertical ? -1.0 : 1.0,
                1.0,
                1.0,
              ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: _layerContent(layer)),
                if (selected)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF667CFF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (selected && layer != _session!.mainLayer)
                  Positioned(
                    right: -8,
                    bottom: -8,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: layer.locked
                          ? null
                          : (details) {
                              setState(() {
                                layer.width = (layer.width + details.delta.dx)
                                    .clamp(60.0, 1200.0)
                                    .toDouble();
                                layer.height = (layer.height + details.delta.dy)
                                    .clamp(40.0, 800.0)
                                    .toDouble();
                                _session?.dirty = true;
                              });
                            },
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B70FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.open_in_full,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (selected && layer != _session!.mainLayer)
                  Positioned(
                    left: 0,
                    top: -22,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF546BFA),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        layer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _layerContent(CanvasLayer layer) {
    switch (layer.type) {
      case LayerType.image:
        if (layer.bytes != null) {
          return Image.memory(
            layer.bytes!,
            fit: layer == _session!.mainLayer ? BoxFit.contain : BoxFit.contain,
            filterQuality: FilterQuality.high,
          );
        }
        return _layerPlaceholder(
            Icons.image_not_supported_outlined, layer.name);

      case LayerType.text:
        return Container(
          padding: const EdgeInsets.all(10),
          alignment: Alignment.center,
          child: Text(
            layer.text.isEmpty ? layer.name : layer.text,
            textAlign: _textAlign(layer.textAlignment),
            style: TextStyle(
              color: Color(layer.textColor.value),
              fontFamily: layer.fontFamily,
              fontSize: layer.fontSize,
              fontWeight: layer.bold ? FontWeight.w700 : FontWeight.w400,
              fontStyle: layer.italic ? FontStyle.italic : FontStyle.normal,
              letterSpacing: layer.letterSpacing,
              height: layer.lineHeight,
              decoration: _textDecoration(layer),
            ),
          ),
        );

      case LayerType.video:
        final controller = _controllerForLayer(layer);
        if (controller != null && controller.value.isInitialized) {
          return FittedBox(
            fit: BoxFit.contain,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          );
        }
        return _layerPlaceholder(
          Icons.play_circle_outline,
          _videoPreparing.contains(layer.id) ? 'Loading video…' : layer.name,
        );
    }
  }

  Widget _layerPlaceholder(IconData icon, String text) {
    return Container(
      color: const Color(0xFF151922),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: const Color(0xFF8591AC)),
          const SizedBox(height: 8),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayersPanel() {
    final session = _session;
    if (session == null) return const SizedBox.shrink();

    return Container(
      height: 116,
      decoration: const BoxDecoration(
        color: Color(0xFF15181E),
        border: Border(
          top: BorderSide(color: Color(0xFF2E333D)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.layers_outlined, size: 17),
              IconButton(
                tooltip: 'Add Layer',
                onPressed: _openAsLayers,
                icon: const Icon(Icons.add, size: 20),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DragTarget<_LayerDragData>(
              onWillAcceptWithDetails: (details) =>
                  details.data.sessionId == session.id,
              onAcceptWithDetails: (details) {
                final data = details.data;
                final first = session.layers.firstOrNull;
                if (first != null && data.layerId == first.id) return;
                // A drop on the panel background moves the dragged layer to the
                // top of the stack without touching the Main Document.
                final index = session.layers.indexWhere(
                  (layer) => layer.id == data.layerId,
                );
                if (index <= 1) return;
                setState(() {
                  final item = session.layers.removeAt(index);
                  session.layers.add(item);
                  session.dirty = true;
                });
                _persistOpenState();
              },
              builder: (context, candidates, rejected) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 9,
                  ),
                  children: [
                    for (var display = session.layers.length - 1;
                        display >= 0;
                        display--)
                      _buildLayerCard(
                        session,
                        session.layers[display],
                        internalIndex: display,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerCard(
    StudioSession session,
    CanvasLayer layer, {
    required int internalIndex,
  }) {
    final selected = layer.id == _selectedLayerId(session);
    final isMain = internalIndex == 0;

    return DragTarget<_LayerDragData>(
      onWillAcceptWithDetails: (details) =>
          details.data.sessionId == session.id &&
          details.data.layerId != layer.id,
      onAcceptWithDetails: (details) {
        _reorderLayerById(details.data.layerId, layer.id);
      },
      builder: (context, candidates, rejected) {
        return LongPressDraggable<_LayerDragData>(
          data: _LayerDragData(
            sessionId: session.id,
            layerId: layer.id,
          ),
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 170,
              child: _layerCardBody(
                session,
                layer,
                selected: true,
                isMain: isMain,
                dragging: true,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.25,
            child: _layerCardBody(
              session,
              layer,
              selected: selected,
              isMain: isMain,
            ),
          ),
          child: _layerCardBody(
            session,
            layer,
            selected: selected,
            isMain: isMain,
          ),
        );
      },
    );
  }

  Widget _layerCardBody(
    StudioSession session,
    CanvasLayer layer, {
    required bool selected,
    required bool isMain,
    bool dragging = false,
  }) {
    return GestureDetector(
      onTap: () => _selectLayer(layer.id),
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2B3550) : const Color(0xFF1E2229),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? const Color(0xFF7184FF) : const Color(0xFF30353F),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 43,
              height: 80,
              child: _layerThumb(layer),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isMain ? 'MAIN' : layer.type.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFFB3BFFF)
                                : Colors.white54,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (layer.locked)
                        const Icon(Icons.lock, size: 12, color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    layer.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        layer.visible ? Icons.visibility : Icons.visibility_off,
                        size: 14,
                        color: Colors.white60,
                      ),
                      const SizedBox(width: 8),
                      if (!isMain)
                        const Icon(
                          Icons.drag_indicator,
                          size: 15,
                          color: Colors.white30,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _layerThumb(CanvasLayer layer) {
    if (layer.type == LayerType.image && layer.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(layer.bytes!, fit: BoxFit.cover),
      );
    }

    final icon = switch (layer.type) {
      LayerType.image => Icons.image_outlined,
      LayerType.text => Icons.text_fields,
      LayerType.video => Icons.movie_outlined,
    };

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1217),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 22, color: const Color(0xFF8190C4)),
    );
  }

  Widget _buildPropertiesPanel() {
    final layer = _selectedLayer;
    if (layer == null) return const SizedBox.shrink();

    return SizedBox(
      width: 280,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF15181E),
          border: Border(
            left: BorderSide(color: Color(0xFF2E333D)),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 14),
          children: [
            Row(
              children: [
                const Icon(Icons.tune, size: 18),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Properties',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => setState(() => _showProperties = false),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            Text(
              layer.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            _propertyValue('Type', layer.type.name.toUpperCase()),
            _propertyValue('X', layer.x.toStringAsFixed(1)),
            _propertyValue('Y', layer.y.toStringAsFixed(1)),
            _propertyValue('Width', layer.width.toStringAsFixed(1)),
            _propertyValue('Height', layer.height.toStringAsFixed(1)),
            _propertyValue(
              'Opacity',
              '${(layer.opacity * 100).round()}%',
            ),
            _propertyValue(
              'Rotation',
              '${(layer.rotation * 180 / math.pi).round()}°',
            ),
            const SizedBox(height: 8),
            if (layer.type == LayerType.text) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: layer.locked ? null : _editText,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit text'),
                ),
              ),
              const SizedBox(height: 8),
              _propertyValue('Font', layer.fontFamily),
              _propertyValue('Font size', layer.fontSize.toStringAsFixed(1)),
            ],
            if (layer.type == LayerType.video &&
                _controllerForLayer(layer)?.value.isInitialized == true) ...[
              const SizedBox(height: 8),
              _propertyValue(
                'Duration',
                _durationText(_controllerForLayer(layer)!.value.duration),
              ),
              _propertyValue(
                'Position',
                _durationText(_controllerForLayer(layer)!.value.position),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _propertyValue(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$key: ',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final session = _session;
    final layer = _selectedLayer;

    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFF0F1116),
      child: Row(
        children: [
          Icon(
            session?.dirty == true ? Icons.circle : Icons.check_circle_outline,
            size: 10,
            color: session?.dirty == true ? Colors.amber : Colors.white38,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              session == null
                  ? 'No session'
                  : '${session.name} • ${session.layers.length} layer${session.layers.length == 1 ? '' : 's'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ),
          if (layer != null)
            Text(
              layer.type.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResponsiveContent() {
    final narrow = MediaQuery.sizeOf(context).width < 760;

    if (!narrow && _showProperties) {
      return Row(
        children: [
          Expanded(child: _buildWorkspace()),
          _buildPropertiesPanel(),
        ],
      );
    }

    return _buildWorkspace();
  }

  Widget _buildBottomPropertiesButton() {
    if (MediaQuery.sizeOf(context).width >= 760 || !_showProperties) {
      return const SizedBox.shrink();
    }
    return Positioned(
      right: 12,
      bottom: 12,
      child: FloatingActionButton.small(
        heroTag: 'properties',
        onPressed: () => _showPropertiesBottomSheet(),
        child: const Icon(Icons.tune),
      ),
    );
  }

  Future<void> _showPropertiesBottomSheet() async {
    final layer = _selectedLayer;
    if (layer == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.72,
        child: _buildPropertiesPanel(),
      ),
    );
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

  TextDecoration _textDecoration(CanvasLayer layer) {
    if (layer.underline && layer.strikethrough) {
      return TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
    }
    if (layer.underline) return TextDecoration.underline;
    if (layer.strikethrough) return TextDecoration.lineThrough;
    return TextDecoration.none;
  }

  void _placeDroppedLayer(String layerId, Offset local) {
    final session = _session;
    if (session == null) return;

    final layer = session.layers.firstWhereOrNull(
      (item) => item.id == layerId,
    );
    if (layer == null || layer.locked || layer == session.mainLayer) return;

    setState(() {
      layer.x =
          (local.dx - layer.width / 2).clamp(0, 1200 - layer.width).toDouble();
      layer.y =
          (local.dy - layer.height / 2).clamp(0, 800 - layer.height).toDouble();
      _selectionIds[session.id] = layer.id;
      session.dirty = true;
    });
    _persistOpenState();
  }

  CanvasLayer _cloneLayer(
    CanvasLayer layer, {
    bool preserveId = false,
  }) {
    return CanvasLayer(
      id: preserveId
          ? layer.id
          : '${layer.id}-copy-${DateTime.now().microsecondsSinceEpoch}',
      name: '${layer.name}${preserveId ? '' : ' Copy'}',
      type: layer.type,
      bytes: layer.bytes,
      path: layer.path,
      text: layer.text,
      fontFamily: layer.fontFamily,
      fontSize: layer.fontSize,
      bold: layer.bold,
      italic: layer.italic,
      underline: layer.underline,
      strikethrough: layer.strikethrough,
      letterSpacing: layer.letterSpacing,
      lineHeight: layer.lineHeight,
      textColor: layer.textColor,
      textAlignment: layer.textAlignment,
      x: layer.x + (preserveId ? 0 : 24),
      y: layer.y + (preserveId ? 0 : 24),
      width: layer.width,
      height: layer.height,
      rotation: layer.rotation,
      opacity: layer.opacity,
      visible: layer.visible,
      locked: false,
      flipHorizontal: layer.flipHorizontal,
      flipVertical: layer.flipVertical,
    );
  }

  String _extension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(dot + 1).toLowerCase() : '';
  }

  String _baseName(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  String _safeFileName(String name) {
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    return safe.isEmpty ? 'Modivka-output' : safe;
  }

  String _durationText(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showBusy(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0D11),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final narrow = MediaQuery.sizeOf(context).width < 760;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D11),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                _buildSessionTabs(),
                _buildLayerToolbar(),
                Expanded(child: _buildResponsiveContent()),
                if (_showLayers) _buildLayersPanel(),
                _buildStatusBar(),
              ],
            ),
            if (narrow && _showProperties) _buildBottomPropertiesButton(),
          ],
        ),
      ),
    );
  }
}

extension _IterableNullableFirst<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }

  T? get lastOrNull {
    if (isEmpty) return null;
    return last;
  }

  T? firstWhereOrNull(bool Function(T element) test) {
    for (final value in this) {
      if (test(value)) return value;
    }
    return null;
  }
}
