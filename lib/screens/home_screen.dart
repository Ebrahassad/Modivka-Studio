import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/models/watermark_config.dart';
import '../core/watermark/watermark_engine.dart';
import '../core/export/export_service.dart';
import '../core/export/export_result.dart';
import '../providers/locale_provider.dart';
import '../widgets/export_success_dialog.dart';
import '../utils/app_strings.dart';

class IndividualConfig {
  double xRatio;
  double yRatio;
  double scaleRatio;
  double opacity;
  double rotation;

  IndividualConfig({
    this.xRatio = 0.8,
    this.yRatio = 0.8,
    this.scaleRatio = 0.25,
    this.opacity = 1.0,
    this.rotation = 0.0,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const WatermarkEngine _watermarkEngine = WatermarkEngine();

  final List<File> _targetImages = [];
  final List<IndividualConfig> _imageConfigs = [];

  File? _logoImage;
  Uint8List? _logoPreviewBytes;

  WatermarkConfig _globalConfig = const WatermarkConfig();

  bool _applyToAll = true;
  bool _isGeneratingPreview = false;
  bool _isProcessing = false;

  int _selectedImage = 0;
  int _processedCount = 0;

  String _activeModule = 'Watermark';

  double _modifyRotation = 0.0;
  double _modifyOpacity = 1.0;
  double _modifyBrightness = 0.0;
  double _modifyCrop = 1.0;
  bool _modifyFlipX = false;
  bool _modifyFlipY = false;

  double _projectWidth = 1200.0;
  double _projectHeight = 800.0;
  Color _projectBackground = Colors.white;
  bool _projectCreated = false;
  bool _showProjectsWorkspace = false;

  final TextEditingController quoteController = TextEditingController();

  @override
  void dispose() {
    quoteController.dispose();
    super.dispose();
  }

  void _resetSession() {
    setState(() {
      _targetImages.clear();
      _imageConfigs.clear();
      _logoImage = null;
      _logoPreviewBytes = null;
      _selectedImage = 0;
      _processedCount = 0;
    });
  }

  Future<void> _pickTargetImages() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
    );

    if (result == null) return;

    final files = result.paths.whereType<String>().map(File.new).toList();

    if (files.isEmpty) return;

    setState(() {
      final start = _targetImages.length;

      _targetImages.addAll(files);

      _imageConfigs.addAll(
        List.generate(
          files.length,
          (_) => IndividualConfig(
            xRatio: _globalConfig.customXRatio,
            yRatio: _globalConfig.customYRatio,
            scaleRatio: _globalConfig.scaleRatio,
            opacity: _globalConfig.opacity,
          ),
        ),
      );

      _selectedImage = start;
    });
  }

