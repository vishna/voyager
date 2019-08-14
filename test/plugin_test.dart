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
}
