![banner](https://user-images.githubusercontent.com/121164/56737645-274c8a80-676b-11e9-86ec-0c99e41582fc.png)

[![pub package](https://img.shields.io/pub/v/voyager.svg)](https://pub.dartlang.org/packages/voyager)

> To boldly resolve where no Dart has resolved before.

Router, requirements & dependency injection library for Flutter.

## Features

If your app is a list of screens with respective paths then this library is for you.

- YAML based Navigation Spec
    - support for query parameters
    - support for global parameters
    - path subsections
    - parameters interpolation in subsections
    - logicless
    - deliverable over the air (think Firebase remote config)
    - code generator for paths (COMING SOON)
- Highly customizable plugin architecture.
- VoyagerWidget to embed your `path` at any point
- Provider to inject any data coming with the `path`

## Getting started

To use this plugin, add `voyager` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages).

You should ensure that you add the router as a dependency in your flutter project.

```yaml
dependencies:
 voyager: "^0.2.1"
```

You can also reference the git repo directly if you want:

```yaml
dependencies:
 voyager:
   git: git://github.com/vishna/voyager.git
```

Then in the code, make sure you import voyager package:

```dart
import 'package:voyager/voyager.dart';
```

### Navigation Spec

It’s best to start with describing what paths your app will have and what subsections will they be made of.

```yaml
---
'/home' :
  type: 'home'
  screen: HomeWidget
  title: "This is Home"
'/other/:title' :
  type: 'other'
  screen: OtherWidget
  title: "This is %{title}"
```

You can either put this in assets as a yaml file or use triple quotes `'''` and keep it in your code as a string. The String approach while a bit uglier allows for faster reloads while updating assets requires project rebuild.

### Creating Router Instance

Your router requires **paths** and **plugins** as constructor parameters. Getting **paths** is quite straightforwad and basically means parsing that YAML file we just defined.

```dart
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
```

or if the file is in the assets folder, you can:

```dart
final paths = loadPathsFromAssets("assets/navigation.yml");
```

The other important ingredient of voyager router are plugins. You need to tell router what kind of plugins you plan to use and those depend on what you have written in the navigation file. In our example we use 3 `type`, `screen` and `title`. This library comes with predefined plugins for `type` & `screen` and we'll create our own plugin for `title`.

```dart
final plugins = [
  [
    TypePlugin(),
    ScreenPlugin({ // provide widget builders for expressions used in YAML
      "HomeWidget": (context) => HomeWidget(),
      "OtherWidget": (context) => OtherWidget(),
    }),
    TitlePlugin()
  ]
];
```

Now you're all set for getting your router instance:

```dart
Future<RouterNG> router = loadRouter(paths, plugins)
```

### Custom Plugins

You can define as many plugins as you want. Here's how you could handle the `title` nodes from the example navigation yaml.

```dart
class TitlePlugin extends RouterPlugin {
  TitlePlugin() : super("title"); // YAML node to intercept

  @override
  void outputFor(RouterContext context, dynamic config, Voyager voyager) {
    // config can be anything that is passed from YAML
    voyager["title"] = config.toString(); // output of this plugin
  }
}
```

### Router's Default Output: Voyager

`Voyager` instance is the composite output of all the relevant plugins that are nested under the path being resolved. Observe:

```dart
Voyager voyager = router.find("/home")
print(voyager["title"]); // originates from the title plugin, prints: "This is home"
print(voyager["type"]); // originates from the type plugin, prints: "home"
assert(voyager["screenBuilder"] is WidgetBuilder); // originates from the screen plugin
```

**NOTE:** Any attempt to modify voyager keys will fail unless done from plugin's `outputFor` method. If you want to add some values to Voyager later on, use `Voyager.storage` public map.

### Embed any screen path with VoyagerWidget

If your path uses `screen` plugin you can try using `VoyagerWidget` and embed any path you want like this:

```dart
VoyagerWidget(path: "/home", router: router);
```

**NOTE:** You can even omit passing router instance if this `VoyagerWidget` is nested within other `VoyagerWidget`.

### Inject your information via Provider

If you use `VoyagerWidget` to create screens for your paths, you can obtain `Voyager` anywhere from `BuildContext` using [Provider](https://pub.dev/packages/provider):

```dart
final voyager = Provider.of<Voyager>(context);
```

Now going back to our mystery `OtherWidget` class from the example navigation spec, that widget could be implemented something like this:

```dart
class OtherWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final voyager = Provider.of<Voyager>(context); // injecting voyager from build context
    final title = voyager["title"]; // assuming title plugin worked and title is here 🙈

    return Scaffold(
      appBar: AppBar(
        title: Text(title), // et voilà
      ),
      body: Center(
        child: Text("Other Page"),
      )
    );
  }
}
```

### Integrating with MaterialApp

Defining inital path & handling navigation

```dart
final initalPath = "/my/fancy/super/path"

MaterialApp(
  home: VoyagerWidget(path: initalPath, router: router),
  onGenerateRoute: router.generator()
)
```

**NOTE:** You can use `MaterialApp.initalRoute` but please [read this first](https://docs.flutter.io/flutter/material/MaterialApp/initialRoute.html) if you find `MaterialApp.initalRoute` is not working for you. TL;DR: It's working as intended ¯\\\_(ツ)_/¯

### Navigation

Having `BuildContext` and `Material.onGenerateRoute` set up, you can simply:

```dart
Navigator.of(context).pushNamed("/path/to/go");
```

If you need to push new screen from elsewhere you probably should set [navigatorKey](https://docs.flutter.io/flutter/material/MaterialApp/navigatorKey.html) to your `MaterialApp`

### Custom Transitions

The article ["Create Custom Router Transition in Flutter using PageRouteBuilder"](https://medium.com/@agungsurya/create-custom-router-transition-in-flutter-using-pageroutebuilder-73a1a9c4a171) by *Agung Surya* explains in detail how to create custom reusable transtions.

Essentially you need to extend a `PageRouteBuilder` class and pass it a widget you want to be transitioning to. In our case that widget is a `VoyagerWidget`.

In the aforementioned artile, the author created `SlideRightRoute` transition. We can combine that transition with any path from our navigation spec by using code below:

```dart
Navigator.push(
  context,
  SlideRightRoute(widget: VoyagerWidget.fromPath(context, "/path/to/go")),
);
```

### Adding global values

If you want to expose some global parameters to specs interpolation, you can do so by doing the following:

```dart
router.registerGlobalParam("isTablet", false);
```

**NOTE**: Because we interpolate String here, only primitve types are allowed.

If you want to make some global entities available via router instance, you can do so by doing the following:

```dart
router.registerGlobalEntity("database", someDatabase);
```

### Sample App

![voyager_edited](https://user-images.githubusercontent.com/121164/60385202-eb91b200-9a86-11e9-8fb0-6923f43522ca.gif)

Check out full example [here](https://github.com/vishna/voyager/blob/master/example/lib/main.dart)

### Strong Typed Paths

Typing navigation paths by hand is error prone, for this very reason ~~there is~~ *there will* be companion library that generates you a dart class from your navigation file so you should only need to type path once.

### More Resources

- [library tests](https://github.com/vishna/voyager/blob/master/test/voyager_test.dart)
- [sample app](https://github.com/vishna/voyager/blob/master/example/lib/main.dart)

### Acknowledgments

- [fluro](https://github.com/theyakka/fluro) As their repo says: *"The brightest, hippest, coolest router for Flutter."* An alternative solution you might want to use if you find this library too obscure/immature ...you name it.
- [angel-route](https://github.com/angel-dart/route) *"A powerful, isomorphic routing library for Dart."* Voyager internally depends on this library.
- [eyeem/router](https://github.com/eyeem/router) Protoplast of the voyager library, written in Java, for Android.
- [NASA Voyager 2 Interstellar Poster](https://voyager.jpl.nasa.gov/downloads/posters/pdf/Voyager2_Interstellar_gold.pdf) Beautiful artwork I found on NASA page also a base content for the banner - changed colors to flutter ones, cropped the poster, added flutter antenna.