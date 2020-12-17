import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/voyager.dart';

import 'mock_classes.dart';

void main() {
  test('easy path home', () async {
    final paths = loadPathsFromYamlString('''
---
'/home' :
  type: 'home'
  widget: HomeWidget
  title: "This is Home"
  fab: /other/thing
'/other/:title' :
  type: 'other'
  widget: OtherWidget
  title: "This is %{title}"
'/' :
  type: 'root'
  widget: OtherWidget
  title: "This is a top %{title}"
''');
    final widgetMappings = {
      "HomeWidget": (BuildContext context) => MockHomeWidget(),
      "OtherWidget": (BuildContext context) => MockOtherWidget(),
    };
    final plugins = [WidgetPlugin(widgetMappings)];

    final router = await loadRouter(paths, plugins);

    final homes = <Voyager>[];
    homes.add(router.find("/home")!);
    homes.add(router.find("home")!);
    homes.add(router.find("home/")!);
    homes.add(router.find("/home/")!);

    expect(homes.length, 4);
    homes.forEach((home) {
      expect(home.type, "home");
      expect(home[WidgetPlugin.KEY], widgetMappings["HomeWidget"]);
    });

    final roots = <Voyager>[];
    roots.add(router.find("/")!);
    roots.add(router.find("")!);
    roots.add(router.find("//")!);
    expect(roots.length, 3);
    roots.forEach((root) {
      expect(root.type, "root");
      expect(root[WidgetPlugin.KEY], widgetMappings["OtherWidget"]);
    });
  });
}
