import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/models/workspace_item.dart';
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
  VideoPlayerController? _controller;

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

    if (widget.items.isEmpty ||
        widget.selectedIndex < 0 ||
        widget.selectedIndex >= widget.items.length) {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final path = widget.items[widget.selectedIndex].path;

    if (path.isEmpty) {
      return;
    }

    final controller = VideoPlayerController.file(File(path));

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
      });
    } catch (_) {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModivkaToolBar(
          tools: [
            ToolDefinition(
              icon: Icons.video_call_outlined,
              name: 'Open Video',
              onPressed: widget.onOpen,
            ),
            const ToolDefinition(icon: Icons.content_cut_rounded, name: 'Cut'),
            const ToolDefinition(icon: Icons.speed_rounded, name: 'Speed'),
            const ToolDefinition(icon: Icons.volume_up_outlined, name: 'Audio'),
            const ToolDefinition(
              icon: Icons.rotate_right_rounded,
              name: 'Rotate',
            ),
            const ToolDefinition(icon: Icons.undo_rounded, name: 'Undo'),
            const ToolDefinition(icon: Icons.redo_rounded, name: 'Redo'),
          ],
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _buildVideoArea(),
          ),
        ),
        const Divider(height: 1),
        ItemStrip(
          items: widget.items,
          selectedIndex: widget.selectedIndex,
          onSelected: widget.onSelected,
        ),
      ],
    );
  }

  Widget _buildVideoArea() {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: FilledButton.icon(
          onPressed: widget.onOpen,
          icon: const Icon(Icons.video_library_outlined),
          label: const Text('Open Video'),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            IconButton.filled(
              iconSize: 30,
              onPressed: () {
                setState(() {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                });
              },
              icon: Icon(
                controller.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
