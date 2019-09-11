![banner](https://user-images.githubusercontent.com/121164/56737645-274c8a80-676b-11e9-86ec-0c99e41582fc.png)

[![pub package](https://img.shields.io/pub/v/voyager.svg)](https://pub.dartlang.org/packages/voyager) [![Codemagic build status](https://api.codemagic.io/apps/5d52c99acb00320011561e79/5d52c99acb00320011561e78/status_badge.svg)](https://codemagic.io/apps/5d52c99acb00320011561e79/5d52c99acb00320011561e78/latest_build) [![codecov](https://codecov.io/gh/vishna/voyager/branch/master/graph/badge.svg)](https://codecov.io/gh/vishna/voyager)


> Navigate and prosper 🖖

Router, requirements & dependency injection library for Flutter.

## Features

If your app is a list of screens with respective paths then this library is for you.

- YAML/JSON based Navigation Spec
    - support for query parameters
    - support for global parameters
    - path subsections
    - parameters interpolation in subsections
    - logicless
    - deliverable over the air (think Firebase remote config)
    - code generator for paths/tests
- Highly customizable plugin architecture.
- VoyagerWidget to embed your `path` at any point
- Provider to inject any data coming with the `path`

## Getting started

To use this plugin, add `voyager` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages).

You should ensure that you add the router as a dependency in your flutter project.

```yaml
dependencies:
 voyager: ^latest_release
 provider: ^3.0.0+1 # if you don't have it yet
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
  widget: HomeWidget
  title: "This is Home"
'/other/:title' :
  type: 'other'
  widget: OtherWidget
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
  widget: HomeWidget
  title: "This is Home"
'/other/:title' :
  type: 'other'
  widget: OtherWidget
  title: "This is %{title}"
''');
```

or if the file is in the assets folder, you can:

```dart
final paths = loadPathsFromAssets("assets/navigation.yml");
```

__NOTE__: JSON support is available as of version `0.2.3`, please check [voyager_test.dart](https://github.com/vishna/voyager/blob/master/test/voyager_test.dart) for reference.

The other important ingredient of voyager router are plugins. You need to tell router what kind of plugins you plan to use and those depend on what you have written in the navigation file. In our example we use 2 `widget` and `title`. This library comes with predefined plugins for `widget` and in the next paragraph you can read how to create your own plugin for `title`.

```dart
final plugins = [
  [
    WidgetPluginBuilder() /// provide widget builders for expressions used in YAML
      .add<HomeWidget>((context) => HomeWidget())
      .add<OtherWidget>((context) => OtherWidget())
      .build(),
    TitlePlugin() /// custom plugin
  ]
];
```

Now you're all set for getting your router instance:

```dart
Future<Router> router = loadRouter(paths, plugins)
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

__NOTE__: Above plugin is redundant, Voyager will repackage the primitive types from configuration and you don't need to do anything 😎 __Use plugins to resolve primitive types to custom types__ , e.g. take a look at [IconPlugin](https://github.com/vishna/voyager/blob/master/example/lib/main.dart#L42) from the example app.

### Router's Default Output: Voyager

`Voyager` instance is the composite output of all the relevant plugins that are nested under the path being resolved. Observe:

```dart
Voyager voyager = router.find("/home")
print(voyager["title"]); /// originates from the title plugin, prints: "This is home"
print(voyager["type"]); /// automatically inherited from the YAML map
print(voyager.type); /// strong typed type
assert(voyager["widget"] is WidgetBuilder); /// originates from the widget plugin
```

**NOTE:** Any attempt to modify voyager keys will fail unless done from plugin's `outputFor` method. If you want to add some values to Voyager later on, use `Voyager.storage` public map.

### Embed any screen path with VoyagerWidget

If your path uses `widget` plugin you can try using `VoyagerWidget` and embed any path you want like this:

```dart
VoyagerWidget(path: "/home", router: router);
```

**RECOMMENDED:** Provide router at the top of your widget tree and omit passing router parameter.

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
    final title = voyager["title"];

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

Provider<Router>.value(
  value: router,
  child: MaterialApp(
    home: VoyagerWidget(path: initalPath),
    onGenerateRoute: router.generator()
  )
)
```

Make sure you wrap your app with router provider.

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

### Code generation

__IMPORTANT__: Code generation relies heavily on the `type` value. It should be unique per path definition, also the values `should_be_snake_case`

Voyager supports generating dart code based on the configuration yaml file. Simply run the following command and wait for the script to set it up for you.

```
flutter packages pub run voyager:codegen
```

This should create a `voyager-codegen.yaml` file in a root of your project, like so:

```yaml
- name: Voyager # base name for generated classes, e.g. VoyagerPaths, VoyagerTests etc.
  source: assets/navigation.yaml
  target: lib/gen/voyager_gen.dart
```

Whenever you edit the `voyager-codegen.yaml` or `source` file the code generation logic will pick it up (as long as `pub run` is running) and generate new dart souces to the target location.

__CODE FORMATTING__: If you want to have Flutter's default code formatting, make sure you have dart-sdk in you PATH, it's included with flutter sdk, so you can e.g.:

```
export PATH="$PATH:/path/to/flutter/bin/cache/dart-sdk/bin"
```

Proper formatting relies on `dartfmt` command being available.

__NOTE 1__: For code generator implementation details please check the source code at [vishna/voyager-codegen](https://github.com/vishna/voyager-codegen).

__NOTE 2__: Should you want run code generation only once (and not watch files continously) you can supply additional `--run-once` flag to pub run command:

```
flutter packages pub run voyager:codegen --run-once
```

This can be useful if running in a CI/CD context.

__NOTE 3__: You might want to add `.jarCache/` to your `.gitignore` to avoid checking in binary jars to your repo.

__NOTE 4__: If you're a Windows user make sure you have `wget` installed.

#### Strong Typed Paths

Typing navigation paths by hand is error prone, for this very reason **it is recommended** to use code generator for the paths, so rather than typing:

```dart
Navigator.of(context).pushNamed("/other/thingy");
```

you can rely on your IDE's autocompletion and do this:

```dart
Navigator.of(context).pushNamed(VoyagerPaths.pathOther("thingy"));
```

#### Automated Widget Tests (Experimental Feautre)

![Screenshot 2019-07-31 at 15 19 15](https://user-images.githubusercontent.com/121164/62217336-c1475300-b3aa-11e9-8ffb-a0ebb815fd6d.png)

If you want to try this feature out, your `voyager-codegen.yaml` should look something like that:

```yaml
- name: Voyager
  source: assets/navigation.yaml
  target: lib/gen/voyager_gen.dart
  testTarget: test/gen/voyager_test_scenarios.dart
```

`testTarget` points to where the generated test code should go.

Say your regular test file is located in the `test` directory, this is how you could integrate with the generated code:

```dart
import 'gen/voyager_test_scenarios.dart';

/// override abstract base class with all the scenarios to test
class TestScenarios extends VoyagerTestScenarios {

  /// default wrapper for all the widgets
  MyVoyagerScenarios() : super((widget) => MaterialApp(home: widget));

  @override
  /// example scenario implementation for the `/home` path
  List<VoyagerTestHomeScenario> homeScenarios() {
    return [
      VoyagerTestHomeScenario.write((tester) async {
        expect(find.text("Home Page"), findsOneWidget);
      })
    ];
  }

  /// etc...
}

void main() {
  /// finally invoke tests, you need to suply `router` as `Future<Router>`
  voyagerAutomatedTests("voyager auto tests", router, TestScenarios());
}
```

Full code available at [example/test/widget_test.dart](https://github.com/vishna/voyager/blob/master/example/test/widget_test.dart).

`voyagerAutomatedTests` comes with a positional argument `forceTests` set to `true` by default. This will assert every widget has **at least one scenario** written for it, otherwise your tests will fail. Set it to `false` to disable this behaviour.

The scenario code is by default being executed within WidgetTester's `runAsync` meaning you should be able to perform real asynchronous methods.

The router is loaded every time the scenario is running - if this is something you don't need consider using e.g. [AsyncMemoizer](https://api.flutter.dev/flutter/package-async_async/AsyncMemoizer-class.html)

### More Resources

- [library tests](https://github.com/vishna/voyager/blob/master/test)
- [sample app](https://github.com/vishna/voyager/blob/master/example/lib/main.dart)

### Acknowledgments

- [fluro](https://github.com/theyakka/fluro) As their repo says: *"The brightest, hippest, coolest router for Flutter."* Probably the most know flutter router out there.
- [angel-route](https://github.com/angel-dart/route) *"A powerful, isomorphic routing library for Dart."* Voyager internally was depending on this library till version `0.2.3`. It was a server oriented library and too big dependency for this project - voyager is now using [abstract_router.dart](https://github.com/vishna/voyager/blob/master/lib/src/abstract_router.dart) which is < 300 LOC.
- [eyeem/router](https://github.com/eyeem/router) Protoplast of the voyager library, written in Java, for Android.
- [NASA Voyager 2 Interstellar Poster](https://voyager.jpl.nasa.gov/downloads/posters/pdf/Voyager2_Interstellar_gold.pdf) Beautiful artwork I found on NASA page also a base content for the banner - changed colors to flutter ones, cropped the poster, added flutter antenna.