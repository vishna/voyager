import 'package:flutter/material.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/src/abstract_router.dart';
import 'package:voyager/voyager.dart';

import 'mock_classes.dart';

// ignore_for_file: avoid_as

void main() {
  test('test redirect plugin', () async {
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
  complexObject:
    property1: true
    property2: 42
    property3: "%{foo} %{bar}"
'/different/one' :
  redirect: '/other/one?foo=hello'
'/different/fail' :
  redirect: '/non/existing/path'
''');
    final widgetMappings = {
      "HomeWidget": (BuildContext context) => MockHomeWidget(),
      "OtherWidget": (BuildContext context) => MockOtherWidget(),
    };
    final plugins = [
      WidgetPlugin(widgetMappings),
      const RedirectPlugin(),
    ];

    final router = await loadRouter(paths, plugins);

    final differentVoyager = router.find("/different/one?bar=world")!;

    expect(differentVoyager[WidgetPlugin.KEY], widgetMappings["OtherWidget"]);

    expect(differentVoyager["type"], "other");
    expect(differentVoyager.type, "other");
    expect(differentVoyager["title"], "This is one");
    expect(differentVoyager["complexObject"],
        {"property1": true, "property2": 42, "property3": "hello world"});

    expect(() => router.find("/different/fail"),
        throwsA(predicate((RouteNotFoundException e) {
      expect(e.cause, "No route found for url /non/existing/path");
      return true;
    })));
  });

  test('test widget plugin', () async {
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
'/other2/:title' :
  type: 'other'
  widget: OtherWidget2
  title: "This is %{title}"
''');
    final widgetMappings = {
      "HomeWidget": (BuildContext context) => MockHomeWidget(),
      "OtherWidget": (BuildContext context) => MockOtherWidget(),
    };
    final plugins = [
      WidgetPlugin(widgetMappings),
      const RedirectPlugin(),
    ];

    final router = await loadRouter(paths, plugins);

    final otherVoyager = router.find("/other/thing")!;

    expect(otherVoyager[WidgetPlugin.KEY], widgetMappings["OtherWidget"]);

    expect(() => router.find("/other2/thing"), throwsA(predicate((Error e) {
      expect(e, isInstanceOf<FlutterError>());
      expect(
          (e as FlutterError).message, "No builder for OtherWidget2 defined.");
      return true;
    })));
  });

  test('test widget plugin builder', () async {
    final paths = loadPathsFromYamlString('''
---
'/home' :
  type: 'home'
  widget: MockHomeWidget
  title: "This is Home"
  fab: /other/thing
'/other/:title' :
  type: 'other'
  widget: MockOtherWidget
  title: "This is %{title}"
'/other2/:title' :
  type: 'other'
  widget: OtherWidget2
  title: "This is %{title}"
''');
    final homeBuilder = (BuildContext context) => MockHomeWidget();
    final otherBuilder = (BuildContext context) => MockOtherWidget();
    final plugins = [
      WidgetPluginBuilder()
          .add("MockHomeWidget", homeBuilder)
          .add("MockOtherWidget", otherBuilder)
          .build(),
      const RedirectPlugin()
    ];

    final router = await loadRouter(paths, plugins);

    final homeVoyager = router.find("/home")!;

    expect(homeVoyager[WidgetPlugin.KEY], homeBuilder);

    final otherVoyager = router.find("/other/thing")!;

    expect(otherVoyager[WidgetPlugin.KEY], otherBuilder);

    expect(() => router.find("/other2/thing"), throwsA(predicate((Error e) {
      expect(e, isInstanceOf<FlutterError>());
      expect(
          (e as FlutterError).message, "No builder for OtherWidget2 defined.");
      return true;
    })));
  });

  test('test widget plugin builder + aliases', () async {
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
'/other2/:title' :
  type: 'other'
  widget: OtherWidget2
  title: "This is %{title}"
''');
    final homeBuilder = (BuildContext context) => MockHomeWidget();
    final otherBuilder = (BuildContext context) => MockOtherWidget();
    final plugins = [
      WidgetPluginBuilder().add(
        "MockHomeWidget",
        homeBuilder,
        aliases: ["HomeWidget"],
      ).add(
        "MockOtherWidget",
        otherBuilder,
        aliases: ["OtherWidget", "OtherWidget2"],
      ).build(),
      const RedirectPlugin()
    ];

    final router = await loadRouter(paths, plugins);

    final homeVoyager = router.find("/home")!;

    expect(homeVoyager[WidgetPlugin.KEY], homeBuilder);

    final otherVoyager = router.find("/other/thing")!;

    expect(otherVoyager[WidgetPlugin.KEY], otherBuilder);

    final other2Voyager = router.find("/other2/thing")!;

    expect(other2Voyager[WidgetPlugin.KEY], otherBuilder);
  });

  test('widget plugin duplicate alias', () async {
    expect(() {
      WidgetPluginBuilder().add("MockHomeWidget", (context) => MockHomeWidget(),
          aliases: [
            "HomeWidget"
          ]).add("MockOtherWidget", (context) => MockOtherWidget(),
          aliases: ["HomeWidget", "OtherWidget2"]).build();
    }, throwsA(predicate((Error e) {
      expect(e, isInstanceOf<AssertionError>());
      expect((e as AssertionError).message,
          "Alias HomeWidget for MockOtherWidget is already used.");
      return true;
    })));
  });

  test('test widget plugin builder and custom function', () async {
    final paths = loadPathsFromYamlString('''
---
'/home' :
  type: 'home'
  widget: MockHomeWidget
  title: "This is Home"
  fab: /other/thing
'/other/:title' :
  type: 'other'
  widget: MockOtherWidget
  title: "This is %{title}"
'/fab' :
  type: 'fab'
  widget: FabWidget
''');
    final homeBuilder = (BuildContext context) => MockHomeWidget();
    final otherBuilder = (BuildContext context) => MockOtherWidget();
    final plugins = [
      WidgetPluginBuilder()
          .add("MockHomeWidget", homeBuilder)
          .add("MockOtherWidget", otherBuilder)
          .add("FabWidget", mockFab)
          .build(),
      const RedirectPlugin()
    ];

    final router = await loadRouter(paths, plugins);

    final homeVoyager = router.find("/home")!;

    expect(homeVoyager[WidgetPlugin.KEY], homeBuilder);

    final otherVoyager = router.find("/other/thing")!;

    expect(otherVoyager[WidgetPlugin.KEY], otherBuilder);

    final fabVoyager = router.find("/fab")!;

    expect(fabVoyager[WidgetPlugin.KEY], mockFab);
  });

  test('test adding widget plugin builders', () async {
    final paths = loadPathsFromYamlString('''
---
'/home' :
  type: 'home'
  widget: MockHomeWidget
  title: "This is Home"
  fab: /other/thing
'/other/:title' :
  type: 'other'
  widget: MockOtherWidget
  title: "This is %{title}"
'/fab' :
  type: 'fab'
  widget: FabWidget
''');
    final builderAClosure = (BuildContext context) => MockHomeWidget();
    final builderA =
        WidgetPluginBuilder().add("MockHomeWidget", builderAClosure);
    final builderBClosure = (BuildContext context) => MockOtherWidget();
    final builderB =
        WidgetPluginBuilder().add("MockOtherWidget", builderBClosure);
    final plugins = [
      WidgetPluginBuilder()
          .addBuilder(builderA)
          .addBuilder(builderB)
          .add("FabWidget", mockFab)
          .build(),
      const RedirectPlugin()
    ];

    final router = await loadRouter(paths, plugins);

    final homeVoyager = router.find("/home")!;

    expect(homeVoyager[WidgetPlugin.KEY], builderAClosure);

    final otherVoyager = router.find("/other/thing")!;

    expect(otherVoyager[WidgetPlugin.KEY], builderBClosure);

    final fabVoyager = router.find("/fab")!;

    expect(fabVoyager[WidgetPlugin.KEY], mockFab);
  });

  test("mock object plugin", () {
    final voyager = Voyager(config: <String, dynamic>{}, path: "/mock/path");
    final mockPlugin = _MockPlugin();
    final mockContext =
        VoyagerContext(path: "/mock/path", params: {}, router: VoyagerRouter());
    mockPlugin.outputFor(mockContext, null, voyager);
    voyager.lock();
    expect(voyager["mock"], isInstanceOf<_MockObject>());
    final mock = voyager["mock"] as _MockObject;
    expect(mock.disposed, false);
    voyager.dispose();
    expect(mock.disposed, true);
  });
}

class _MockObject {
  bool disposed = false;
}

class _MockPlugin extends VoyagerObjectPlugin<_MockObject> {
  _MockPlugin() : super("mock");

  @override
  void onDispose(_MockObject t) {
    super.onDispose(t);
    t.disposed = true;
  }

  @override
  _MockObject buildObject(VoyagerContext context, dynamic config) {
    return _MockObject();
  }
}
