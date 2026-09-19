import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/compression/compression_service.dart';
import '../../core/conversion/conversion_service.dart';
import '../../core/export/export_service.dart';
import '../../core/models/workspace_item.dart';
import '../../widgets/format_actions.dart';
import '../../widgets/item_strip.dart';
import '../../widgets/tool_bar.dart';

class VideoWorkspace extends StatefulWidget {
  final List<WorkspaceItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onOpen;

  const VideoWorkspace({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onOpen,
  });

  @override
  State<VideoWorkspace> createState() => _VideoWorkspaceState();
}

class _VideoWorkspaceState extends State<VideoWorkspace> {
  final _exportService = const ExportService();
  final _conversionService = const ConversionService();
  final _compressionService = CompressionService();
  VideoPlayerController? _controller;
  bool _muted = false;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(covariant VideoWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex ||
        widget.items.length != oldWidget.items.length) {
      _loadVideo();
    }
  }

  Future<void> _loadVideo() async {
    await _controller?.dispose();
    _controller = null;
    _muted = false;
    _speed = 1;

    if (widget.items.isEmpty ||
        widget.selectedIndex < 0 ||
        widget.selectedIndex >= widget.items.length) {
      if (mounted) setState(() {});
      return;
    }

    final path = widget.items[widget.selectedIndex].path;
    if (path.isEmpty) return;

    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      await controller.setLooping(false);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
    }
  }

  Future<void> _saveAs() async {
    final item = _currentItem;
    if (item == null) return;
    final config = await showFormatActionSheet(
      context,
      type: WorkspaceType.video,
      initialName: item.name,
      title: 'Export video',
    );
    if (config == null) return;

    if (config.format.extension == _extensionOf(item.name)) {
      final bytes = await _readItemBytes(item);
      if (bytes == null || !mounted) return;
      final saved = await _exportService.saveBytes(
        bytes: bytes,
        fileName: '${config.fileName}.${config.format.extension}',
        mimeType: config.format.mimeType,
        allowedExtensions: [config.format.extension],
      );
      if (!mounted || saved == null) return;
      _message('${saved.fileName} saved.');
      return;
    }

    await _convertWithConfig(item, config);
  }

  Future<void> _convert() async {
    final item = _currentItem;
    if (item == null) return;
    final config = await showFormatActionSheet(
      context,
      type: WorkspaceType.video,
      initialName: item.name,
      title: 'Convert video / audio',
    );
    if (config == null) return;
    await _convertWithConfig(item, config);
  }

  Future<void> _convertWithConfig(
    WorkspaceItem item,
    FormatActionConfig config,
  ) async {
    if (item.path.isEmpty) {
      _message('A local video path is required for conversion.');
      return;
    }

    _showBusy('Converting…');
    try {
      final result = await _conversionService.convert(
        type: WorkspaceType.video,
        inputPath: item.path,
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

  Future<void> _compress() async {
    final item = _currentItem;
    if (item == null || item.path.isEmpty) return;
    final bytes = await _compressionService.zipFiles([item.path]);
    if (!mounted) return;
    final saved = await _exportService.saveBytes(
      bytes: bytes,
      fileName: '${_baseName(item.name)}.zip',
      mimeType: 'application/zip',
      allowedExtensions: const ['zip'],
    );
    if (!mounted || saved == null) return;
    _message('${saved.fileName} saved.');
  }

  Future<Uint8List?> _readItemBytes(WorkspaceItem item) async {
    if (item.bytes != null) return item.bytes;
    if (item.path.isEmpty) return null;
    try {
      return await File(item.path).readAsBytes();
    } catch (_) {
      return null;
    }
  }

  WorkspaceItem? get _currentItem {
    if (widget.selectedIndex < 0 ||
        widget.selectedIndex >= widget.items.length) {
      return null;
    }
    return widget.items[widget.selectedIndex];
  }

  void _showBusy(String text) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                  width: 24, height: 24, child: CircularProgressIndicator()),
              const SizedBox(width: 16),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      ),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(dot + 1).toLowerCase() : '';
  }

  String _baseName(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final duration = controller?.value.duration ?? Duration.zero;
    final position = controller?.value.position ?? Duration.zero;
    final durationMs = duration.inMilliseconds.toDouble();
    final safeMax = durationMs <= 0 ? 1.0 : durationMs;
    final positionMs =
        position.inMilliseconds.toDouble().clamp(0.0, safeMax).toDouble();

    return Column(
      children: [
        ModivkaToolBar(
          tools: [
            ToolDefinition(
                icon: Icons.video_library_outlined,
                name: 'Open',
                onPressed: widget.onOpen),
            ToolDefinition(
                icon: Icons.save_outlined,
                name: 'Save / Export',
                onPressed: _saveAs),
            ToolDefinition(
                icon: Icons.transform_rounded,
                name: 'Convert',
                onPressed: _convert),
            ToolDefinition(
                icon: Icons.compress_rounded,
                name: 'Compress',
                onPressed: _compress),
            ToolDefinition(
              icon: Icons.speed_rounded,
              name: 'Speed',
              onPressed: controller == null ? null : () => _showSpeedSheet(),
            ),
            ToolDefinition(
              icon:
                  _muted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
              name: 'Mute',
              onPressed: controller == null ? null : () => _toggleMute(),
            ),
          ],
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x267B68FF)),
            ),
            child: _buildVideoArea(controller),
          ),
        ),
        if (controller != null && controller.value.isInitialized)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(_formatDuration(position),
                    style: const TextStyle(fontSize: 11)),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: safeMax,
                    value: positionMs,
                    onChanged: (value) => controller
                        .seekTo(Duration(milliseconds: value.round())),
                  ),
                ),
                Text(_formatDuration(duration),
                    style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ItemStrip(
          items: widget.items,
          selectedIndex: widget.selectedIndex,
          onSelected: widget.onSelected,
        ),
      ],
    );
  }

  Widget _buildVideoArea(VideoPlayerController? controller) {
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: FilledButton.icon(
          onPressed: widget.onOpen,
          icon: const Icon(Icons.video_library_outlined),
          label: const Text('Open video'),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (controller.value.isPlaying) {
            controller.pause();
          } else {
            controller.play();
          }
        });
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: controller.value.isPlaying ? 0.0 : 1.0,
                child: const Icon(Icons.play_circle_filled_rounded,
                    size: 72, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _muted = !_muted);
    controller.setVolume(_muted ? 0 : 1);
  }

  void _showSpeedSheet() {
    final controller = _controller;
    if (controller == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF11101B),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Playback speed',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              ),
            ),
            for (final value in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
              ListTile(
                title: Text('$value×'),
                trailing:
                    _speed == value ? const Icon(Icons.check_rounded) : null,
                onTap: () {
                  setState(() => _speed = value);
                  controller.setPlaybackSpeed(value);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration value) {
    final h = value.inHours;
    final m = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }
}
