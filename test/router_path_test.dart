import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/voyager.dart';
import 'package:yaml/yaml.dart';

void main() {
  test("load router path from normal map", () async {
    final routerPath = RouterPath.fromMap(path: "/home", config: {
      "type": "home",
      "widget": "HomeWidget",
      "title": "Home Title"
    });

    expect(routerPath.path, "/home");
    expect(routerPath.config["type"], "home");
    expect(routerPath.config["widget"], "HomeWidget");
    expect(routerPath.config["title"], "Home Title");
  });

  test("load router path from normal yaml map", () async {
    final configYaml = """
---
type: home
widget: HomeWidget
title: Home Title
""";

   final configMap = loadYaml(configYaml) as YamlMap;

    final routerPath = RouterPath.fromYaml(path: "/home", config: configMap);

    expect(routerPath.path, "/home");
    expect(routerPath.config["type"], "home");
    expect(routerPath.config["widget"], "HomeWidget");
    expect(routerPath.config["title"], "Home Title");
  });
}
