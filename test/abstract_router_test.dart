import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/src/voyager_router.dart';
import 'package:voyager/voyager.dart';

import 'mock_classes.dart';

// ignore_for_file: avoid_as

void main() {
  test('test wildcard parameter', () async {
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
  title: "This is a %{title}"
'/other/:whatever:' :
  type: 'other_whatever'
  widget: OtherWidget
  title: "Now the wild %{whatever}"
''');
    final widgetMappings = {
      "HomeWidget": (BuildContext context) => MockHomeWidget(),
      "OtherWidget": (BuildContext context) => MockOtherWidget(),
    };
    final plugins = [WidgetPlugin(widgetMappings), const RedirectPlugin()];

    final router = await loadRouter(paths, plugins);

    final otherVoyager = router.find("/other/thing")!;

    expect(otherVoyager[WidgetPlugin.KEY], widgetMappings["OtherWidget"]);
    expect(otherVoyager["title"], "This is a thing");

    final wildVoyager = router.find("/other/thing/is/here")!;
    expect(wildVoyager["title"], "Now the wild thing/is/here");
  });

  test('forbidden wildcard parameter', () async {
    final paths = loadPathsFromYamlString('''
---
'/other/:whatever:/:id' :
  type: 'whatever_faulty'
  widget: OtherWidget
  title: "Now the wild %{whatever} with an %{id} which obviously is not possible"
''');
    final plugins = [
      WidgetPlugin({
        "HomeWidget": (context) => MockHomeWidget(),
        "OtherWidget": (context) => MockOtherWidget(),
      }),
      const RedirectPlugin()
    ];

    final router = await loadRouter(paths, plugins);

    expect(() => router.find("/other/quite/ridiculous/thing"),
        throwsA(predicate((Error e) {
      expect(e, isInstanceOf<StateError>());
      expect((e as StateError).message,
          "Wildcard parameter :whatever: cannot be directly followed by a parameter :id");
      return true;
    })));
  });

  test('multi param or wildcard', () async {
    final paths = loadPathsFromYamlString('''
---
'/position/:lat/:lon' :
  type: 'other'
  widget: OtherWidget
  title: "The beer is %{lat} and %{lon}"
'/location/:city/:whatever:' :
  type: 'other'
  widget: OtherWidget
  title: "Beer is located in %{city}"
''');
    final plugins = [
      WidgetPlugin({
        "OtherWidget": (context) => MockOtherWidget(),
      })
    ];

    final router = await loadRouter(paths, plugins);

    final beerPosition = router.find("/position/52.4915536/13.4265027")!;
    expect(beerPosition["title"], "The beer is 52.4915536 and 13.4265027");

    final beerInCityPosition =
        router.find("/location/Berlin/52.4915536/13.4265027")!;
    expect(beerInCityPosition.path, "/location/Berlin/52.4915536/13.4265027");
    expect(beerInCityPosition["title"], "Beer is located in Berlin");
  });

  test('get same location twice, clear cache', () async {
    final paths = loadPathsFromYamlString('''
---
'/position/:lat/:lon' :
  type: 'other'
  widget: OtherWidget
  title: "The beer is %{lat} and %{lon}"
''');
    final plugins = [
      WidgetPlugin({
        "OtherWidget": (context) => MockOtherWidget(),
      })
    ];

    final router = await loadRouter(paths, plugins);

    final beerPosition = router.find("/position/52.4915536/13.4265027")!;
    expect(beerPosition["title"], "The beer is 52.4915536 and 13.4265027");

    final anotherBeerPosition = router.find("/position/52.4915536/13.4265027")!;
    expect(
        anotherBeerPosition["title"], "The beer is 52.4915536 and 13.4265027");

    router.clearCache();
  });

  test('global param', () async {
    final paths = loadPathsFromYamlString('''
---
'/position/:lat/:lon' :
  type: 'other'
  widget: OtherWidget
  title: "The beer is %{lat} and %{lon} in %{city}"
''');
    final plugins = [
      WidgetPlugin({
        "OtherWidget": (context) => MockOtherWidget(),
      })
    ];

    final router = await loadRouter(paths, plugins);
    router.globalParam("city", "Berlin");

    final beerPosition = router.find("/position/52.4915536/13.4265027")!;
    expect(beerPosition["title"],
        "The beer is 52.4915536 and 13.4265027 in Berlin");
  });
}
