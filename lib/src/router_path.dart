import 'dart:convert';
import 'package:yaml/yaml.dart';

class RouterPath {
  String path;
  Map<String, dynamic> config;

  RouterPath._({this.path, this.config});

  factory RouterPath.fromYaml({String path, YamlMap config}) {
    return RouterPath._(
        path: path,
        config: json.decode(json.encode(config)) as Map<String, dynamic>
    );
  }
}