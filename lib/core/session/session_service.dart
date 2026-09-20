import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/canvas_layer.dart';
import '../models/studio_session.dart';

class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.name,
    required this.savedAt,
  });

  final String id;
  final String name;
  final DateTime? savedAt;
}

class SessionService {
  const SessionService();

  Future<Directory> _rootDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/ModivkaStudioSessions');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> _indexFile() async {
    final root = await _rootDirectory();
    return File('${root.path}/index.json');
  }

  Future<Directory> _sessionDirectory(String id) async {
    final root = await _rootDirectory();
    final directory = Directory('${root.path}/$id');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Directory> _assetsDirectory(String id) async {
    final sessionDirectory = await _sessionDirectory(id);
    final directory = Directory('${sessionDirectory.path}/assets');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Map<String, dynamic>> _readIndex() async {
    final file = await _indexFile();
    if (!await file.exists()) {
      return <String, dynamic>{
        'sessions': <dynamic>[],
        'openIds': <dynamic>[],
        'activeId': null,
      };
    }

    try {
      final value = jsonDecode(await file.readAsString());
      if (value is Map<String, dynamic>) {
        return value;
      }
    } catch (_) {
      // A corrupted index should not prevent the application from opening.
    }

    return <String, dynamic>{
      'sessions': <dynamic>[],
      'openIds': <dynamic>[],
      'activeId': null,
    };
  }

  Future<void> _writeIndex(Map<String, dynamic> index) async {
    final file = await _indexFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(index),
      flush: true,
    );
  }

  Future<String?> loadActiveId() async {
    final index = await _readIndex();
    return index['activeId'] as String?;
  }

  Future<List<StudioSession>> loadOpenSessions() async {
    final index = await _readIndex();
    final openIds = (index['openIds'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .toList();

    final sessions = <StudioSession>[];
    for (final id in openIds) {
      final session = await loadSession(id);
      if (session != null) {
        sessions.add(session);
      }
    }

    return sessions;
  }

  Future<List<SessionSummary>> listSavedSessions() async {
    final index = await _readIndex();
    final values = index['sessions'];
    if (values is! List<dynamic>) {
      return const <SessionSummary>[];
    }

    return values
        .whereType<Map<String, dynamic>>()
        .map((entry) {
          final savedAtText = entry['savedAt'] as String?;
          return SessionSummary(
            id: entry['id'] as String? ?? '',
            name: entry['name'] as String? ?? 'Untitled',
            savedAt:
                savedAtText == null ? null : DateTime.tryParse(savedAtText),
          );
        })
        .where((summary) => summary.id.isNotEmpty)
        .toList();
  }

  Future<StudioSession?> loadSession(String id) async {
    final directory = await _sessionDirectory(id);
    final file = File('${directory.path}/session.json');
    if (!await file.exists()) {
      return null;
    }

    try {
      final root = jsonDecode(await file.readAsString());
      if (root is! Map<String, dynamic>) {
        return null;
      }

      final layers = <CanvasLayer>[];
      final layerValues = root['layers'];
      if (layerValues is List<dynamic>) {
        for (final raw in layerValues) {
          if (raw is! Map<String, dynamic>) {
            continue;
          }
          layers.add(await _layerFromJson(raw));
        }
      }

      return StudioSession(
        id: root['id'] as String? ?? id,
        name: root['name'] as String? ?? 'Untitled',
        layers: layers,
        dirty: false,
        selectedLayerId: root['selectedLayerId'] as String?,
        savedAt: root['savedAt'] == null
            ? null
            : DateTime.tryParse(root['savedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(StudioSession session) async {
    final now = DateTime.now();
    final assets = await _assetsDirectory(session.id);

    final layerJson = <Map<String, dynamic>>[];
    for (var index = 0; index < session.layers.length; index++) {
      final layer = session.layers[index];
      final assetPath = await _prepareAsset(
        assets,
        index,
        layer,
      );
      layerJson.add(_layerToJson(layer, assetPath: assetPath));
    }

    final sessionDirectory = await _sessionDirectory(session.id);
    final file = File('${sessionDirectory.path}/session.json');
    final root = <String, dynamic>{
      'version': 2,
      'id': session.id,
      'name': session.name,
      'savedAt': now.toIso8601String(),
      'selectedLayerId': session.selectedLayerId,
      'layers': layerJson,
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(root),
      flush: true,
    );

    session.savedAt = now;
    session.dirty = false;
    await _upsertSummary(session);
  }

  Future<String?> _prepareAsset(
    Directory assets,
    int index,
    CanvasLayer layer,
  ) async {
    if (layer.type == LayerType.text) {
      return null;
    }

    final sourcePath = layer.path;
    final extension = _extensionOf(layer.name);
    final safeName = _safeName(_stripExtension(layer.name));
    final fileName = '${index}_$safeName'
        '${extension.isEmpty ? '' : '.$extension'}';
    final destination = File('${assets.path}/$fileName');

    if (layer.type == LayerType.image) {
      final bytes = layer.bytes;
      if (bytes != null && bytes.isNotEmpty) {
        await destination.writeAsBytes(bytes, flush: true);
        return destination.path;
      }
    }

    if (sourcePath != null && sourcePath.isNotEmpty) {
      final source = File(sourcePath);
      if (await source.exists()) {
        if (source.path != destination.path) {
          if (!await destination.exists() ||
              await _differentLength(source, destination)) {
            await source.copy(destination.path);
          }
        }
        return destination.path;
      }
    }

    return null;
  }

  Future<bool> _differentLength(File a, File b) async {
    try {
      return await a.length() != await b.length();
    } catch (_) {
      return true;
    }
  }

  Map<String, dynamic> _layerToJson(
    CanvasLayer layer, {
    String? assetPath,
  }) {
    return <String, dynamic>{
      'id': layer.id,
      'name': layer.name,
      'type': layer.type.name,
      'path': assetPath ?? layer.path,
      'text': layer.text,
      'fontFamily': layer.fontFamily,
      'fontSize': layer.fontSize,
      'bold': layer.bold,
      'italic': layer.italic,
      'underline': layer.underline,
      'strikethrough': layer.strikethrough,
      'letterSpacing': layer.letterSpacing,
      'lineHeight': layer.lineHeight,
      'textColor': <String, int>{
        'r': layer.textColor.red,
        'g': layer.textColor.green,
        'b': layer.textColor.blue,
      },
      'textAlignment': layer.textAlignment.name,
      'x': layer.x,
      'y': layer.y,
      'width': layer.width,
      'height': layer.height,
      'rotation': layer.rotation,
      'opacity': layer.opacity,
      'visible': layer.visible,
      'locked': layer.locked,
      'flipHorizontal': layer.flipHorizontal,
      'flipVertical': layer.flipVertical,
    };
  }

  Future<CanvasLayer> _layerFromJson(Map<String, dynamic> json) async {
    final typeName = json['type'] as String? ?? 'image';
    final type = LayerType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => LayerType.image,
    );

    final path = json['path'] as String?;
    Uint8List? bytes;

    if (type == LayerType.image && path != null && path.isNotEmpty) {
      try {
        final file = File(path);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      } catch (_) {
        bytes = null;
      }
    }

    final color = json['textColor'];
    final colorMap =
        color is Map<String, dynamic> ? color : const <String, dynamic>{};

    final alignmentName = json['textAlignment'] as String? ?? 'left';
    final alignment = TextAlignment.values.firstWhere(
      (value) => value.name == alignmentName,
      orElse: () => TextAlignment.left,
    );

    return CanvasLayer(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Layer',
      type: type,
      bytes: bytes,
      path: path,
      text: json['text'] as String? ?? '',
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      fontSize: _double(json['fontSize'], 32),
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      underline: json['underline'] as bool? ?? false,
      strikethrough: json['strikethrough'] as bool? ?? false,
      letterSpacing: _double(json['letterSpacing'], 0),
      lineHeight: _double(json['lineHeight'], 1.2),
      textColor: ColorValue(
        _int(colorMap['r'], 255),
        _int(colorMap['g'], 255),
        _int(colorMap['b'], 255),
      ),
      textAlignment: alignment,
      x: _double(json['x'], 0),
      y: _double(json['y'], 0),
      width: _double(json['width'], 300),
      height: _double(json['height'], 300),
      rotation: _double(json['rotation'], 0),
      opacity: _double(json['opacity'], 1),
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      flipHorizontal: json['flipHorizontal'] as bool? ?? false,
      flipVertical: json['flipVertical'] as bool? ?? false,
    );
  }

  Future<void> _upsertSummary(StudioSession session) async {
    final index = await _readIndex();
    final values = (index['sessions'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    final summary = <String, dynamic>{
      'id': session.id,
      'name': session.name,
      'savedAt': session.savedAt?.toIso8601String(),
    };

    final existing = values.indexWhere(
      (entry) => entry['id'] == session.id,
    );

    if (existing >= 0) {
      values[existing] = summary;
    } else {
      values.add(summary);
    }

    index['sessions'] = values;
    await _writeIndex(index);
  }

  Future<void> updateOpenState(
    List<StudioSession> sessions,
    String? activeId,
  ) async {
    final index = await _readIndex();
    final savedValues = (index['sessions'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    final savedIds = sessions
        .where((session) => session.savedAt != null)
        .map((session) => session.id)
        .toSet();

    index['sessions'] = savedValues;
    final openIds = sessions
        .where((session) => savedIds.contains(session.id))
        .map((session) => session.id)
        .toList();
    index['openIds'] = openIds;
    index['activeId'] = savedIds.contains(activeId)
        ? activeId
        : (openIds.isEmpty ? null : openIds.last);

    await _writeIndex(index);
  }

  Future<void> deleteSavedSession(String id) async {
    final root = await _rootDirectory();
    final directory = Directory('${root.path}/$id');
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }

    final index = await _readIndex();
    final sessions = (index['sessions'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .where((entry) => entry['id'] != id)
        .toList();

    final openIds = (index['openIds'] as List<dynamic>? ?? <dynamic>[])
        .where((value) => value != id)
        .toList();

    index['sessions'] = sessions;
    index['openIds'] = openIds;
    if (index['activeId'] == id) {
      index['activeId'] = openIds.isEmpty ? null : openIds.first;
    }

    await _writeIndex(index);
  }

  String _stripExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(dot + 1).toLowerCase() : '';
  }

  String _safeName(String value) {
    final withoutExtension = value.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]+'),
      '_',
    );
    return withoutExtension.isEmpty ? 'layer' : withoutExtension;
  }

  double _double(Object? value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }

  int _int(Object? value, int fallback) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
