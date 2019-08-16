import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/src/abstract_router.dart';
import 'package:voyager/voyager.dart';

import 'mock_classes.dart';

void main() {
  test('test redirect plugin', () async {
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
  complexObject:
    property1: true
    property2: 42
    property3: "%{foo} %{bar}"
'/different/one' :
  redirect: '/other/one?foo=hello'
'/different/fail' :
  redirect: '/non/existing/path'
''');
    final plugins = [
      WidgetPlugin({
        "HomeWidget": (context) => MockHomeWidget(),
        "OtherWidget": (context) => MockOtherWidget(),
      }),
      RedirectPlugin()
    ];

    final router = await loadRouter(paths, plugins);

    final differentVoyager = router.find("/different/one?bar=world");

    expect(differentVoyager[WidgetPlugin.KEY](null),
        isInstanceOf<MockOtherWidget>());

    expect(differentVoyager["type"], "other");
    expect(differentVoyager.type, "other");
    expect(differentVoyager["title"], "This is one");
    expect(differentVoyager["complexObject"],
        {"property1": true, "property2": 42, "property3": "hello world"});

    expect(() => router.find("/different/fail"), throwsA(predicate((e) {
      expect(e, isInstanceOf<RouteNotFoundException>());
      expect((e as RouteNotFoundException).cause,
          "No route found for url /non/existing/path");
      return true;
    })));
  });

  test('test widget plugin', () async {
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
'/other2/:title' :
  type: 'other'
  widget: OtherWidget2
  title: "This is %{title}"
''');
    final plugins = [
      WidgetPlugin({
        "HomeWidget": (context) => MockHomeWidget(),
        "OtherWidget": (context) => MockOtherWidget(),
      }),
      RedirectPlugin()
    ];

    final router = await loadRouter(paths, plugins);

    final otherVoyager = router.find("/other/thing");

    expect(
        otherVoyager[WidgetPlugin.KEY](null), isInstanceOf<MockOtherWidget>());

    expect(() => router.find("/other2/thing"), throwsA(predicate((e) {
      expect(e, isInstanceOf<FlutterError>());
      expect(
          (e as FlutterError).message, "No builder for OtherWidget2 defined.");
      return true;
    })));
  });

  test('test widget plugin builder', () async {
    final paths = loadPathsFromString('''
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
    final plugins = [
      WidgetPluginBuilder()
          .add<MockHomeWidget>((context) => MockHomeWidget())
          .add<MockOtherWidget>((context) => MockOtherWidget())
          .build(),
      RedirectPlugin()
    ];

    final router = await loadRouter(paths, plugins);

    final homeVoyager = router.find("/home");

    expect(homeVoyager[WidgetPlugin.KEY](null), isInstanceOf<MockHomeWidget>());

    final otherVoyager = router.find("/other/thing");

    expect(
        otherVoyager[WidgetPlugin.KEY](null), isInstanceOf<MockOtherWidget>());

    expect(() => router.find("/other2/thing"), throwsA(predicate((e) {
      expect(e, isInstanceOf<FlutterError>());
      expect(
          (e as FlutterError).message, "No builder for OtherWidget2 defined.");
      return true;
    })));
  });

  test('test widget plugin builder + aliases', () async {
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
'/other2/:title' :
  type: 'other'
  widget: OtherWidget2
  title: "This is %{title}"
''');
    final plugins = [
      WidgetPluginBuilder().add<MockHomeWidget>((context) => MockHomeWidget(),
          aliases: [
            "HomeWidget"
          ]).add<MockOtherWidget>((context) => MockOtherWidget(),
          aliases: ["OtherWidget", "OtherWidget2"]).build(),
      RedirectPlugin()
    ];

    final router = await loadRouter(paths, plugins);

    final homeVoyager = router.find("/home");

    expect(homeVoyager[WidgetPlugin.KEY](null), isInstanceOf<MockHomeWidget>());

    final otherVoyager = router.find("/other/thing");

    expect(
        otherVoyager[WidgetPlugin.KEY](null), isInstanceOf<MockOtherWidget>());

    final other2Voyager = router.find("/other2/thing");

    expect(
        other2Voyager[WidgetPlugin.KEY](null), isInstanceOf<MockOtherWidget>());
  });

  test('test widget plugin null builder', () async {
    expect(() {
      WidgetPluginBuilder().add<MockHomeWidget>(null, aliases: [
        "HomeWidget"
      ]).add<MockOtherWidget>((context) => MockOtherWidget(),
          aliases: ["OtherWidget", "OtherWidget2"]).build();
    }, throwsA(predicate((e) {
      expect(e, isInstanceOf<AssertionError>());
      expect((e as AssertionError).message, "Builder must be provided");
      return true;
    })));
  });

  test('widget plugin duplicate alias', () async {
    expect(() {
      WidgetPluginBuilder().add<MockHomeWidget>((context) => MockHomeWidget(),
          aliases: [
            "HomeWidget"
          ]).add<MockOtherWidget>((context) => MockOtherWidget(),
          aliases: ["HomeWidget", "OtherWidget2"]).build();
    }, throwsA(predicate((e) {
      expect(e, isInstanceOf<AssertionError>());
      expect((e as AssertionError).message,
          "Alias HomeWidget for MockOtherWidget is already used.");
      return true;
    })));
  });

  test('widget plugin unspefied class type', () async {
    expect(() {
      WidgetPluginBuilder()
          .add<MockHomeWidget>((context) => MockHomeWidget())
          .add<MockOtherWidget>((context) => MockOtherWidget())
          .add(mockFab)
          .build();
    }, throwsA(predicate((e) {
      expect(e, isInstanceOf<ArgumentError>());
      expect((e as ArgumentError).message,
          "Use addMethod if you can't provide Widget class as T parameter");
      return true;
    })));
  });

  test('test widget plugin builder and custom function', () async {
    final paths = loadPathsFromString('''
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
    final plugins = [
      WidgetPluginBuilder()
          .add<MockHomeWidget>((context) => MockHomeWidget())
          .add<MockOtherWidget>((context) => MockOtherWidget())
          .addMethod(mockFab, "FabWidget")
          .build(),
      RedirectPlugin()
    ];

    final router = await loadRouter(paths, plugins);

    final homeVoyager = router.find("/home");

    expect(homeVoyager[WidgetPlugin.KEY](null), isInstanceOf<MockHomeWidget>());

    final otherVoyager = router.find("/other/thing");

    expect(
        otherVoyager[WidgetPlugin.KEY](null), isInstanceOf<MockOtherWidget>());

    final fabVoyager = router.find("/fab");

    expect(fabVoyager[WidgetPlugin.KEY](null),
        isInstanceOf<FloatingActionButton>());
  });
}
