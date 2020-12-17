import 'package:example/gen/voyager_gen.dart';
import 'package:flutter/material.dart';
import 'package:voyager/voyager.dart' hide VoyagerRouter;
import 'package:voyager/voyager.dart' as voyager;
import 'package:provider/provider.dart';

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

Future<List<VoyagerPath>> paths() {
  return loadPathsFromYamlString(requirements());
}

/// plugins that are mentioned in requirements
List<VoyagerPlugin> plugins() => [
      /// provide widget builders for expressions used in YAML
      WidgetPluginBuilder()
          .add<PageWidget>((context) => PageWidget())
          .add<ListWidget>((context) => ListWidget())
          .add<TalkWidget>((context) => TalkWidget())
          .addMethod(makeMeFab, "FabWidget")
          .build(),
      IconPlugin()
    ];

class IconPlugin extends IconPluginStub {
  @override
  Icon buildObject(VoyagerContext context, dynamic config) =>
      fromHexValue(config.toString());

  static Icon fromHexValue(String hexValue) {
    return Icon(
        IconData(int.parse(hexValue, radix: 16), fontFamily: 'MaterialIcons'));
  }
}

void main() {
  _setupVoyagerObfuscation();
  // wrapped with a builder, otherwise hot reload doesn't quite click
  runApp(Builder(builder: (builder) => appOrSplash()));
}

Widget appOrSplash() {
  return FutureBuilder(
      future: loadRouter(paths(), plugins()),
      builder: (BuildContext context,
          AsyncSnapshot<voyager.VoyagerRouter> snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final router = snapshot.data!;
          return Provider<voyager.VoyagerRouter>.value(
              value: router,
              child: MaterialApp(
                title: "Voyager Demo",
                home: VoyagerWidget(path: pathHome, router: router),
                theme: themeData(),
                onGenerateRoute: router.generator(),
              ));
        } else {
          return SplashScreen();
        }
      });
}

Widget makeMeFab(BuildContext context) {
  final voyager = context.voyager;
  return FloatingActionButton(
    onPressed: () {
      Navigator.of(context)!.pushNamed(voyager.target!);
    },
    tooltip: 'Navigate',
    child: voyager.icon,
  );
}

ThemeData themeData() {
  return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xff5bb974),
      canvasColor: Colors.black,
      accentColor: const Color(0xfffcc934));
}

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
                key: ValueKey(idMapper(talk)),
                path: objectMapper(talk),
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
  static String idMapper(dynamic item) => (item as Talk).city;
  static String objectMapper(dynamic item) =>
      pathObjectItem(VoyagerUtils.deobfuscate(item.runtimeType.toString()));
}

class Talk {
  const Talk(this.city, this.event, this.date);
  final String city;
  final String event;
  final String date;
}

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

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Text("Loading",
            style: TextStyle(fontSize: 24), textDirection: TextDirection.ltr));
  }
}

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
        Navigator.of(context)!.pushNamed(action["target"]);
      },
    ));
  });
  return widgets;
}

/// web release obfuscates class names, sadly we need to do this
void _setupVoyagerObfuscation() {
  VoyagerUtils.addObfuscationMap({
    PageWidget: "PageWidget",
    ListWidget: "ListWidget",
    TalkWidget: "TalkWidget",
    Talk: "Talk",
  });
}
