// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/voyager.dart';

import 'mock_classes.dart';
import 'navigation_yml.dart';

void main() {
  testWidgets("VoyagerStackApp - Home Page, Declarative Way", (tester) async {
    final widgetMappings = {
      "HomeWidget": (BuildContext context) => MockHomeWidget(),
      "OtherWidget": (BuildContext context) => MockOtherWidget(),
    };
    final paths = loadPathsFromYamlSync(navigation_yml);
    final plugins = [WidgetPlugin(widgetMappings)];
    final router = VoyagerRouter.from(paths, plugins);

    await tester.pumpWidget(VoyagerStackApp(
        onBackPressed: () {},
        router: router,
        stack: const VoyagerStack<dynamic>([VoyagerPage("/home")]),
        createApp: (context, parser, delegate) => MaterialApp.router(
            routeInformationParser: parser, routerDelegate: delegate)));

    expect(find.text("Home Page"), findsOneWidget);
  });

  testWidgets(
      "VoyagerStackApp - Home Page, Declarative Way & then update to the OtherPage",
      (tester) async {
    final widgetMappings = {
      "HomeWidget": (BuildContext context) => MockHomeWidget(),
      "OtherWidget": (BuildContext context) => MockOtherWidget(),
    };
    final paths = loadPathsFromYamlSync(navigation_yml);
    final plugins = [WidgetPlugin(widgetMappings)];
    final router = VoyagerRouter.from(paths, plugins);

    await tester.pumpWidget(_FakeApp(
        router: router,
        stack: const VoyagerStack<dynamic>([VoyagerPage("/home")])));

    expect(find.text("Home Page"), findsOneWidget);

    final state = tester.state<_FakeAppState>(find.byType(_FakeApp));

    state.setState(() {
      state.stack = const VoyagerStack<dynamic>([VoyagerPage("/other/thing")]);
    });
    await tester.pumpAndSettle();

    expect(find.text("Other Page"), findsOneWidget);
  });

  testWidgets("VoyagerStackApp - router update", (tester) async {
    final widgetMappings = {
      "HomeWidget": (BuildContext context) => MockHomeWidget(),
      "OtherWidget": (BuildContext context) => MockOtherWidget(),
    };
    final paths = loadPathsFromYamlSync(navigation_yml);
    final plugins = [WidgetPlugin(widgetMappings)];
    final router = VoyagerRouter.from(paths, plugins);

    await tester.pumpWidget(_FakeApp(
        router: router,
        stack: const VoyagerStack<dynamic>([VoyagerPage("/home")])));

    expect(find.text("Home Page"), findsOneWidget);

    final paths2 = loadPathsFromYamlSync('''
---
'/home' :
  type: 'home'
  widget: OtherWidget
  title: "This is Home"
  fab: /other/thing
'/other/:title' :
  type: 'other'
  widget: OtherWidget
  title: "This is %{title}"
''');
    final router2 = VoyagerRouter.from(paths2, plugins);

    final state = tester.state<_FakeAppState>(find.byType(_FakeApp));

    state.setState(() {
      state.router = router2;
    });
    await tester.pumpAndSettle();

    expect(find.text("Other Page"), findsOneWidget);
  });

  testWidgets("VoyagerStackApp - switch from Material to Cupertino",
      (tester) async {
    var routeType = VoyagerRouteType.material;
    final widgetMappings = {
      "HomeWidget": (BuildContext context) {
        if (routeType == VoyagerRouteType.cupertino) {
          return const CupertinoPageScaffold(
            child: Center(
              child: Text("Home Page"),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text("Home Title"),
          ),
          body: const Center(
            child: Text("Home Page"),
          ),
          floatingActionButton: mockFab(context),
        );
      },
      "OtherWidget": (BuildContext context) {
        if (routeType == VoyagerRouteType.cupertino) {
          return const CupertinoPageScaffold(
            child: Center(
              child: Text("This is Cupertino"),
            ),
          );
        }

        final String title = context.voyager["title"];

        return Scaffold(
            appBar: AppBar(
              title: Text(title),
            ),
            body: const Center(
              child: Text("Other Page"),
            ));
      },
    };
    final paths = loadPathsFromYamlSync(navigation_yml);
    final plugins = [WidgetPlugin(widgetMappings)];
    final router = VoyagerRouter.from(paths, plugins);

    await tester.pumpWidget(_FakeApp(
        router: router,
        stack: const VoyagerStack<dynamic>(
            [VoyagerPage("/home"), VoyagerPage("/other/thing")])));

    expect(find.text("Other Page"), findsOneWidget);

    final state = tester.state<_FakeAppState>(find.byType(_FakeApp));
    routeType = VoyagerRouteType.cupertino;
    state.setState(() {
      state.routeType = routeType;
    });
    await tester.pumpAndSettle();

    expect(find.text("This is Cupertino"), findsOneWidget);
  });

  testWidgets("VoyagerStackApp - nested scopes", (tester) async {
    final widgetMappings = {
      "HomeWidget": (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Home Title"),
          ),
          body: Center(
            child: Text(
                """${context.voyagerScope<bool>()} ${context.voyagerScope<String>()} ${context.voyagerScope<int>()}"""),
          ),
          floatingActionButton: mockFab(context),
        );
      }
    };
    final paths = loadPathsFromYamlSync(navigation_yml);
    final plugins = [WidgetPlugin(widgetMappings)];
    final router = VoyagerRouter.from(paths, plugins);

    await tester.pumpWidget(VoyagerStackApp(
        router: router,
        createApp: (context, parser, delegate) {
          return MaterialApp.router(
            routerDelegate: delegate,
            routeInformationParser: parser,
          );
        },
        stack: const VoyagerStack<String>(
          [
            VoyagerStack<int>(
              [
                VoyagerStack<bool>(
                  [
                    VoyagerPage("/home"),
                  ],
                  scope: VoyagerStackScope(true),
                )
              ],
              scope: VoyagerStackScope(42),
            ),
          ],
          scope: VoyagerStackScope("meaning of life is"),
        ),
        onBackPressed: () {}));

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text("true meaning of life is 42"), findsOneWidget);
  });

  testWidgets("VoyagerStackApp - back callback", (tester) async {
    final widgetMappings = {
      "HomeWidget": (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Home Title"),
          ),
          body: const Center(
            child: Text("Home Page"),
          ),
          floatingActionButton: mockFab(context),
        );
      },
      "OtherWidget": (BuildContext context) {
        final String title = context.voyager["title"];

        return Scaffold(
            appBar: AppBar(
              title: Text(title),
            ),
            body: const Center(
              child: Text("Other Page"),
            ));
      },
    };
    var wasBackPressed = false;
    final paths = loadPathsFromYamlSync(navigation_yml);
    final plugins = [WidgetPlugin(widgetMappings)];
    final router = VoyagerRouter.from(paths, plugins);
    const stack = VoyagerStack<dynamic>(
        [VoyagerPage("/home"), VoyagerPage("/other/thing")]);

    await tester.pumpWidget(VoyagerStackApp(
        router: router,
        createApp: (context, parser, delegate) => MaterialApp.router(
            routeInformationParser: parser, routerDelegate: delegate),
        stack: stack,
        onBackPressed: () {
          wasBackPressed = true;
        }));

    expect(find.text("Other Page"), findsOneWidget);
    expect(wasBackPressed, false);

    await tester.pageBack();

    expect(wasBackPressed, true);
  });

  testWidgets("VoyagerDelegate - back callback", (tester) async {
    final widgetMappings = {
      "HomeWidget": (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Home Title"),
          ),
          body: const Center(
            child: Text("Home Page"),
          ),
          floatingActionButton: mockFab(context),
        );
      },
      "OtherWidget": (BuildContext context) {
        final String title = context.voyager["title"];

        return Scaffold(
            appBar: AppBar(
              title: Text(title),
            ),
            body: const Center(
              child: Text("Other Page"),
            ));
      },
    };

    final paths = loadPathsFromYamlSync(navigation_yml);
    final plugins = [WidgetPlugin(widgetMappings)];
    final router = VoyagerRouter.from(paths, plugins);
    final delegate = VoyagerDelegate(router, initialStackPages: const [
      VoyagerPage("/home"),
      VoyagerPage("/other/thing")
    ]);

    await tester.pumpWidget(
      MaterialApp.router(
        routeInformationParser: const VoyagerInformationParser(),
        routerDelegate: delegate,
      ),
    );

    expect(find.text("Other Page"), findsOneWidget);
    expect(delegate.stack.toPathList(), ['/home', '/other/thing']);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text("Home Page"), findsOneWidget);
    expect(delegate.stack.toPathList(), ['/home']);
  });

  testWidgets("VoyagerDelegate - enable initial path", (tester) async {
    final widgetMappings = {
      "HomeWidget": (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Home Title"),
          ),
          body: const Center(
            child: Text("Home Page"),
          ),
          floatingActionButton: mockFab(context),
        );
      },
      "OtherWidget": (BuildContext context) {
        final String title = context.voyager["title"];

        return Scaffold(
            appBar: AppBar(
              title: Text(title),
            ),
            body: const Center(
              child: Text("Other Page"),
            ));
      },
    };

    final paths = loadPathsFromYamlSync(navigation_yml);
    final plugins = [WidgetPlugin(widgetMappings)];
    final router = VoyagerRouter.from(paths, plugins);
    final delegate = VoyagerDelegate(router,
        initialStackPages: const [
          VoyagerPage("/home"),
          VoyagerPage("/other/thing")
        ],
        ignoreInitialPath: false);

    await tester.pumpWidget(
      MaterialApp.router(
        routeInformationParser: const VoyagerInformationParser(),
        routerDelegate: delegate,
      ),
    );

    expect(delegate.stack.toPathList(), ['/home', '/other/thing', '/']);
  });

  testWidgets("VoyagerStackApp - onNewCallback", (tester) async {
    final widgetMappings = {
      "HomeWidget": (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Home Title"),
          ),
          body: const Center(
            child: Text("Home Page"),
          ),
          floatingActionButton: mockFab(context),
        );
      },
      "OtherWidget": (BuildContext context) {
        final String title = context.voyager["title"];

        return Scaffold(
            appBar: AppBar(
              title: Text(title),
            ),
            body: const Center(
              child: Text("Other Page"),
            ));
      },
    };
    var wasNewPageCalled = false;
    final paths = loadPathsFromYamlSync(navigation_yml);
    final plugins = [WidgetPlugin(widgetMappings)];
    final router = VoyagerRouter.from(paths, plugins);
    const stack = VoyagerStack<dynamic>(
        [VoyagerPage("/home"), VoyagerPage("/other/thing")]);

    await tester.pumpWidget(VoyagerStackApp(
      router: router,
      ignoreInitialPath: false,
      onNewPage: (page) {
        wasNewPageCalled = true;
      },
      createApp: (context, parser, delegate) => MaterialApp.router(
          routeInformationParser: parser, routerDelegate: delegate),
      stack: stack,
      onBackPressed: () {},
    ));

    expect(find.text("Other Page"), findsOneWidget);
    expect(wasNewPageCalled, true);
  });
}

class _FakeApp extends StatefulWidget {
  const _FakeApp({Key? key, required this.router, required this.stack})
      : super(key: key);
  final VoyagerRouter router;
  final VoyagerStack stack;
  @override
  _FakeAppState createState() => _FakeAppState();
}

class _FakeAppState extends State<_FakeApp> {
  VoyagerRouter? router;
  VoyagerStack? stack;
  VoyagerRouteType? routeType;

  @override
  Widget build(BuildContext context) {
    return VoyagerStackApp(
        onBackPressed: () {},
        onNewPage: (page) {},
        router: router ?? widget.router,
        stack: stack ?? widget.stack,
        routeType: routeType ?? VoyagerRouteType.material,
        createApp: (context, parser, delegate) {
          if (delegate.routeType == VoyagerRouteType.cupertino) {
            return CupertinoApp.router(
              routeInformationParser: parser,
              routerDelegate: delegate,
            );
          } else {
            return MaterialApp.router(
                routeInformationParser: parser, routerDelegate: delegate);
          }
        });
  }
}