  Future<void> _pickImageFromCamera() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );

    if (photo == null) return;

    setState(() {
      _targetImages.add(File(photo.path));
      _imageConfigs.add(
        IndividualConfig(
          xRatio: _globalConfig.customXRatio,
          yRatio: _globalConfig.customYRatio,
          scaleRatio: _globalConfig.scaleRatio,
          opacity: _globalConfig.opacity,
        ),
      );
      _selectedImage = _targetImages.length - 1;
    });
  }

  Future<void> _pickLogoImage() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    setState(() {
      _logoImage = File(result.files.single.path!);
      _logoPreviewBytes = null;
    });

    await _generateLogoPreview();
  }

  Future<void> _generateLogoPreview() async {
    if (_logoImage == null) return;

    setState(() {
      _isGeneratingPreview = true;
    });

    final bytes = _watermarkEngine.generateLogoPreview(
      await _logoImage!.readAsBytes(),
      removeBg: _globalConfig.removeLogoBg,
    );

    if (!mounted) return;

    setState(() {
      _logoPreviewBytes = bytes;
      _isGeneratingPreview = false;
    });
  }

  void _updateConfig({
    double? xRatio,
    double? yRatio,
    double? scaleRatio,
    double? opacity,
    double? rotation,
  }) {
    setState(() {
      if (_applyToAll) {
        _globalConfig = _globalConfig.copyWith(
          customXRatio: xRatio,
          customYRatio: yRatio,
          scaleRatio: scaleRatio,
          opacity: opacity,
          rotation: rotation,
        );

        for (final cfg in _imageConfigs) {
          if (xRatio != null) cfg.xRatio = xRatio;
          if (yRatio != null) cfg.yRatio = yRatio;
          if (scaleRatio != null) cfg.scaleRatio = scaleRatio;
          if (opacity != null) cfg.opacity = opacity;
          if (rotation != null) cfg.rotation = rotation;
        }
      } else if (_imageConfigs.isNotEmpty) {
        final cfg = _imageConfigs[_selectedImage];

        if (xRatio != null) cfg.xRatio = xRatio;
        if (yRatio != null) cfg.yRatio = yRatio;
        if (scaleRatio != null) cfg.scaleRatio = scaleRatio;
        if (opacity != null) cfg.opacity = opacity;
        if (rotation != null) cfg.rotation = rotation;
      }
    });
  }

  Future<void> _processImages() async {
    if (_targetImages.isEmpty || _logoImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.get(context, 'pleaseSelect'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _processedCount = 0;
    });

    int successCount = 0;
    final exportedPaths = <String>[];
    String outputDirectory = '';

    for (int i = 0; i < _targetImages.length; i++) {
      final cfg = _imageConfigs[i];

      final processConfig = WatermarkConfig(
        removeLogoBg: _globalConfig.removeLogoBg,
        mode: PositioningMode.manual,
        customXRatio: cfg.xRatio,
        customYRatio: cfg.yRatio,
        scaleRatio: cfg.scaleRatio,
        opacity: cfg.opacity,
        rotation: cfg.rotation,
      );

      final resultBytes = _watermarkEngine.process(
        targetBytes: await _targetImages[i].readAsBytes(),
        logoBytes: await _logoImage!.readAsBytes(),
        config: processConfig,
      );

      if (resultBytes != null) {
        final extension =
            processConfig.exportFormat == ExportFormat.png ? 'png' : 'jpg';

        final output = await const ExportService().exportBytes(
          module: 'Watermark',
          files: [resultBytes],
          extension: extension,
          prefix: 'Watermark',
        );

        if (output.success) {
          successCount += output.successCount;
          exportedPaths.addAll(output.savedPaths);
          outputDirectory = output.outputDirectory;
        }
      }

      if (mounted) {
        setState(() {
          _processedCount = i + 1;
        });
      }
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    if (successCount > 0) {
      await ExportSuccessDialog.show(
        context,
        ExportResult(
          successCount: successCount,
          totalCount: _targetImages.length,
          outputDirectory: outputDirectory,
          savedPaths: exportedPaths,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: LocaleProvider.selectedGradientIndex,
      builder: (context, bgIndex, child) {
        final isDark = bgIndex == 5;

        final textColor = isDark ? Colors.white : const Color(0xFF20242A);

        final panelColor = isDark ? const Color(0xFF171A20) : Colors.white;

        final accent =
            isDark ? const Color(0xFFB8A7FF) : const Color(0xFF5667A8);

        return Container(
          decoration: BoxDecoration(
            gradient: LocaleProvider.bgGradients[bgIndex],
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: panelColor.withAlpha(235),
              foregroundColor: textColor,
              titleSpacing: 16,
              title: Row(
                children: [
                  Image.asset(
                    'assets/icon/app_icon.png',
                    width: 34,
                    height: 34,
                    errorBuilder: (_, __, ___) {
                      return Icon(
                        Icons.auto_awesome_rounded,
                        color: accent,
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Modivka Studio',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              actions: [
                _topAction(
                  icon: Icons.folder_copy_rounded,
                  label: 'Projects',
                  onPressed: () {
                    setState(() {
                      _showProjectsWorkspace = true;
                    });
                  },
                ),
                _topAction(
                  icon: Icons.grid_view_rounded,
                  label: 'Modules',
                  onPressed: () {},
                ),
                IconButton(
                  tooltip: AppStrings.get(
                    context,
                    'settingsTooltip',
                  ),
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/settings',
                    );
                  },
                ),
                const SizedBox(width: 6),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  _buildModuleBar(
                    panelColor,
                    textColor,
                    accent,
                  ),
                  Expanded(
                    child: _showProjectsWorkspace
                        ? _buildProjectsWorkspace(
                            panelColor,
                            textColor,
                            accent,
                          )
                        : _buildWorkspace(
                            panelColor,
                            textColor,
                            accent,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label),
      ),
    );
  }

  Widget _buildModuleBar(
    Color panelColor,
    Color textColor,
    Color accent,
  ) {
    return Container(
      height: 62,
      width: double.infinity,
      decoration: BoxDecoration(
        color: panelColor.withAlpha(225),
        border: Border(
          bottom: BorderSide(
            color: textColor.withAlpha(18),
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        children: [
          _moduleButton(
            icon: Icons.branding_watermark_rounded,
            title: 'Watermark',
            active: _activeModule == 'Watermark',
            accent: accent,
            onTap: () => _selectModule('Watermark'),
          ),
          _moduleButton(
            icon: Icons.auto_awesome_rounded,
            title: 'Create',
            active: _activeModule == 'Create',
            accent: accent,
            onTap: () => _selectModule('Create'),
          ),
          _moduleButton(
            icon: Icons.tune_rounded,
            title: 'Modify',
            active: _activeModule == 'Modify',
            accent: accent,
            onTap: () => _selectModule('Modify'),
          ),
          _moduleButton(
            icon: Icons.swap_horiz_rounded,
            title: 'Convert',
            active: _activeModule == 'Convert',
            accent: accent,
            onTap: () => _selectModule('Convert'),
          ),
          _moduleButton(
            icon: Icons.photo_library_rounded,
            title: 'Assets',
            active: _activeModule == 'Assets',
            accent: accent,
            onTap: () => _selectModule('Assets'),
          ),
        ],
      ),
    );
  }

  void _selectModule(String module) {
    if (_activeModule == module) return;

    setState(() {
      _activeModule = module;
    });
  }

  Widget _moduleButton({
    required IconData icon,
    required String title,
    required Color accent,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: active ? accent.withAlpha(35) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 8,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active ? accent : null,
                ),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                    color: active ? accent : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsWorkspace(
    Color panelColor,
    Color textColor,
    Color accent,
  ) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor.withAlpha(235),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: textColor.withAlpha(18),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: panelColor.withAlpha(245),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_copy_rounded,
                  color: accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Projects',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _showCreateProjectDialog,
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('New Project'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Close Projects',
                  onPressed: () {
                    setState(() {
                      _showProjectsWorkspace = false;
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: _projectCreated
                ? Center(
                    child: Container(
                      width: 420,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: textColor.withAlpha(10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: accent.withAlpha(45),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description_rounded,
                            size: 58,
                            color: accent,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Current Project',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_projectWidth.round()} × ${_projectHeight.round()} px',
                            style: TextStyle(
                              color: textColor.withAlpha(170),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _showProjectsWorkspace = false;
                                _activeModule = 'Create';
                              });
                            },
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Open Project'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          size: 76,
                          color: accent.withAlpha(180),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Projects',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a new project to start working.',
                          style: TextStyle(
                            color: textColor.withAlpha(150),
                          ),
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _showCreateProjectDialog,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('New Project'),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifyWorkspace(
    Color panelColor,
    Color textColor,
    Color accent,
  ) {
    final hasImage = _targetImages.isNotEmpty &&
        _selectedImage >= 0 &&
        _selectedImage < _targetImages.length;

    final currentImage = hasImage ? _targetImages[_selectedImage] : null;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor.withAlpha(235),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: textColor.withAlpha(18),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: panelColor.withAlpha(245),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: accent,
                  size: 23,
                ),
                const SizedBox(width: 10),
                Text(
                  'Modify Workspace',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Reset',
                  onPressed: hasImage
                      ? () {
                          setState(() {
                            _modifyRotation = 0;
                            _modifyOpacity = 1;
                            _modifyBrightness = 0;
                            _modifyCrop = 1;
                            _modifyFlipX = false;
                            _modifyFlipY = false;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.restart_alt_rounded),
                ),
                FilledButton.icon(
                  onPressed: hasImage ? () {} : null,
                  icon: const Icon(
                    Icons.download_rounded,
                    size: 18,
                  ),
                  label: const Text('Export'),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 72,
                      decoration: BoxDecoration(
                        color: panelColor.withAlpha(220),
                        border: Border(
                          right: BorderSide(
                            color: textColor.withAlpha(15),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _modifyTool(
                            Icons.near_me_rounded,
                            'Select',
                            accent,
                            onPressed: () {},
                          ),
                          _modifyTool(
                            Icons.crop_rounded,
                            'Crop',
                            accent,
                            onPressed: hasImage
                                ? () {
                                    setState(() {
                                      _modifyCrop =
                                          _modifyCrop <= 0.5 ? 1.0 : 0.7;
                                    });
                                  }
                                : null,
                          ),
                          _modifyTool(
                            Icons.rotate_90_degrees_ccw_rounded,
                            'Rotate',
                            accent,
                            onPressed: hasImage
                                ? () {
                                    setState(() {
                                      _modifyRotation += 90;
                                      if (_modifyRotation >= 360) {
                                        _modifyRotation -= 360;
                                      }
                                    });
                                  }
                                : null,
                          ),
                          _modifyTool(
                            Icons.flip_rounded,
                            'Flip',
                            accent,
                            onPressed: hasImage
                                ? () {
                                    setState(() {
                                      _modifyFlipX = !_modifyFlipX;
                                    });
                                  }
                                : null,
                          ),
                          _modifyTool(
                            Icons.auto_fix_high_rounded,
                            'Adjust',
                            accent,
                            onPressed: hasImage
                                ? () {
                                    setState(() {
                                      _modifyBrightness =
                                          _modifyBrightness >= 0.5
                                              ? 0.0
                                              : _modifyBrightness + 0.25;
                                    });
                                  }
                                : null,
                          ),
                          _modifyTool(
                            Icons.blur_on_rounded,
                            'Blur',
                            accent,
                            onPressed: null,
                          ),
                          _modifyTool(
                            Icons.text_fields_rounded,
                            'Text',
                            accent,
                            onPressed: null,
                          ),
                          _modifyTool(
                            Icons.layers_rounded,
                            'Layers',
                            accent,
                            onPressed: null,
                          ),
                          const Spacer(),
                          _modifyTool(
                            Icons.zoom_out_rounded,
                            'Zoom Out',
                            accent,
                            onPressed: null,
                          ),
                          _modifyTool(
                            Icons.zoom_in_rounded,
                            'Zoom In',
                            accent,
                            onPressed: null,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: textColor.withAlpha(18),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                width: wide ? 520 : 300,
                                height: wide ? 350 : 230,
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 28,
                                      offset: Offset(0, 10),
                                      color: Color(0x33000000),
                                    ),
                                  ],
                                ),
                                child: hasImage
                                    ? Center(
                                        child: ClipRect(
                                          child: SizedBox(
                                            width: 520 * _modifyCrop,
                                            height: 350 * _modifyCrop,
                                            child: Transform(
                                              alignment: Alignment.center,
                                              transform: Matrix4.identity()
                                                ..scaleByDouble(
                                                  _modifyFlipX ? -1.0 : 1.0,
                                                  _modifyFlipY ? -1.0 : 1.0,
                                                  1.0,
                                                  1.0,
                                                )
                                                ..rotateZ(
                                                  _modifyRotation *
                                                      3.14159265359 /
                                                      180,
                                                ),
                                              child: Opacity(
                                                opacity: _modifyOpacity,
                                                child: ColorFiltered(
                                                  colorFilter:
                                                      ColorFilter.matrix(
                                                    <double>[
                                                      1,
                                                      0,
                                                      0,
                                                      0,
                                                      _modifyBrightness * 255,
                                                      0,
                                                      1,
                                                      0,
                                                      0,
                                                      _modifyBrightness * 255,
                                                      0,
                                                      0,
                                                      1,
                                                      0,
                                                      _modifyBrightness * 255,
                                                      0,
                                                      0,
                                                      0,
                                                      1,
                                                      0,
                                                    ],
                                                  ),
                                                  child: Image.file(
                                                    currentImage!,
                                                    fit: BoxFit.contain,
                                                    width: 520,
                                                    height: 350,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.image_outlined,
                                              size: 58,
                                              color: Color(0xFF9AA0A6),
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'Open an image to start editing',
                                              style: TextStyle(
                                                color: Color(0xFF777777),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: panelColor.withAlpha(235),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: textColor.withAlpha(18),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      hasImage
                                          ? Icons.image_rounded
                                          : Icons.image_outlined,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        hasImage
                                            ? currentImage!.path.split('/').last
                                            : 'No image selected',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(_modifyOpacity * 100).round()}%',
                                      style: TextStyle(
                                        color: textColor.withAlpha(150),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (wide)
                      Container(
                        width: 290,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: panelColor.withAlpha(225),
                          border: Border(
                            left: BorderSide(
                              color: textColor.withAlpha(15),
                            ),
                          ),
                        ),
                        child: ListView(
                          children: [
                            Text(
                              'Properties',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _modifyProperty(
                              'Image',
                              hasImage ? 'Selected' : 'None',
                            ),
                            _modifyProperty(
                              'Rotation',
                              '${_modifyRotation.round()}°',
                            ),
                            _modifyProperty(
                              'Crop',
                              '${(_modifyCrop * 100).round()}%',
                            ),
                            _modifyProperty(
                              'Brightness',
                              '${(_modifyBrightness * 100).round()}%',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Opacity',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Slider(
                              value: _modifyOpacity,
                              min: 0,
                              max: 1,
                              onChanged: hasImage
                                  ? (value) {
                                      setState(() {
                                        _modifyOpacity = value;
                                      });
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _pickTargetImages,
                              icon: const Icon(
                                Icons.image_rounded,
                              ),
                              label: const Text('Open Image'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: hasImage
                                  ? () {
                                      setState(() {
                                        _modifyFlipY = !_modifyFlipY;
                                      });
                                    }
                                  : null,
                              icon: const Icon(
                                Icons.swap_vert_rounded,
                              ),
                              label: const Text('Flip Vertical'),
                            ),
                          ],
                        ),
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

  Widget _modifyTool(
    IconData icon,
    String label,
    Color accent, {
    VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 250),
        showDuration: const Duration(seconds: 2),
        preferBelow: false,
        verticalOffset: 8,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: enabled ? accent.withAlpha(12) : Colors.transparent,
              border: Border.all(
                color: enabled ? accent.withAlpha(28) : Colors.transparent,
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: enabled ? accent : accent.withAlpha(75),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modifyProperty(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.withAlpha(70),
              ),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace(
    Color panelColor,
    Color textColor,
    Color accent,
  ) {
    switch (_activeModule) {
      case 'Create':
        return _buildModuleWorkspace(
          'Create',
          'Create new projects and designs',
          Icons.auto_awesome_rounded,
          panelColor,
          textColor,
          accent,
        );

      case 'Modify':
        return _buildModifyWorkspace(
          panelColor,
          textColor,
          accent,
        );

      case 'Convert':
        return _buildModuleWorkspace(
          'Convert',
          'Convert files between supported formats',
          Icons.swap_horiz_rounded,
          panelColor,
          textColor,
          accent,
        );

      case 'Assets':
        return _buildModuleWorkspace(
          'Assets',
          'Manage images, logos and project assets',
          Icons.photo_library_rounded,
          panelColor,
          textColor,
          accent,
        );

      case 'Watermark':
      default:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildCanvas(
                panelColor,
                textColor,
                accent,
              ),
            ),
            SizedBox(
              width: 280,
              child: _buildToolsPanel(
                panelColor,
                textColor,
                accent,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildModuleWorkspace(
    String title,
    String subtitle,
    IconData icon,
    Color panelColor,
    Color textColor,
    Color accent,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildModuleToolRail(
          icon: icon,
          title: title,
          panelColor: panelColor,
          textColor: textColor,
          accent: accent,
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 12, 0, 12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: textColor.withAlpha(20),
              ),
            ),
            child: Column(
              children: [
                _buildWorkspaceHeader(
                  title: title,
                  icon: icon,
                  textColor: textColor,
                  accent: accent,
                ),
                Expanded(
                  child: _buildModuleCanvas(
                    title: title,
                    icon: icon,
                    panelColor: panelColor,
                    textColor: textColor,
                    accent: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildModuleProperties(
          title: title,
          panelColor: panelColor,
          textColor: textColor,
          accent: accent,
        ),
      ],
    );
  }

  Widget _buildWorkspaceHeader({
    required IconData icon,
    required String title,
    required Color textColor,
    required Color accent,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: textColor.withAlpha(15),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: accent,
          ),
          const SizedBox(width: 9),
          Text(
            '$title Workspace',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'New Project',
            onPressed: () {},
            icon: const Icon(
              Icons.add_box_outlined,
              size: 21,
            ),
          ),
          IconButton(
            tooltip: 'Open Project',
            onPressed: () {},
            icon: const Icon(
              Icons.folder_open_rounded,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleToolRail({
    required IconData icon,
    required String title,
    required Color panelColor,
    required Color textColor,
    required Color accent,
  }) {
    final tools = _moduleTools(title);

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: panelColor.withAlpha(245),
        border: Border(
          right: BorderSide(
            color: textColor.withAlpha(15),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 8,
        ),
        children: [
          _workspaceTool(
            icon: icon,
            label: title,
            active: true,
            accent: accent,
          ),
          const SizedBox(height: 8),
          ...tools.map(
            (tool) => _workspaceTool(
              icon: tool.$1,
              label: tool.$2,
              accent: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _workspaceTool({
    required IconData icon,
    required String label,
    required Color accent,
    bool active = false,
  }) {
    return Tooltip(
      message: label,
      child: Container(
        height: 50,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: active ? accent.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          size: 22,
          color: active ? accent : null,
        ),
      ),
    );
  }

  List<(IconData, String)> _moduleTools(String title) {
    switch (title) {
      case 'Create':
        return const [
          (Icons.text_fields_rounded, 'Text'),
          (Icons.crop_square_rounded, 'Shape'),
          (Icons.image_rounded, 'Image'),
          (Icons.layers_rounded, 'Layers'),
        ];

      case 'Modify':
        return const [
          (Icons.crop_rounded, 'Crop'),
          (Icons.rotate_90_degrees_ccw_rounded, 'Rotate'),
          (Icons.tune_rounded, 'Adjust'),
          (Icons.auto_fix_high_rounded, 'Enhance'),
        ];

      case 'Convert':
        return const [
          (Icons.image_rounded, 'Image'),
          (Icons.picture_as_pdf_rounded, 'PDF'),
          (Icons.swap_vert_rounded, 'Format'),
          (Icons.compress_rounded, 'Compress'),
        ];

      case 'Assets':
        return const [
          (Icons.image_rounded, 'Images'),
          (Icons.branding_watermark_rounded, 'Logos'),
          (Icons.folder_rounded, 'Folders'),
          (Icons.collections_rounded, 'Library'),
        ];

      default:
        return const [];
    }
  }

  Future<void> _showCreateProjectDialog() async {
    final widthController = TextEditingController(
      text: _projectWidth.round().toString(),
    );
    final heightController = TextEditingController(
      text: _projectHeight.round().toString(),
    );

    Color selectedBackground = _projectBackground;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.add_box_rounded),
                  SizedBox(width: 10),
                  Text(
                    'New Project',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 390,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Canvas Size',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: widthController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Width',
                                suffixText: 'px',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Height',
                                suffixText: 'px',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Presets',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _projectPreset(
                            'Square',
                            1080,
                            1080,
                            widthController,
                            heightController,
                            setDialogState,
                          ),
                          _projectPreset(
                            'HD',
                            1280,
                            720,
                            widthController,
                            heightController,
                            setDialogState,
                          ),
                          _projectPreset(
                            'Full HD',
                            1920,
                            1080,
                            widthController,
                            heightController,
                            setDialogState,
                          ),
                          _projectPreset(
                            'Portrait',
                            1080,
                            1350,
                            widthController,
                            heightController,
                            setDialogState,
                          ),
                          _projectPreset(
                            'Story',
                            1080,
                            1920,
                            widthController,
                            heightController,
                            setDialogState,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Background',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          _backgroundChoice(
                            Colors.white,
                            selectedBackground,
                            () {
                              setDialogState(() {
                                selectedBackground = Colors.white;
                              });
                            },
                          ),
                          _backgroundChoice(
                            Colors.black,
                            selectedBackground,
                            () {
                              setDialogState(() {
                                selectedBackground = Colors.black;
                              });
                            },
                          ),
                          _backgroundChoice(
                            const Color(0xFFF1F3F6),
                            selectedBackground,
                            () {
                              setDialogState(() {
                                selectedBackground = const Color(0xFFF1F3F6);
                              });
                            },
                          ),
                          _backgroundChoice(
                            const Color(0xFF20242A),
                            selectedBackground,
                            () {
                              setDialogState(() {
                                selectedBackground = const Color(0xFF20242A);
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final width = double.tryParse(widthController.text.trim());
                    final height =
                        double.tryParse(heightController.text.trim());

                    if (width == null ||
                        height == null ||
                        width <= 0 ||
                        height <= 0) {
                      return;
                    }

                    setState(() {
                      _projectWidth = width;
                      _projectHeight = height;
                      _projectBackground = selectedBackground;
                      _projectCreated = true;
                    });

                    Navigator.pop(dialogContext);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'Create',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    widthController.dispose();
    heightController.dispose();
  }

  Widget _projectPreset(
    String label,
    int width,
    int height,
    TextEditingController widthController,
    TextEditingController heightController,
    StateSetter setDialogState,
  ) {
    return OutlinedButton(
      onPressed: () {
        setDialogState(() {
          widthController.text = width.toString();
          heightController.text = height.toString();
        });
      },
      child: Text(label),
    );
  }

  Widget _backgroundChoice(
    Color color,
    Color selected,
    VoidCallback onTap,
  ) {
    final isSelected = color.toARGB32() == selected.toARGB32();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check_rounded,
                size: 20,
                color: color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildModuleCanvas({
    required String title,
    required IconData icon,
    required Color panelColor,
    required Color textColor,
    required Color accent,
  }) {
    if (title != 'Create') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: accent),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Workspace ready',
              style: TextStyle(
                color: textColor.withAlpha(150),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = _projectCreated ? _projectWidth : 1080.0;
        final canvasHeight = _projectCreated ? _projectHeight : 1080.0;

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(28),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: textColor.withAlpha(18),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CreateGridPainter(
                    lineColor: textColor.withAlpha(16),
                  ),
                ),
              ),
              Center(
                child: InteractiveViewer(
                  minScale: 0.25,
                  maxScale: 4,
                  boundaryMargin: const EdgeInsets.all(120),
                  child: Container(
                    width: constraints.maxWidth > 700
                        ? 560
                        : constraints.maxWidth * 0.72,
                    height: constraints.maxHeight > 500
                        ? 380
                        : constraints.maxHeight * 0.58,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(35),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 35,
                          spreadRadius: 2,
                          color: Color(0x55000000),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: canvasWidth / canvasHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _projectBackground,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 25,
                                spreadRadius: 1,
                                color: Color(0x55000000),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 12,
                                top: 10,
                                child: Text(
                                  '${canvasWidth.round()} × ${canvasHeight.round()} px',
                                  style: TextStyle(
                                    color:
                                        _projectBackground.computeLuminance() >
                                                0.5
                                            ? Colors.black54
                                            : Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (!_projectCreated)
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 52,
                                        color: accent,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Create something new',
                                        style: TextStyle(
                                          color: _projectBackground
                                                      .computeLuminance() >
                                                  0.5
                                              ? const Color(0xFF20242A)
                                              : Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Start with a blank canvas',
                                        style: TextStyle(
                                          color: _projectBackground
                                                      .computeLuminance() >
                                                  0.5
                                              ? Colors.black54
                                              : Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: panelColor.withAlpha(235),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: textColor.withAlpha(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.dashboard_customize_rounded,
                        size: 19,
                        color: accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _projectCreated
                            ? '${_projectWidth.round()} × ${_projectHeight.round()} px'
                            : 'No project',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Zoom out',
                        onPressed: () {},
                        icon: const Icon(
                          Icons.remove_rounded,
                          size: 18,
                        ),
                      ),
                      const Text(
                        '100%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Zoom in',
                        onPressed: () {},
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 14,
                child: FilledButton.icon(
                  onPressed: _showCreateProjectDialog,
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 19,
                  ),
                  label: Text(
                    _projectCreated ? 'New Project' : 'Create Project',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModuleProperties({
    required String title,
    required Color panelColor,
    required Color textColor,
    required Color accent,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor.withAlpha(245),
        border: Border(
          left: BorderSide(
            color: textColor.withAlpha(15),
          ),
        ),
      ),
      child: ListView(
        children: [
          Text(
            'Properties',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _propertyPlaceholder(
            icon: Icons.layers_outlined,
            title: 'Layers',
            textColor: textColor,
          ),
          _propertyPlaceholder(
            icon: Icons.tune_rounded,
            title: 'Adjustments',
            textColor: textColor,
          ),
          _propertyPlaceholder(
            icon: Icons.settings_outlined,
            title: 'Settings',
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _propertyPlaceholder({
    required IconData icon,
    required String title,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textColor.withAlpha(7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: textColor.withAlpha(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: textColor.withAlpha(150),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: TextStyle(
              color: textColor.withAlpha(180),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas(
    Color panelColor,
    Color textColor,
    Color accent,
  ) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: textColor.withAlpha(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: panelColor.withAlpha(220),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.branding_watermark_rounded,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Watermark Workspace',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Camera',
                  onPressed: _pickImageFromCamera,
                  icon: const Icon(
                    Icons.camera_alt_rounded,
                    size: 20,
                  ),
                ),
                IconButton(
                  tooltip: 'New Session',
                  onPressed: _resetSession,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _targetImages.isEmpty
                ? _emptyCanvas(
                    textColor,
                    accent,
                  )
                : _imageWorkspace(
                    textColor,
                    accent,
                  ),
          ),
          _buildBottomBar(
            panelColor,
            textColor,
            accent,
          ),
        ],
      ),
    );
  }

  Widget _emptyCanvas(
    Color textColor,
    Color accent,
  ) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _pickTargetImages,
        child: Container(
          width: 360,
          constraints: const BoxConstraints(
            maxWidth: 360,
          ),
          padding: const EdgeInsets.all(34),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withAlpha(80),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_rounded,
                size: 64,
                color: accent,
              ),
              const SizedBox(height: 18),
              Text(
                AppStrings.get(context, 'noImages'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select images to begin working',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageWorkspace(
    Color textColor,
    Color accent,
  ) {
    final file = _targetImages[_selectedImage];

    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 650,
                  maxHeight: 650,
                ),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 30,
                      color: Colors.black.withAlpha(80),
                    ),
                  ],
                ),
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        if (_targetImages.length > 1)
          SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              itemCount: _targetImages.length,
              itemBuilder: (context, index) {
                final selected = index == _selectedImage;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImage = index;
                    });
                  },
                  child: Container(
                    width: 58,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? accent : textColor.withAlpha(40),
                        width: selected ? 3 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(
                      _targetImages[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildToolsPanel(
    Color panelColor,
    Color textColor,
    Color accent,
  ) {
    final cfg = _imageConfigs.isNotEmpty
        ? _imageConfigs[_selectedImage]
        : IndividualConfig();

    return Container(
      margin: const EdgeInsets.fromLTRB(
        0,
        12,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: panelColor.withAlpha(230),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: textColor.withAlpha(18),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text(
            'Watermark Tools',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          _toolButton(
            icon: Icons.photo_library_rounded,
            title: 'Select Images',
            onTap: _pickTargetImages,
            accent: accent,
          ),
          _toolButton(
            icon: Icons.branding_watermark_rounded,
            title: 'Select Logo',
            onTap: _pickLogoImage,
            accent: accent,
          ),
          const SizedBox(height: 12),
          if (_logoPreviewBytes != null)
            Container(
              height: 100,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withAlpha(18),
              ),
              child: Image.memory(
                _logoPreviewBytes!,
                fit: BoxFit.contain,
              ),
            )
          else if (_isGeneratingPreview)
            const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Apply to all images',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            value: _applyToAll,
            onChanged: (value) {
              setState(() {
                _applyToAll = value;
              });
            },
          ),
          _slider(
            label: 'Size',
            value: cfg.scaleRatio,
            min: 0.05,
            max: 0.8,
            onChanged: (v) {
              _updateConfig(scaleRatio: v);
            },
          ),
          _slider(
            label: 'Opacity',
            value: cfg.opacity,
            min: 0.05,
            max: 1,
            onChanged: (v) {
              _updateConfig(opacity: v);
            },
          ),
          _slider(
            label: 'Horizontal',
            value: cfg.xRatio,
            min: 0,
            max: 1,
            onChanged: (v) {
              _updateConfig(xRatio: v);
            },
          ),
          _slider(
            label: 'Vertical',
            value: cfg.yRatio,
            min: 0,
            max: 1,
            onChanged: (v) {
              _updateConfig(yRatio: v);
            },
          ),
          _slider(
            label: 'Rotation',
            value: cfg.rotation,
            min: -3.14,
            max: 3.14,
            onChanged: (v) {
              _updateConfig(rotation: v);
            },
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _isProcessing ? null : _processImages,
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(
              _isProcessing
                  ? 'Processing $_processedCount/${_targetImages.length}'
                  : 'Export',
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: accent),
        label: Text(title),
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    Color panelColor,
    Color textColor,
    Color accent,
  ) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: panelColor.withAlpha(230),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _pickTargetImages,
            icon: const Icon(
              Icons.add_photo_alternate_rounded,
              size: 18,
            ),
            label: const Text('Images'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _pickLogoImage,
            icon: const Icon(
              Icons.branding_watermark_rounded,
              size: 18,
            ),
            label: const Text('Logo'),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _isProcessing ? null : _processImages,
            icon: const Icon(
              Icons.save_rounded,
              size: 18,
            ),
            label: Text(
              _isProcessing
                  ? '$_processedCount/${_targetImages.length}'
                  : 'Export',
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateGridPainter extends CustomPainter {
  final Color lineColor;

  const _CreateGridPainter({
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    const spacing = 32.0;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CreateGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
