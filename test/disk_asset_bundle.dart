import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glob/glob.dart';

/// A simple implementation of [AssetBundle] that reads files from an asset dir.
///
/// This is meant to be similar to the default [rootBundle] for testing.
class DiskAssetBundle extends CachingAssetBundle {
  DiskAssetBundle._(this._cache);
  static const _assetManifestDotJson = 'AssetManifest.json';

  /// Creates a [DiskAssetBundle] by loading [globs] of assets under `assets/`.
  static Future<AssetBundle> loadGlob(
    Iterable<String> globs, {
    String from = 'assets',
  }) async {
    final cache = <String, ByteData>{};
    for (final pattern in globs) {
      await for (final path in Glob(pattern).list(root: from)) {
        if (path is File) {
          // ignore: avoid_as
          final bytes = await path.readAsBytes() as Uint8List;
          cache[path.path] = ByteData.view(bytes.buffer);
        }
      }
    }
    final manifest = <String, List<String>>{};
    cache.forEach((key, _) {
      manifest[key] = [key];
    });

    cache[_assetManifestDotJson] = ByteData.view(
      Uint8List.fromList(jsonEncode(manifest).codeUnits).buffer,
    );

    return DiskAssetBundle._(cache);
  }

  final Map<String, ByteData> _cache;

  @override
  Future<ByteData> load(String key) async {
    return _cache[key];
  }
}
