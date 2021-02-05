import 'dart:convert';
import 'package:voyager/voyager.dart';
import 'package:yaml/yaml.dart';

/// a build piece of [VoyagerRouter]
class VoyagerPath {
  const VoyagerPath._({required this.path, required this.config});

  /// factory method for creating a single Voyager path instance from [YamlMap]
  factory VoyagerPath.fromYaml(
      {required String path, required YamlMap config}) {
    return VoyagerPath.fromMap(
        path: path, config: json.decode(json.encode(config)));
  }

  /// factory method for creating a single Voyager path instance from [Map]
  factory VoyagerPath.fromMap(
      {required String path, required Map<String, dynamic> config}) {
    if (config["type"] == null && config["redirect"] == null) {
      config["type"] = VoyagerUtils.typify(path);
    }
    return VoyagerPath._(path: path, config: config);
  }

  /// path
  final String path;

  /// path's config
  final Map<String, dynamic> config;
}
