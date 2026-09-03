import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../models/watermark_config.dart';
import '../providers/locale_provider.dart';
import '../services/watermark_service.dart';
import '../utils/app_strings.dart';
import '../services/ads_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

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
  final List<File> _targetImages = [];
  File? _logoImage;
  Uint8List? _logoPreviewBytes;
  bool _isGeneratingPreview = false;
  final WatermarkConfig _globalConfig = WatermarkConfig();
  bool _applyToAll = true;
  int _selectedIndex = 0;
  final List<IndividualConfig> _imageConfigs = [];
  bool _isProcessing = false;
  int _processedCount = 0;
  final TextEditingController quoteController = TextEditingController();
  // ignore: prefer_final_fields
  List<String> _lastProcessedPaths = [];

  @override
  void dispose() {
    quoteController.dispose();
    super.dispose();
  }

  void _resetSession() {
    _lastProcessedPaths.clear();
    setState(() {
      _targetImages.clear();
      _logoImage = null;
      _imageConfigs.clear();
      _selectedIndex = 0;
    });
  }

    Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
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
        _selectedIndex = _targetImages.length - 1;
      });
    }
  }

  Future<void> _pickTargetImages() async {
    fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
    );

    if (result != null && result.paths.isNotEmpty) {
      final newFiles = result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();

      setState(() {
        final int startIndex = _targetImages.length;
        _targetImages.addAll(newFiles);
        _imageConfigs.addAll(
          List.generate(
            newFiles.length,
            (_) => IndividualConfig(
              xRatio: _globalConfig.customXRatio,
              yRatio: _globalConfig.customYRatio,
              scaleRatio: _globalConfig.scaleRatio,
              opacity: _globalConfig.opacity,
            ),
          ),
        );
        if (startIndex < _targetImages.length) {
          _selectedIndex = startIndex;
        }
      });
    }
  }

  Future<void> _pickLogoImage() async {
    fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _logoImage = File(result.files.single.path!);
        _logoPreviewBytes = null;
      });
      _generateLogoPreview();
    }
  }

  Future<void> _generateLogoPreview() async {
    if (_logoImage == null) return;
    setState(() {
      _isGeneratingPreview = true;
    });
    final bytes = await WatermarkService.generateLogoPreviewBytes(
      _logoImage!,
      _globalConfig.removeLogoBg,
    );
    if (!mounted) return;
    setState(() {
      _logoPreviewBytes = bytes;
      _isGeneratingPreview = false;
    });
  }

  void _updateConfig(
      {double? xRatio,
      double? yRatio,
      double? scaleRatio,
      double? opacity,
      double? rotation}) {
    setState(() {
      if (_applyToAll) {
        if (xRatio != null) _globalConfig.customXRatio = xRatio;
        if (yRatio != null) _globalConfig.customYRatio = yRatio;
        if (scaleRatio != null) _globalConfig.scaleRatio = scaleRatio;
        if (opacity != null) _globalConfig.opacity = opacity;
        if (rotation != null) _globalConfig.rotation = rotation;

        for (var cfg in _imageConfigs) {
          if (xRatio != null) cfg.xRatio = xRatio;
          if (yRatio != null) cfg.yRatio = yRatio;
          if (scaleRatio != null) cfg.scaleRatio = scaleRatio;
          if (opacity != null) cfg.opacity = opacity;
          if (rotation != null) cfg.rotation = rotation;
        }
      } else if (_imageConfigs.isNotEmpty) {
        var currentCfg = _imageConfigs[_selectedIndex];
        if (xRatio != null) currentCfg.xRatio = xRatio;
        if (yRatio != null) currentCfg.yRatio = yRatio;
        if (scaleRatio != null) currentCfg.scaleRatio = scaleRatio;
        if (opacity != null) currentCfg.opacity = opacity;
        if (rotation != null) currentCfg.rotation = rotation;
      }
    });
  }

  void _showSavedDialog(int successCount, String folderPath) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          viewInsets: EdgeInsets.zero,
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          contentPadding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
          titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 4),
          title: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.indigo.withAlpha(18),
                ),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 48,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.get(context, 'saveSuccess'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(14),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.green.withAlpha(45),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.green,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.get(
                          context,
                          'processedSuccess',
                          args: {
                            'count': '$successCount',
                            'total': '${_targetImages.length}',
                          },
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const SizedBox(height: 14),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  AppStrings.get(context, 'shareQuoteLabel'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: quoteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: AppStrings.get(context, 'quoteHint'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  AppStrings.get(context, 'savePath'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.folder_rounded,
                        color: Colors.indigo,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: SelectableText(
                        folderPath,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.indigo,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          actions: [
            if (_lastProcessedPaths.isNotEmpty)
              TextButton.icon(
                onPressed: () async {
                  final files =
                      _lastProcessedPaths.map((path) => XFile(path)).toList();

                  AdsService.showInterstitial();

                  await Share.shareXFiles(
                    files,
                    text: quoteController.text.trim().isNotEmpty
                        ? quoteController.text.trim()
                        : AppStrings.get(context, 'processedByApp'),
                  );
                },
                icon: const Icon(
                  Icons.share_rounded,
                  size: 19,
                ),
                label: Text(
                  AppStrings.get(context, 'share'),
                ),
              ),
            TextButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await const MethodChannel('watermark_pro/folder')
                    .invokeMethod<bool>(
                  'openFolder',
                  {'path': folderPath},
                );

                if (result != true && mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('تعذر فتح المجلد'),
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.folder_open_rounded,
                size: 19,
              ),
              label: Text(AppStrings.get(context, 'openFolder')),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                AdsService.showInterstitial();
              },
              icon: const Icon(
                Icons.check_rounded,
                size: 19,
              ),
              label: Text(
                AppStrings.get(context, 'ok'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImages() async {
    _lastProcessedPaths.clear();
    if (_targetImages.isEmpty || _logoImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get(context, 'pleaseSelect'))),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _processedCount = 0;
    });

    int successCount = 0;
    String lastSavedPath = "/storage/emulated/0/Pictures/WatermarkPro";

    for (int i = 0; i < _targetImages.length; i++) {
      var cfg = _imageConfigs[i];
      WatermarkConfig processCfg = WatermarkConfig(
        removeLogoBg: _globalConfig.removeLogoBg,
        mode: PositioningMode.manual,
        customXRatio: cfg.xRatio,
        customYRatio: cfg.yRatio,
        scaleRatio: cfg.scaleRatio,
        opacity: cfg.opacity,
        rotation: cfg.rotation,
      );

      final result = await WatermarkService.processImage(
        targetImageFile: _targetImages[i],
        logoFile: _logoImage!,
        config: processCfg,
      );
      if (result != null) {
        successCount++;
        lastSavedPath = result.parent.path;
        _lastProcessedPaths.add(result.path);
      }

      if (mounted) {
        setState(() {
          _processedCount = i + 1;
        });
      }
    }

    setState(() {
      _isProcessing = false;
    });

    if (mounted && successCount > 0) {
      AdsService.showRewarded();
      _showSavedDialog(successCount, lastSavedPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig =
        (_imageConfigs.isNotEmpty && _selectedIndex < _imageConfigs.length)
            ? _imageConfigs[_selectedIndex]
            : IndividualConfig();

    return ValueListenableBuilder<int>(
      valueListenable: LocaleProvider.selectedGradientIndex,
      builder: (context, bgIndex, child) {
        final isDarkBg = bgIndex == 5;

        final primary =
            isDarkBg ? const Color(0xFF9FA8DA) : const Color(0xFF5667A8);

        final accent =
            isDarkBg ? const Color(0xFFB39DDB) : const Color(0xFF7E6AA2);

        final textColor = isDarkBg ? Colors.white : const Color(0xFF263238);

        final cardColor = isDarkBg
            ? const Color(0xFF30363D).withAlpha(235)
            : Colors.white.withAlpha(245);

        return Container(
          decoration: BoxDecoration(
            gradient: LocaleProvider.bgGradients[bgIndex],
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              foregroundColor: textColor,
              leading: IconButton(
                tooltip: AppStrings.get(context, 'settingsTooltip'),
                icon: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 8,
                        offset: Offset(0, 2),
                        color: Color(0x22000000),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    size: 21,
                    color: primary,
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              title: Text(
                AppStrings.get(context, 'appTitle'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Camera',
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          offset: Offset(0, 2),
                          color: Color(0x22000000),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 21,
                      color: primary,
                    ),
                  ),
                  onPressed: _pickImageFromCamera,
                )
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        4,
                        12,
                        18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // =========================
                          // أزرار اختيار الصور والشعار والجلسة
                          // =========================
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final bool compact = constraints.maxWidth < 390;
                              final bool textOnly = constraints.maxWidth < 340;

                              Widget button({
                                required IconData icon,
                                required String title,
                                required Color color,
                                required VoidCallback onTap,
                              }) {
                                return Expanded(
                                  child: Material(
                                    color: color,
                                    borderRadius: BorderRadius.circular(13),
                                    elevation: 4,
                                    shadowColor: color.withAlpha(90),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(13),
                                      onTap: onTap,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: compact ? 9 : 11,
                                          horizontal: compact ? 3 : 6,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (!textOnly) ...[
                                              Icon(
                                                icon,
                                                color: Colors.white,
                                                size: compact ? 18 : 21,
                                              ),
                                              SizedBox(width: compact ? 3 : 6),
                                            ],
                                            Flexible(
                                              child: Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: compact ? 12 : 13.5,
                                                  fontWeight: FontWeight.w800,
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

                              return Row(
                                children: [
                                  button(
                                    icon: Icons.photo_library_rounded,
                                    title:
                                        AppStrings.get(context, 'selectImages'),
                                    color: primary,
                                    onTap: _pickTargetImages,
                                  ),
                                  SizedBox(width: compact ? 5 : 8),
                                  button(
                                    icon: Icons.branding_watermark_rounded,
                                    title:
                                        AppStrings.get(context, 'selectLogo'),
                                    color: accent,
                                    onTap: _pickLogoImage,
                                  ),
                                  SizedBox(width: compact ? 5 : 8),
                                  button(
                                    icon: Icons.refresh_rounded,
                                    title:
                                        AppStrings.get(context, 'newSession'),
                                    color: primary,
                                    onTap: _resetSession,
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          // =========================
                          // مساحة العمل
                          // =========================
                          Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 14,
                                  offset: Offset(0, 5),
                                  color: Color(0x22000000),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(9),
                            child: Column(
                              children: [
                                if (_targetImages.isEmpty)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: _pickTargetImages,
                                    child: Container(
                                      height: 230,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: isDarkBg
                                            ? Colors.black.withAlpha(45)
                                            : const Color(0xFFF1F3F6),
                                        border: Border.all(
                                          color: primary.withAlpha(90),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 48,
                                            color: primary,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            AppStrings.get(
                                              context,
                                              'noImages',
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xFF263238),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            AppStrings.get(
                                              context,
                                              'selectImages',
                                            ),
                                            style: TextStyle(
                                              color: textColor.withAlpha(150),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: Container(
                                        color: const Color(0xFFE7E9ED),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final w = constraints.maxWidth;
                                            final h = constraints.maxHeight;
                                            final logoWidth =
                                                w * currentConfig.scaleRatio;

                                            return Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image.file(
                                                  _targetImages[_selectedIndex],
                                                  fit: BoxFit.cover,
                                                ),
                                                if (_logoImage != null)
                                                  Positioned(
                                                    left:
                                                        (currentConfig.xRatio *
                                                                w) -
                                                            (logoWidth / 2),
                                                    top: (currentConfig.yRatio *
                                                            h) -
                                                        (logoWidth / 2),
                                                    child: GestureDetector(
                                                      onPanUpdate: (details) {
                                                        final newX =
                                                            ((currentConfig.xRatio *
                                                                        w) +
                                                                    details
                                                                        .delta
                                                                        .dx) /
                                                                w;

                                                        final newY =
                                                            ((currentConfig.yRatio *
                                                                        h) +
                                                                    details
                                                                        .delta
                                                                        .dy) /
                                                                h;

                                                        _updateConfig(
                                                          xRatio: newX.clamp(
                                                              0.05, 0.95),
                                                          yRatio: newY.clamp(
                                                              0.05, 0.95),
                                                        );
                                                      },
                                                      child: Opacity(
                                                        opacity: currentConfig
                                                            .opacity,
                                                        child: Transform.rotate(
                                                          angle: currentConfig
                                                              .rotation,
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              border:
                                                                  Border.all(
                                                                color: primary
                                                                    .withAlpha(
                                                                        190),
                                                                width: 1.5,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5),
                                                            ),
                                                            child:
                                                                _logoPreviewBytes !=
                                                                        null
                                                                    ? Image
                                                                        .memory(
                                                                        _logoPreviewBytes!,
                                                                        width:
                                                                            logoWidth,
                                                                        fit: BoxFit
                                                                            .contain,
                                                                      )
                                                                    : Image
                                                                        .file(
                                                                        _logoImage!,
                                                                        width:
                                                                            logoWidth,
                                                                        fit: BoxFit
                                                                            .contain,
                                                                      ),
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
                                  ),
                                if (_logoImage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      _isGeneratingPreview
                                          ? AppStrings.get(
                                              context, 'generatingPreview')
                                          : AppStrings.get(
                                              context, 'dragLogoHint'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: textColor.withAlpha(140),
                                      ),
                                    ),
                                  ),
                                if (_targetImages.isNotEmpty) ...[
                                  const SizedBox(height: 7),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      AppStrings.get(
                                        context,
                                        'selectedImage',
                                        args: {
                                          'current': '${_selectedIndex + 1}',
                                          'total': '${_targetImages.length}',
                                        },
                                      ),
                                      style: TextStyle(
                                        color: textColor.withAlpha(170),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  SizedBox(
                                    height: 58,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _targetImages.length,
                                      itemBuilder: (context, index) {
                                        final selected =
                                            index == _selectedIndex;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedIndex = index;
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 160),
                                            width: 58,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 3,
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: selected
                                                    ? primary
                                                    : Colors.transparent,
                                                width: selected ? 2.5 : 1,
                                              ),
                                              boxShadow: selected
                                                  ? const [
                                                      BoxShadow(
                                                        blurRadius: 6,
                                                        color:
                                                            Color(0x33000000),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                              child: Image.file(
                                                _targetImages[index],
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // =========================
                          // أدوات التعديل
                          // =========================
                          Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 14,
                                  offset: Offset(0, 5),
                                  color: Color(0x22000000),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(
                              13,
                              13,
                              13,
                              9,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _uiSwitchRow(
                                  icon: Icons.auto_fix_high_rounded,
                                  title: AppStrings.get(
                                    context,
                                    'removeLogoBg',
                                  ),
                                  value: _globalConfig.removeLogoBg,
                                  color: accent,
                                  textColor: textColor,
                                  onChanged: (value) {
                                    setState(() {
                                      _globalConfig.removeLogoBg = value;
                                    });
                                    _generateLogoPreview();

                                    if (value) {
                                      AdsService.showRewarded();
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                _uiSwitchRow(
                                  icon: Icons.select_all_rounded,
                                  title: AppStrings.get(
                                    context,
                                    'applyToAllTitle',
                                  ),
                                  value: _applyToAll,
                                  color: primary,
                                  textColor: textColor,
                                  onChanged: (value) {
                                    setState(() {
                                      _applyToAll = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _uiCompactSlider(
                                        icon: Icons.photo_size_select_large,
                                        title: AppStrings.get(
                                          context,
                                          'enlargeLogo',
                                        ),
                                        value: currentConfig.scaleRatio,
                                        min: 0.05,
                                        max: 0.6,
                                        display:
                                            '${(currentConfig.scaleRatio * 100).toInt()}%',
                                        color: primary,
                                        textColor: textColor,
                                        onChanged: (value) {
                                          _updateConfig(scaleRatio: value);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _uiCompactSlider(
                                        icon: Icons.rotate_right_rounded,
                                        title: AppStrings.get(
                                          context,
                                          'rotateLogo',
                                        ),
                                        value: currentConfig.rotation,
                                        min: -3.14,
                                        max: 3.14,
                                        display:
                                            '${(currentConfig.rotation * (180 / 3.14159)).toInt()}°',
                                        color: accent,
                                        textColor: textColor,
                                        onChanged: (value) {
                                          _updateConfig(rotation: value);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _uiCompactSlider(
                                        icon: Icons.opacity_rounded,
                                        title: AppStrings.get(
                                          context,
                                          'logoOpacity',
                                        ),
                                        value: currentConfig.opacity,
                                        min: 0.1,
                                        max: 1.0,
                                        display:
                                            '${(currentConfig.opacity * 100).toInt()}%',
                                        color: primary,
                                        textColor: textColor,
                                        onChanged: (value) {
                                          _updateConfig(opacity: value);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 13),
                                SizedBox(
                                  height: 46,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isProcessing ? null : _processImages,
                                    icon: _isProcessing
                                        ? const SizedBox(
                                            width: 21,
                                            height: 21,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.file_upload_rounded,
                                            size: 22,
                                          ),
                                    label: Text(
                                      _isProcessing
                                          ? AppStrings.get(
                                              context,
                                              'savingExporting',
                                              args: {
                                                'current': '$_processedCount',
                                                'total':
                                                    '${_targetImages.length}',
                                              },
                                            )
                                          : AppStrings.get(
                                              context,
                                              'applySave',
                                            ),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shadowColor: primary.withAlpha(90),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildBannerAd(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannerAd() {
    if (kIsWeb) return const SizedBox.shrink();
    try {
      if (!(Platform.isAndroid || Platform.isIOS)) {
        return const SizedBox.shrink();
      }
    } catch (_) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: UnityBannerAd(
        placementId: AdsService.bannerPlacementId,
        onLoad: (placementId) {},
        onFailed: (placementId, error, message) {},
      ),
    );
  }

  Widget _uiSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required Color color,
    required Color textColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _uiCompactSlider({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required String display,
    required Color color,
    required Color textColor,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Expanded(
          flex: 2,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 5,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 12,
              ),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: color,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 38,
          child: Text(
            display,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
