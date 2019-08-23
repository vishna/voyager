import 'dart:convert';
import 'package:yaml/yaml.dart';

class RouterPath {
  const RouterPath._({this.path, this.config});
  factory RouterPath.fromYaml({String path, YamlMap config}) {
    return RouterPath._(path: path, config: json.decode(json.encode(config)));
  }

  factory RouterPath.fromMap({String path, Map<String, dynamic> config}) {
    return RouterPath._(path: path, config: config);
  }
  final String path;
  final Map<String, dynamic> config;
}
