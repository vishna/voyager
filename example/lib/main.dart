import 'package:flutter/material.dart';
import 'package:voyager/voyager.dart';

/// Navigation spec
final paths = loadPathsFromString('''
---
'/home' :
  type: 'home'
  screen: HomeWidget
  title: "This is Home"
'/other/:title' :
  type: 'other'
  screen: OtherWidget
  title: "This is %{title}"
''');

/// plugins that are mentioned in the navigation spec
final plugins = [
  TypePlugin(),
  ScreenPlugin({
    // provide widget builders for expressions used in YAML
    "HomeWidget": (context) => HomeWidget(),
    "OtherWidget": (context) => OtherWidget(),
  }),
  TitlePlugin()
];

void main() {
  loadRouter(paths, plugins).then((router) => runApp(MyApp(router: router)));
}

class MyApp extends StatelessWidget {
  final RouterNG router;

  const MyApp({Key key, @required this.router}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voyager Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VoyagerWidget(path: "/home", router: router),
      onGenerateRoute: router.generator(),
    );
  }
}

class TitlePlugin extends RouterPlugin {
  TitlePlugin() : super("title"); // YAML node to intercept

  @override
  void outputFor(RouterContext context, dynamic config, Voyager voyager) {
    // config can be anything that is passed from YAML
    voyager["title"] = config.toString(); // output of this plugin
  }
}

class HomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final voyager =
        VoyagerProvider.of(context); // injecting voyager from build context
    final title =
        voyager["title"]; // assuming title plugin worked and title is here 🙈

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          child: Text("Home Page"),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed("/other/onfabpressed");
          },
          tooltip: 'Navigate',
          child: Icon(Icons.navigate_next),
        ));
  }
}

class OtherWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final voyager =
        VoyagerProvider.of(context); // injecting voyager from build context
    final title =
        voyager["title"]; // assuming title plugin worked and title is here 🙈

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          child: Text("Other Page"),
        ));
  }
}
