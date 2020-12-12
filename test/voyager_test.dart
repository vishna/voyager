import 'package:flutter/material.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/voyager.dart' hide Router;
import 'package:voyager/voyager.dart' as voyager;

import 'mock_classes.dart';
import 'navigation_json.dart';
import 'navigation_yml.dart';

// ignore_for_file: avoid_as

void main() {
  test('loadRouter from a yaml defined in a string', () async {
    final widgetMappings = {
      "HomeWidget": (BuildContext context) => MockHomeWidget(),
      "OtherWidget": (BuildContext context) => MockOtherWidget(),
    };
    final paths = loadPathsFromString(navigation_yml);
    final plugins = [WidgetPlugin(widgetMappings)];

    final router = await loadRouter(paths, plugins);

    final homeVoyager = router.find("/home")!;

    expect(homeVoyager[WidgetPlugin.KEY], widgetMappings["HomeWidget"]);
    expect(homeVoyager.type, "home");
  });

  test('loadRouter from a yaml defined in a string + mock factory', () async {
    final widgetMappings = {
      "HomeWidget": (BuildContext context) => MockHomeWidget(),
      "OtherWidget": (BuildContext context) => MockOtherWidget(),
    };
    final paths = loadPathsFromString(navigation_yml);
    final plugins = [WidgetPlugin(widgetMappings)];

    final router =
        await loadRouter(paths, plugins, voyagerFactory: _mockFactory);

    final homeVoyager = router.find("/home")!;

    expect(homeVoyager[WidgetPlugin.KEY], widgetMappings["HomeWidget"]);
    expect(homeVoyager.type, "home");
  });

  test('loadRouter from a json defined in a string', () async {
    final paths = loadPathsFromJsonString(navigation_json);
    final widgetMappings = {
      "HomeWidget": (BuildContext context) => MockHomeWidget(),
      "OtherWidget": (BuildContext context) => MockOtherWidget(),
    };
    final plugins = [WidgetPlugin(widgetMappings)];

    final router = await loadRouter(paths, plugins);

    final homeVoyager = router.find("/home")!;

    expect(homeVoyager[WidgetPlugin.KEY], widgetMappings["HomeWidget"]);
    expect(homeVoyager.type, "home");
  });

  test('create router programatically', () async {
    final homeClosure = (BuildContext buildContext) => MockHomeWidget();
    final otherClosure = (BuildContext buildContext) => MockOtherWidget();
    final router = voyager.Router();
    router.registerConfig('/home', (context, Voyager voyager) {
      voyager.type = "home";
      voyager[WidgetPlugin.KEY] = homeClosure;
      voyager["title"] = "This is Home";
    });
    router.registerConfig('/other/:title', (context, Voyager voyager) {
      final title = context.params["title"];
      voyager.type = "other";
      voyager[WidgetPlugin.KEY] = otherClosure;
      voyager["title"] = "This is a $title";
    });

    final homeVoyager = router.find("/home")!;

    expect(homeVoyager[WidgetPlugin.KEY], homeClosure);
    expect(homeVoyager.type, "home");
    expect(homeVoyager["title"], "This is Home");

    final otherVoyager = router.find("/other/thing")!;

    expect(otherVoyager[WidgetPlugin.KEY], otherClosure);
    expect(otherVoyager.type, "other");
    expect(otherVoyager["title"], "This is a thing");
  });

  test('create router programatically with custom voyager factory', () async {
    final homeClosure = (BuildContext buildContext) => MockHomeWidget();
    final otherClosure = (BuildContext buildContext) => MockOtherWidget();
    // ignore: omit_local_variable_types
    final ProgrammaticVoyagerFactory<CustomVoyager> customVoyagerFactory =
        (abstractContext, context) => CustomVoyager(
            abstractContext.url(), abstractContext.getExtras().parent);

    final router = voyager.Router();
    router.registerConfig<CustomVoyager>('/home', (context, voyager) {
      voyager.type = "home";
      voyager.widget = homeClosure;
      voyager.title = "This is Home";
    }, customVoyagerFactory);
    router.registerConfig<CustomVoyager>('/other/:title', (context, voyager) {
      final title = context.params["title"];
      voyager.type = "other";
      voyager.widget = otherClosure;
      voyager.title = "This is a $title";
    }, customVoyagerFactory);

    final homeVoyager = router.find("/home") as CustomVoyager;

    expect(homeVoyager[WidgetPlugin.KEY], homeClosure);
    expect(homeVoyager.type, "home");
    expect(homeVoyager.title, "This is Home");

    final otherVoyager = router.find("/other/thing") as CustomVoyager;

    expect(otherVoyager[WidgetPlugin.KEY], otherClosure);
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

      expect(router, isInstanceOf<voyager.Router>());

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

      expect(router, isInstanceOf<voyager.Router>());

      await tester.pumpWidget(MaterialApp(
          home: VoyagerWidget(path: "/other/foobar123", router: router)));

      expect(find.text("Other Page"), findsOneWidget);
      expect(find.text("This is foobar123"), findsOneWidget);
    });
  });

  test("merging one voyager into another", () {
    final one = Voyager(
      config: <String, dynamic>{},
      path: "/path",
    );
    one["mission"] = "Mission 1";
    one["brief"] = "A short brief from 1";
    final two = Voyager(
      config: <String, dynamic>{},
      path: "/path",
    );
    two["mission"] = "Mission 2";
    two["team"] = ["Jon", "Jessie"];

    two.merge(one);

    expect(two["mission"], "Mission 1");
    expect(two["brief"], "A short brief from 1");
    expect(two["team"], ["Jon", "Jessie"]);
  });

  test("merging one voyager into another with a lock", () {
    final one = Voyager(
      config: <String, dynamic>{},
      path: "/path",
    );
    one["mission"] = "Mission 1";
    one["brief"] = "A short brief from 1";
    final two = Voyager(
      config: <String, dynamic>{},
      path: "/path",
    );
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
    final one = Voyager(
      config: <String, dynamic>{},
      path: "/path",
    );
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
    final one = Voyager(
      config: <String, dynamic>{},
      path: "/path",
    );
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
    final one = Voyager(
      config: <String, dynamic>{},
      path: "/path",
    );
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

  test("adding dispose callback to locked voyager shouldn't throw", () {
    final one = Voyager(
      config: <String, dynamic>{},
      path: "/path",
    );
    var _onDisposeCalled = false;
    one["mission"] = "Mission 1";
    one["brief"] = "A short brief from 1";
    one.lock();

    one.onDispose(() {
      _onDisposeCalled = true;
    });

    expect(_onDisposeCalled, false);
    expect(one["mission"], "Mission 1");
    expect(one["brief"], "A short brief from 1");

    one.dispose();
    expect(_onDisposeCalled, true);

    /// since callback wasn't added
    expect(one["mission"], null);
    expect(one["brief"], null);
  });

  testWidgets('test VoyagerWidget didUpdateWidget',
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

      expect(router, isInstanceOf<voyager.Router>());

      const mockKey = Key("mockApp");

      final mockApp = _MockApp(mockKey, router: router, path: "/home");

      await tester.pumpWidget(mockApp);

      expect(find.text("Home Page"), findsOneWidget);
      expect(find.text("Home Title"), findsOneWidget);

      final mockElement = tester.element<StatefulElement>(find.byKey(mockKey));
      final mockElementState = mockElement.state as _MockAppState;

      mockElementState.path = "/other/thing";
      // ignore: invalid_use_of_protected_member
      mockElementState.setState(() {});

      await tester.pumpAndSettle();

      expect(find.text("Other Page"), findsOneWidget);
      expect(find.text("This is thing"), findsOneWidget);
    });
  });

  testWidgets('create HomeWidget via VoyagerWidget without router',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: VoyagerWidget(path: "/home", router: null)));
    expect(tester.takeException(), isA<TypeError>());
  });

  testWidgets(
      'create HomeWidget via VoyagerWidget without widget builder + keepAlive',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      final paths = loadPathsFromString(navigation_yml);
      final plugins = [_MockRouterPlugin()];

      final router = await loadRouter(paths, plugins);

      expect(router, isInstanceOf<voyager.Router>());

      await tester.pumpWidget(MaterialApp(
          home: VoyagerWidget(
        path: "/home",
        router: router,
        keepAlive: true,
      )));

      expect(tester.takeException(), isAssertionError);
    });
  });

  test('overriding existing path behavior', () async {
    final paths = loadPathsFromString(navigation_yml);
    final widgetMappings = {
      "HomeWidget": (BuildContext context) => MockHomeWidget(),
      "OtherWidget": (BuildContext context) => MockOtherWidget(),
    };
    final plugins = [WidgetPlugin(widgetMappings)];

    final router = await loadRouter(paths, plugins);

    final homeVoyager = router.find("/home")!;

    expect(homeVoyager[WidgetPlugin.KEY], widgetMappings["HomeWidget"]);
    expect(homeVoyager.type, "home");
    expect(homeVoyager["title"], "This is Home");

    final overridenPart = await loadPathsFromString('''
'/home' :
  type: 'home'
  widget: OtherWidget
  title: "This is Remote Home"
  fab: /other/thing
''');

    router.clearCache();
    router.registerPath(overridenPart.first);

    final remoteHomeVoyager = router.find("/home")!;

    expect(remoteHomeVoyager[WidgetPlugin.KEY], widgetMappings["OtherWidget"]);
    expect(remoteHomeVoyager.type, "home");
    expect(remoteHomeVoyager["title"], "This is Remote Home");
  });
}

class _MockApp extends StatefulWidget {
  const _MockApp(Key key, {required this.path, required this.router})
      : super(key: key);
  final String path;
  final voyager.Router router;

  @override
  State<StatefulWidget> createState() => _MockAppState();
}

class _MockRouterPlugin extends RouterPlugin {
  _MockRouterPlugin() : super("widget");

  @override
  void outputFor(RouterContext context, dynamic config, Voyager output) {
    output["widget"] = Voyager.nothing;
  }
}

class _MockAppState extends State<_MockApp> {
  late String path;
  late voyager.Router router;

  @override
  void initState() {
    super.initState();
    path = widget.path;
    router = widget.router;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: VoyagerWidget(path: path, router: router));
  }
}

Voyager _mockFactory(
        AbstractRouteContext abstractContext, Map<String, dynamic> config) =>
    Voyager(
        path: abstractContext.url(),
        parent: abstractContext.getExtras().parent,
        config: config);
