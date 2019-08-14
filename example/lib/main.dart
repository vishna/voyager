import 'package:example/gen/voyager_gen.dart';
import 'package:flutter/material.dart';
import 'package:voyager/voyager.dart';
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
''';
}

Future<List<RouterPath>> paths() {
  return loadPathsFromString(requirements());
}

/// plugins that are mentioned in requirements
final plugins = [
  WidgetPlugin({
    // provide widget builders for expressions used in YAML
    "PageWidget": (context) => PageWidget(),
    "FabWidget": makeMeFab
  }),
  IconPlugin()
];

class IconPlugin extends RouterPlugin {
  IconPlugin() : super("icon");

  @override
  void outputFor(RouterContext context, config, Voyager output) {
    output["icon"] = Icon(IconData(int.parse(config.toString(), radix: 16),
        fontFamily: 'MaterialIcons'));
  }
}

void main() {
  // wrapped with a builder, otherwise hot reload doesn't quite click
  runApp(Builder(builder: (builder) => appOrSplash()));
}

Widget appOrSplash() {
  return FutureBuilder(
      future: loadRouter(paths(), plugins),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final router = snapshot.data;
          return Provider<RouterNG>.value(
              value: router,
              child: MaterialApp(
                title: 'Voyager Demo',
                home:
                    VoyagerWidget(path: VoyagerPaths.pathHome, router: router),
                theme: themeData(),
                onGenerateRoute: router.generator(),
              ));
        } else {
          return SplashScreen();
        }
      });
}

Widget makeMeFab(BuildContext context) {
  final voyager = Provider.of<Voyager>(context);
  return FloatingActionButton(
    onPressed: () {
      Navigator.of(context).pushNamed(voyager["target"]);
    },
    tooltip: 'Navigate',
    child: voyager["icon"],
  );
}

ThemeData themeData() {
  return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xff5bb974),
      canvasColor: Colors.black,
      accentColor: Color(0xfffcc934));
}

class PageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final voyager = Provider.of<Voyager>(context);
    final title = voyager["title"];

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          child: Text(voyager["body"], style: TextStyle(fontSize: 24)),
        ),
        floatingActionButton: voyager["fabPath"] != null
            ? VoyagerWidget(
                path: voyager["fabPath"],
              )
            : null);
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text("Loading",
            style: TextStyle(fontSize: 24), textDirection: TextDirection.ltr));
  }
}
