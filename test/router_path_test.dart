import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/voyager.dart';
import 'package:yaml/yaml.dart';

void main() {
  test("load router path from normal map", () async {
    final routerPath = VoyagerPath.fromMap(
        path: "/home",
        config: <String, String>{
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
    const configYaml = """
---
type: home
widget: HomeWidget
title: Home Title
""";

    final YamlMap configMap = loadYaml(configYaml);

    final routerPath = VoyagerPath.fromYaml(path: "/home", config: configMap);

    expect(routerPath.path, "/home");
    expect(routerPath.config["type"], "home");
    expect(routerPath.config["widget"], "HomeWidget");
    expect(routerPath.config["title"], "Home Title");
  });

  test("load router path from normal yaml map (no types)", () async {
    const configYaml = """
---
widget: HomeWidget
title: Home Title
""";

    final YamlMap configMap = loadYaml(configYaml);

    final routerPath = VoyagerPath.fromYaml(path: "/home", config: configMap);

    expect(routerPath.path, "/home");
    expect(routerPath.config["type"], "home");
    expect(routerPath.config["widget"], "HomeWidget");
    expect(routerPath.config["title"], "Home Title");
  });
}
