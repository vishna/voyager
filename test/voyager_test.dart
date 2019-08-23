import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/voyager.dart';

import 'mock_classes.dart';
import 'navigation_json.dart';
import 'navigation_yml.dart';

// ignore_for_file: avoid_as

void main() {
  test('loadRouter from a yaml defined in a string', () async {
    final paths = loadPathsFromString(navigation_yml);
    final plugins = [
      WidgetPlugin({
        "HomeWidget": (context) => MockHomeWidget(),
        "OtherWidget": (context) => MockOtherWidget(),
      })
    ];

    final router = await loadRouter(paths, plugins);

    final homeVoyager = router.find("/home");

    expect(homeVoyager[WidgetPlugin.KEY](null), isInstanceOf<MockHomeWidget>());
    expect(homeVoyager.type, "home");
  });

  test('loadRouter from a json defined in a string', () async {
    final paths = loadPathsFromJsonString(navigation_json);
    final plugins = [
      WidgetPlugin({
        "HomeWidget": (context) => MockHomeWidget(),
        "OtherWidget": (context) => MockOtherWidget(),
      })
    ];

    final router = await loadRouter(paths, plugins);

    final homeVoyager = router.find("/home");

    expect(homeVoyager[WidgetPlugin.KEY](null), isInstanceOf<MockHomeWidget>());
    expect(homeVoyager.type, "home");
  });

  test('create router programatically', () async {
    final router = RouterNG();
    router.registerConfig('/home', (context, Voyager voyager) {
      voyager.type = "home";
      voyager[WidgetPlugin.KEY] =
          (BuildContext buildContext) => MockHomeWidget();
      voyager["title"] = "This is Home";
    });
    router.registerConfig('/other/:title', (context, Voyager voyager) {
      final title = context.params["title"];
      voyager.type = "other";
      voyager[WidgetPlugin.KEY] =
          (BuildContext buildContext) => MockOtherWidget();
      voyager["title"] = "This is a $title";
    });

    final homeVoyager = router.find("/home");

    expect(homeVoyager[WidgetPlugin.KEY](null), isInstanceOf<MockHomeWidget>());
    expect(homeVoyager.type, "home");
    expect(homeVoyager["title"], "This is Home");

    final otherVoyager = router.find("/other/thing");

    expect(
        otherVoyager[WidgetPlugin.KEY](null), isInstanceOf<MockOtherWidget>());
    expect(otherVoyager.type, "other");
    expect(otherVoyager["title"], "This is a thing");
  });

  test('create router programatically with custom voyager factory', () async {
    final VoyagerFactory<CustomVoyager> customVoyagerFactory =
        (abstractContext, context) => CustomVoyager(
            abstractContext.url(), abstractContext.getExtras().parent);

    final router = RouterNG();
    router.registerConfig<CustomVoyager>('/home', (context, voyager) {
      voyager.type = "home";
      voyager.widget = (BuildContext buildContext) => MockHomeWidget();
      voyager.title = "This is Home";
    }, customVoyagerFactory);
    router.registerConfig<CustomVoyager>('/other/:title', (context, voyager) {
      final title = context.params["title"];
      voyager.type = "other";
      voyager.widget = (BuildContext buildContext) => MockOtherWidget();
      voyager.title = "This is a $title";
    }, customVoyagerFactory);

    final CustomVoyager homeVoyager = router.find("/home");

    expect(homeVoyager[WidgetPlugin.KEY](null), isInstanceOf<MockHomeWidget>());
    expect(homeVoyager.type, "home");
    expect(homeVoyager.title, "This is Home");

    final CustomVoyager otherVoyager = router.find("/other/thing");

    expect(
        otherVoyager[WidgetPlugin.KEY](null), isInstanceOf<MockOtherWidget>());
    expect(otherVoyager.type, "other");
    expect(otherVoyager.title, "This is a thing");
  });

  testWidgets('create HomeWidget via VoyagerWidget',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      final paths = loadPathsFromString(navigation_yml);
      final plugins = [
        WidgetPlugin({
          "HomeWidget": (context) => MockHomeWidget(),
          "OtherWidget": (context) => MockOtherWidget(),
        })
      ];

      final router = await loadRouter(paths, plugins);

      expect(router, isInstanceOf<RouterNG>());

      await tester.pumpWidget(
          MaterialApp(home: VoyagerWidget(path: "/home", router: router)));

      expect(find.text("Home Page"), findsOneWidget);
      expect(find.text("Home Title"), findsOneWidget);
    });
  });

  testWidgets(
      'create OtherWidget via VoyagerWidget & inject title through path parameter',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      final paths = loadPathsFromString(navigation_yml);
      final plugins = [
        WidgetPlugin({
          "HomeWidget": (context) => MockHomeWidget(),
          "OtherWidget": (context) => MockOtherWidget(),
        })
      ];

      final router = await loadRouter(paths, plugins);

      expect(router, isInstanceOf<RouterNG>());

      await tester.pumpWidget(MaterialApp(
          home: VoyagerWidget(path: "/other/foobar123", router: router)));

      expect(find.text("Other Page"), findsOneWidget);
      expect(find.text("This is foobar123"), findsOneWidget);
    });
  });

  test("merging one voyager into another", () {
    final one = Voyager(config: <String, dynamic>{});
    one["mission"] = "Mission 1";
    one["brief"] = "A short brief from 1";
    final two = Voyager(config: <String, dynamic>{});
    two["mission"] = "Mission 2";
    two["team"] = ["Jon", "Jessie"];

    two.merge(one);

    expect(two["mission"], "Mission 1");
    expect(two["brief"], "A short brief from 1");
    expect(two["team"], ["Jon", "Jessie"]);
  });

  test("merging one voyager into another with a lock", () {
    final one = Voyager(config: <String, dynamic>{});
    one["mission"] = "Mission 1";
    one["brief"] = "A short brief from 1";
    final two = Voyager(config: <String, dynamic>{});
    two["mission"] = "Mission 2";
    two["team"] = ["Jon", "Jessie"];
    two.lock();

    expect(() => two.merge(one), throwsA(predicate((Error e) {
      expect(e, isInstanceOf<FlutterError>());
      expect((e as FlutterError).message, "Voyager is in lockdown.");
      return true;
    })));
  });

  test("adding items to a locked voyager", () {
    final one = Voyager(config: <String, dynamic>{});
    one["mission"] = "Mission 1";
    one["brief"] = "A short brief from 1";
    one["team"] = ["Jon", "Jessie"];
    one.lock();
    expect(() {
      /// sorry John
      one["team"] = ["Jon", "Jessie", "John"];
    }, throwsA(predicate((Error e) {
      expect(e, isInstanceOf<FlutterError>());
      expect((e as FlutterError).message, "Voyager is in lockdown.");
      return true;
    })));

    expect(one["mission"], "Mission 1");
    expect(one["brief"], "A short brief from 1");
    expect(one["team"], ["Jon", "Jessie"]);
  });

  test("disposing unlocked voyager", () {
    final one = Voyager(config: <String, dynamic>{});
    one["mission"] = "Mission 1";
    one["brief"] = "A short brief from 1";
    expect(() {
      one.dispose();
    }, throwsA(predicate((Error e) {
      expect(e, isInstanceOf<FlutterError>());
      expect((e as FlutterError).message,
          "Can't dispose resources before Voyager is locked");
      return true;
    })));
  });

  test("disposing properly locked voyager", () {
    final one = Voyager(config: <String, dynamic>{});
    var _onDisposeCalled = false;
    one["mission"] = "Mission 1";
    one["brief"] = "A short brief from 1";
    one.onDispose(() {
      _onDisposeCalled = true;
    });
    expect(_onDisposeCalled, false);
    expect(one["mission"], "Mission 1");
    expect(one["brief"], "A short brief from 1");
    one.lock();
    one.dispose();
    expect(_onDisposeCalled, true);
    expect(one["mission"], null);
    expect(one["brief"], null);
  });

  test("adding dispose callback to locked voyager should throw", () {
    final one = Voyager(config: <String, dynamic>{});
    var _onDisposeCalled = false;
    one["mission"] = "Mission 1";
    one["brief"] = "A short brief from 1";
    one.lock();

    expect(() {
      one.onDispose(() {
        _onDisposeCalled = true;
      });
    }, throwsA(predicate((Error e) {
      expect(e, isInstanceOf<FlutterError>());
      expect((e as FlutterError).message, "Voyager is in lockdown.");
      return true;
    })));

    expect(_onDisposeCalled, false);
    expect(one["mission"], "Mission 1");
    expect(one["brief"], "A short brief from 1");

    one.dispose();
    expect(_onDisposeCalled, false);

    /// since callback wasn't added
    expect(one["mission"], null);
    expect(one["brief"], null);
  });
}
