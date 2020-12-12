import 'dart:convert';
import 'package:yaml/yaml.dart';

class RouterPath {
  const RouterPath._({required this.path, required this.config});
  factory RouterPath.fromYaml({required String path, required YamlMap config}) {
    return RouterPath._(path: path, config: json.decode(json.encode(config)));
  }

  factory RouterPath.fromMap(
      {required String path, required Map<String, dynamic> config}) {
    return RouterPath._(path: path, config: config);
  }
  final String path;
  final Map<String, dynamic> config;
}
