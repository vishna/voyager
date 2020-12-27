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
        stack: const VoyagerStack([VoyagerPage("/home")]),
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
        router: router, stack: const VoyagerStack([VoyagerPage("/home")])));

    expect(find.text("Home Page"), findsOneWidget);

    final state = tester.state<_FakeAppState>(find.byType(_FakeApp));

    state.setState(() {
      state.stack = const VoyagerStack([VoyagerPage("/other/thing")]);
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
        router: router, stack: const VoyagerStack([VoyagerPage("/home")])));

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
    var defaultPageBuilder = PagePlugin.defaultMaterial;
    final widgetMappings = {
      "HomeWidget": (BuildContext context) {
        if (defaultPageBuilder == PagePlugin.defaultCupertino) {
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
        if (defaultPageBuilder == PagePlugin.defaultCupertino) {
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
        stack: const VoyagerStack(
            [VoyagerPage("/home"), VoyagerPage("/other/thing")])));

    expect(find.text("Other Page"), findsOneWidget);

    final state = tester.state<_FakeAppState>(find.byType(_FakeApp));
    defaultPageBuilder = PagePlugin.defaultCupertino;
    state.setState(() {
      state.defaultPageBuilder = defaultPageBuilder;
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
        stack: const VoyagerStack(
          [
            VoyagerStack(
              [
                VoyagerStack(
                  [
                    VoyagerPage("/home"),
                  ],
                  scope: true,
                )
              ],
              scope: 42,
            ),
          ],
          scope: "meaning of life is",
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
    const stack =
        VoyagerStack([VoyagerPage("/home"), VoyagerPage("/other/thing")]);

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
    final delegate = VoyagerDelegate(
      router,
      initialStack: const VoyagerStack(
        [
          VoyagerPage("/home"),
          VoyagerPage("/other/thing"),
        ],
      ),
      onInitialPage: (page) {
        // ignore
      },
    );

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
    final delegate = VoyagerDelegate(
      router,
      initialStack: const VoyagerStack([
        VoyagerPage("/home"),
        VoyagerPage("/other/thing"),
      ]),
    );

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
    const stack =
        VoyagerStack([VoyagerPage("/home"), VoyagerPage("/other/thing")]);

    await tester.pumpWidget(VoyagerStackApp(
      router: router,
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

  testWidgets("VoyagerStackApp - Home Page, Declarative Way with custom page",
      (tester) async {
    final widgetMappings = {
      "HomeWidget": (BuildContext context) => MockHomeWidget(),
      "OtherWidget": (BuildContext context) => MockOtherWidget(),
    };
    final paths = loadPathsFromYamlSync('''
---
'/home' :
  type: 'home'
  page: 'yolo'
  widget: HomeWidget
  title: "This is Home"
  fab: /other/thing
'/other/:title' :
  type: 'other'
  widget: OtherWidget
  title: "This is %{title}"
''');
    final plugins = [
      WidgetPlugin(widgetMappings),
      const PagePlugin({"yolo": PagePlugin.defaultMaterial})
    ];
    final router = VoyagerRouter.from(paths, plugins);

    await tester.pumpWidget(VoyagerStackApp(
        onBackPressed: () {},
        router: router,
        stack: const VoyagerStack([VoyagerPage("/home")]),
        createApp: (context, parser, delegate) => MaterialApp.router(
            routeInformationParser: parser, routerDelegate: delegate)));

    expect(find.text("Home Page"), findsOneWidget);
  });

  testWidgets("VoyagerStackApp - change transition delegate", (tester) async {
    var wasCalled = false;
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

    await tester.pumpWidget(_FakeApp(
        router: router,
        stack: const VoyagerStack(
            [VoyagerPage("/home"), VoyagerPage("/other/thing")])));

    expect(find.text("Other Page"), findsOneWidget);
    expect(wasCalled, false);

    final state = tester.state<_FakeAppState>(find.byType(_FakeApp));

    state.setState(() {
      state.transitionDelegate = _NoAnimationTransitionDelegate()
        ..callback = () => wasCalled = true;
    });
    await tester.pumpAndSettle();

    expect(find.text("Other Page"), findsOneWidget);
    expect(wasCalled, false);

    state.setState(() {
      state.stack = const VoyagerStack([VoyagerPage("/home")]);
    });
    await tester.pumpAndSettle();

    expect(find.text("Home Page"), findsOneWidget);
    expect(wasCalled, true);
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
  VoyagerPageBuilder? defaultPageBuilder;
  TransitionDelegate<dynamic>? transitionDelegate;

  @override
  Widget build(BuildContext context) {
    return VoyagerStackApp(
        onBackPressed: () {},
        onNewPage: (page) {},
        onInitialPage: (page) {},
        router: router ?? widget.router,
        stack: stack ?? widget.stack,
        defaultPageBuilder: defaultPageBuilder ?? PagePlugin.defaultMaterial,
        transitionDelegate:
            transitionDelegate ?? const DefaultTransitionDelegate<dynamic>(),
        createApp: (context, parser, delegate) {
          if (delegate.defaultPageBuilder == PagePlugin.defaultCupertino) {
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

class _NoAnimationTransitionDelegate extends TransitionDelegate<dynamic> {
  VoidCallback? callback;
  @override
  Iterable<RouteTransitionRecord> resolve({
    required List<RouteTransitionRecord> newPageRouteHistory,
    required Map<RouteTransitionRecord?, RouteTransitionRecord>
        locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
        pageRouteToPagelessRoutes,
  }) {
    final results = <RouteTransitionRecord>[];

    for (final pageRoute in newPageRouteHistory) {
      if (pageRoute.isWaitingForEnteringDecision) {
        pageRoute.markForAdd();
      }
      results.add(pageRoute);
    }

    for (final exitingPageRoute in locationToExitingPageRoute.values) {
      if (exitingPageRoute.isWaitingForExitingDecision) {
        exitingPageRoute.markForRemove();
        final pagelessRoutes = pageRouteToPagelessRoutes[exitingPageRoute];
        if (pagelessRoutes != null) {
          for (final pagelessRoute in pagelessRoutes) {
            pagelessRoute.markForRemove();
          }
        }
      }

      results.add(exitingPageRoute);
    }
    callback?.call();
    return results;
  }
}
