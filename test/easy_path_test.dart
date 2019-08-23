import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/voyager.dart';

import 'mock_classes.dart';

void main() {
  test('easy path home', () async {
    final paths = loadPathsFromString('''
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
    final plugins = [
      WidgetPlugin({
        "HomeWidget": (context) => MockHomeWidget(),
        "OtherWidget": (context) => MockOtherWidget(),
      })
    ];

    final router = await loadRouter(paths, plugins);

    final homes = <Voyager>[];
    homes.add(router.find("/home"));
    homes.add(router.find("home"));
    homes.add(router.find("home/"));
    homes.add(router.find("/home/"));

    expect(homes.length, 4);
    homes.forEach((home) {
      expect(home.type, "home");
      expect(home[WidgetPlugin.KEY](null), isInstanceOf<MockHomeWidget>());
    });

    final roots = <Voyager>[];
    roots.add(router.find("/"));
    roots.add(router.find(""));
    roots.add(router.find("//"));
    expect(roots.length, 3);
    roots.forEach((root) {
      expect(root.type, "root");
      expect(root[WidgetPlugin.KEY](null), isInstanceOf<MockOtherWidget>());
    });
  });
}
