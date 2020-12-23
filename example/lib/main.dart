import 'package:example/gen/voyager_gen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voyager/voyager.dart';

/// navigation map, a yaml file, can be provided as a tripple quoted string
String requirements() {
  return '''
---
'/home' :
  type: 'home'
  widget: PageWidget
  title: "This is Home"
  body: "Hello World"
  fabPath: /fab
  actions:
    - target: /talks
      icon: e896
'/other/:title' :
  type: 'other'
  widget: PageWidget
  body: "Welcome to the other side"
  title: "This is %{title}"
'/fab' :
  type: fab
  widget: FabWidget
  target: /other/thing
  icon: e88f # check icons.dart for reference
'/talks' :
  type: 'talks'
  widget: ListWidget
  title: "Voyager Talks"
  items:
    - city: "Berlin"
      event: Droidcon
      date: July 1, 2019
    - city: "London"
      event: FlutterLDN
      date: October 21, 2019
    - city: "Łódź"
      event: Mobilization
      date: October 26, 2019
    - city: "San Francisco"
      event: Droidcon
      date: November 25-26, 2019
'/_object/:className':
  type: object_item
  widget: "%{className}Widget"
''';
}

/// list of [VoyagerPath] (a YAML above but parsed to objects)
List<VoyagerPath> paths() {
  return loadPathsFromYamlSync(requirements());
}

/// plugins that are mentioned in requirements
List<VoyagerPlugin> plugins() => [
      /// provide widget builders for expressions used in YAML
      WidgetPluginBuilder()
          .add("PageWidget", (context) => PageWidget())
          .add("ListWidget", (context) => ListWidget())
          .add("TalkWidget", (context) => TalkWidget())
          .add("FabWidget", makeMeFab)
          .build(),
      IconPlugin()
    ];

/// icon plugin
class IconPlugin extends IconPluginStub {
  @override
  Icon buildObject(VoyagerContext context, dynamic config) =>
      fromHexValue(config.toString());

  /// helper method converting hex value to an icon instance
  static Icon fromHexValue(String hexValue) {
    return Icon(
        IconData(int.parse(hexValue, radix: 16), fontFamily: 'MaterialIcons'));
  }
}

/// a model class that exposes [VoyagerStack] instance to entire widget tree using [Provider]
class MyStack extends ChangeNotifier {
  /// default constructor
  MyStack(
      {VoyagerStack value = const VoyagerStack<dynamic>([
        VoyagerPage(pathHome),
      ])})
      : _value = value;

  VoyagerStack _value;

  /// the current stack
  VoyagerStack get value => _value;

  /// push new stack state
  set value(VoyagerStack newValue) {
    _value = newValue;
    notifyListeners();
  }

  /// remove last item
  void pop() {
    value = value.removeLast();
  }

  /// add a new page on top
  void add(VoyagerPage information) {
    final newValue = value.mutate((items) {
      items.add(information);
    });
    value = newValue;
  }
}

void main() {
  /// initalize router router
  final router = VoyagerRouter.from(paths(), plugins());

  /// run the app
  runApp(ChangeNotifierProvider<MyStack>(
    create: (context) => MyStack(),
    child: Builder(builder: (context) {
      final stack = Provider.of<MyStack>(context);
      return VoyagerStackApp(
        router: router,
        stack: stack.value,
        onBackPressed: () {
          stack.pop();
        },
        createApp: (context, parser, delegate) => MaterialApp.router(
          title: "Voyager Demo",
          routeInformationParser: parser,
          routerDelegate: delegate,
          theme: themeData(),
        ),
      );
    }),
  ));
}

/// creates a floating action button
Widget makeMeFab(BuildContext context) {
  final voyager = context.voyager;
  return FloatingActionButton(
    onPressed: () {
      Provider.of<MyStack>(context, listen: false)
          .add(VoyagerPage(voyager.target!));
    },
    tooltip: 'Navigate',
    child: voyager.icon,
  );
}

/// theme data
ThemeData themeData() {
  return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xff5bb974),
      canvasColor: Colors.black,
      accentColor: const Color(0xfffcc934));
}

///page widget
class PageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final voyager = context.voyager;

    return Scaffold(
        appBar: AppBar(
          title: Text(voyager.title!),
          actions: actions(context),
        ),
        body: Center(
          child: Text(voyager.body!, style: const TextStyle(fontSize: 24)),
        ),
        floatingActionButton: voyager.fabPath != null
            ? VoyagerWidget(
                path: voyager.fabPath!,
              )
            : null);
  }
}

/// list widget
class ListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final voyager = context.voyager;

    final talks = voyager.items!
        .toList()
        .map((dynamic item) => Talk(item["city"], item["event"], item["date"]))
        .toList();

    return Scaffold(
        appBar: AppBar(
          title: Text(voyager.title!),
          actions: actions(context),
        ),
        body: ListView.builder(
          itemCount: talks.length,
          itemBuilder: (context, index) {
            final talk = talks[index];
            return VoyagerWidget(
                key: ValueKey(_idMapper(talk)),
                path: _objectMapper(talk),
                argument: VoyagerArgument(talk));
          },
        ),
        floatingActionButton: voyager.fabPath != null
            ? VoyagerWidget(
                path: voyager.fabPath!,
              )
            : null);
  }

  // ignore: avoid_as
  static String _idMapper(dynamic item) => (item as Talk).city;
  static String _objectMapper(dynamic item) =>
      pathObjectItem(item.runtimeType.toString());
}

/// object representing conference
class Talk {
  /// default constructor
  const Talk(this.city, this.event, this.date);

  /// city where the talk took place
  final String city;

  /// event during which the talk took place
  final String event;

  /// date when the talk took place
  final String date;
}

/// talk widget
class TalkWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Talk talk = context.voyagerArgument!.value;
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(talk.city,
                style: TextStyle(
                    fontSize: 20,
                    color: theme.accentColor,
                    fontWeight: FontWeight.bold)),
            Text(talk.event, style: const TextStyle(fontSize: 16)),
            Text(talk.date, style: const TextStyle(fontSize: 14)),
          ],
        ));
  }
}

/// actions
List<Widget>? actions(BuildContext context) {
  final actions = context.voyager.actions;
  if (actions == null || actions.isEmpty) {
    return null;
  }
  final widgets = <Widget>[];
  actions.forEach((dynamic action) {
    widgets.add(IconButton(
      icon: IconPlugin.fromHexValue(action["icon"]),
      onPressed: () {
        Provider.of<MyStack>(context, listen: false)
            .add(VoyagerPage(action["target"]));
      },
    ));
  });
  return widgets;
}
