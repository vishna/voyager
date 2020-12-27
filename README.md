![banner](https://user-images.githubusercontent.com/121164/56737645-274c8a80-676b-11e9-86ec-0c99e41582fc.png)

[![pub package](https://img.shields.io/pub/v/voyager.svg)](https://pub.dartlang.org/packages/voyager) [![Codemagic build status](https://api.codemagic.io/apps/5d52c99acb00320011561e79/5d52c99acb00320011561e78/status_badge.svg)](https://codemagic.io/apps/5d52c99acb00320011561e79/5d52c99acb00320011561e78/latest_build) [![codecov](https://codecov.io/gh/vishna/voyager/branch/master/graph/badge.svg)](https://codecov.io/gh/vishna/voyager) [![Kotlinlang slack](https://img.shields.io/static/v1?label=Flutter+Community&message=voyager&color=brightgreen&logo=slack&style=flat-square)](https://fluttercommunity.slack.com/messages/CP5GU9T19)


> Navigate and prosper 🖖

Voyager is a Widget router for Flutter with a dynamic navigation map and [Provider](https://pub.dev/packages/provider) based DI elements.

## Features

- Support for [Navigator 1.0/2.0 APIs](https://medium.com/flutter/learning-flutters-new-navigation-and-routing-system-7c9068155ade)
- YAML/JSON based Navigation Map
    - support for query parameters (`?param=value`)
    - path subsections (`/user/:id`)
    - parameters interpolation in subsections (`Selected %{id}`)
    - serializable (can be delivered using e.g. Firebase remote config)
    - [code generator](https://github.com/vishna/voyager-codegen) for paths & plugins
    - schema validation (draft v7)
- Highly customizable plugin architecture.
- `VoyagerWidget` to embed your `path` mapping in any place

## Getting started

Check the example app [on github](https://github.com/vishna/voyager/blob/master/example/lib/main.dart) or see it in [the browser](https://voyager.codemagic.app/).

- [Add Voyager Dependency](#add-voyager-dependency)
- [Define Navigation Map](#define-navigation-map)
- [Instantiate Router](#instantiate-router)
- [Choose Your API](#choose-your-api)
    - [Voyager Widget](#voyager-widget)
    - [Navigator 1.0](#navigator-10)
    - [Navigator 2.0](#navigator-20)
- [Predefined Plugins](#predefined-plugins)
    - [Widget Plugin](#widget-plugin)
    - [Page Plugin (a.k.a. transitions)](#page-plugin-aka-transitions)
    - [Redirect Plugin](#redirect-plugin)
- [Writing Custom Plugins](#writing-custom-plugins)
- [Dependency Injection](#dependency-injection)
- [Code Generation](#code-generation)
    - [Schema Validation](#schema-validation)

### Add Voyager Dependency

To use this plugin, add `voyager` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages).

You should ensure that you add the router as a dependency in your flutter project.

```yaml
dependencies:
 voyager: ^latest_release
```

Then in the code, make sure you import voyager package:

```dart
import 'package:voyager/voyager.dart';
```

### Define Navigation Map

In an example below there are two paths defined - `/home` and `/other/:title`. These paths route to `HomeWidget` and `OtherWidget` respectively. A map can carry extra information along the way - e.g. `title` will later be accessible in the routed widget.

```yaml
---
'/home' :
  type: 'home'
  widget: HomeWidget
  title: "This is Home"
'/other/:thing' :
  type: 'other'
  widget: OtherWidget
  title: "This is %{thing}"
```

The second path has `:thing` section parameter. This can be used to interpolate value of title dynamically at runtime, using `%{key}` notation.

Load paths using method of your choosing:
```dart
final List<VoyagerPath> paths = loadPathsFromYamlSync(yaml_string);
```

### Define Plugins

You need to tell router what kind of plugins you plan to use. Those depend on what you have written in the navigation file. In our example we need to provide mappings for `widget` and `title`.

```dart
final plugins = [
  WidgetPluginBuilder() /// provide widget builders for expressions used in YAML
    .add("HomeWidget", (context) => HomeWidget())
    .add("OtherWidget", (context) => OtherWidget())
    .build(),
  TitlePlugin() /// custom plugin
];
```

We omit `type` which is a field used for annotation purposes (code generation).

### Instantiate Router

Pass **paths** and **plugins** as constructor parameters to obtain `VoyagerRouter`.


```dart
final router = VoyagerRouter.from(paths, plugins);
```

### Choose Your API

Voyager offers different kind of APIs. Here's a quick overview what these are good for.

#### Voyager Widget

This is the most atomic use case. Simply embed your widget anywhere you want:

```dart
VoyagerWidget(path: "/home", router: router);
```

If `Provider<VoyagerRouter>` is available in the widget tree, you can omit the router parameter.

#### Navigator 1.0

Simple, imperative navigation model. Following snippet illustrates intergration with MaterialApp and opening `initialPath`:

```dart
final initalPath = "/my/fancy/super/path"

Provider<VoyagerRouter>.value(
  value: router,
  child: MaterialApp(
    home: VoyagerWidget(path: initalPath),
    onGenerateRoute: router.generator()
  )
)
```

Navigation stack is handled via system, e.g. following will push a new page:

```dart
Navigator.of(context).pushNamed("/path/to/go");
```

**Sidenote:** You can try using `MaterialApp.initalRoute` but please [read this first](https://docs.flutter.io/flutter/material/MaterialApp/initialRoute.html) if you find `MaterialApp.initalRoute` is not working for you... that's because it's probably working as intended ¯\\\_(ツ)_/¯

#### Navigator 2.0

Navigator 2.0 gives you a full control over the navigation stack. This comes with a price of [fairly complex API](https://medium.com/flutter/learning-flutters-new-navigation-and-routing-system-7c9068155ade). Voyager builds on top of this API and introduces `VoyagerStack` to hopefully make declarative navigation easier.

```dart
VoyagerStackApp(
  router: router,
  stack: VoyagerStack[
    VoyagerPage("/my/fancy/super/path"),
  ],
  createApp: (context, parser, delegate) => MaterialApp.router(
    routeInformationParser: parser,
    routerDelegate: delegate,
    theme: themeData(),
  ),
);
```

> With Navigator 2.0, you own the navigation stack.

If you wish to navigate to the other path, you'll need to update the stack the declarative way, e.g.:

```dart
  // ...
  stack: VoyagerStack[
    VoyagerPage("/my/fancy/super/path"),
    VoyagerPage("/path/to/go"),
  ],
  // ...
```

Under the hood, `VoyagerStack` uses `.asPages(VoyagerRouter)` method that resolves the given stack to a `List<Page<dynamic>>` instance which then is used with `Navigator`. It's possible to use `Navigator` and `VoyagerStack` directly without `VoyagerStackApp` wrapper. Additionally `VoyagerInformationParser` and `VoyagerDelegate` are easily instantiable in case you need to use them directly.

### Predefined Plugins

Voyager comes with a few predefined plugins that are ready to setup and use:

#### Widget Plugin

This is a mandatory plugin that enables widget resolution. It converts a string value from navigation map e.g. "HomeWidget" into a usable Flutter widget:

```dart
WidgetPlugin({
  "HomeWidget": (context) => HomeWidget()
});
```

You can enable [code generation](#code-generation) to avoid writing these mappings manually. Check the example app.

#### Page Plugin (a.k.a. transitions)

This plugin works only when using Voyager in Navigation 2.0 API. It enables specifying custom `Page<dynamic>` appearance to be used for the given path, e.g.:

```dart
PagePlugin({
  "slideFromTop": slideFromTop
});
```

Check [slide_from_top_page.dart](https://github.com/vishna/voyager/blob/master/example/lib/slide_from_top_page.dart) for a custom page implementation details

[Code generation](#code-generation) to avoid writing these mappings manually. Check the example app.

#### Redirect Plugin

Allows registering aliases for already defined paths:

```yaml
---
'/home' :
  type: 'home'
  widget: HomeWidget
  title: "This is Home"
'/start' :
  redirect: '/home'
```

### Writing Custom Plugins

You can define as many router plugins as you want. Here's how you could handle the `title` node from the example navigation yaml.

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

__Sidenote__: Above plugin is redundant. Voyager repackages the primitive types from configuration by default. __Use plugins to resolve primitive types to custom types__ , e.g. take a look at [IconPlugin](https://github.com/vishna/voyager/blob/master/example/lib/main.dart#L83) from the example app.

### Dependency Injection

If you use `VoyagerWidget` to e.g. resolve to `OtherWidget`, you can obtain `Voyager` anywhere from `BuildContext` using extension getter:

```dart
final voyager = context.voyager;
```

`Voyager` is a key/value map, a composite output of the plugins setup for the given path.

Now going back to our mystery `OtherWidget` class from the example navigation map, that widget's implementation could look something like this:

```dart
class OtherWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final voyager = context.voyager; // injecting voyager from build context
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

### Code generation

Using code generation enables you to use some of the following features:

- Strong typed paths
    - `"/other/:thing"` becomes `pathOther("thing")`
- [WidgetPlugin](#widget-plugin) generation
    - skip manual mapping, simply add `generatedVoyagerWidgetPlugin()` to list of plugins
- [PathPlugin](#path-plugin) generation
    - skip manual mapping, simply add `generatedVoyagerPathPlugin()` to list of plugins
- [Schema validation](#schema-validation) & strong typed Voyager fields

__Important__: Code generation relies heavily on the `type` value. It should be unique per path definition, also the values `should_be_snake_case`

Voyager supports generating dart code based on the navigation map yaml (json support [coming soon](https://github.com/vishna/voyager-codegen/issues/7)) file. Simply run the following command and wait for the script to set it up for you.

```
flutter packages pub run voyager:codegen --run-once
```

This should create a `voyager-codegen.yaml` file in the root of your project:

```yaml
- name: Voyager # base name for generated classes
  source: assets/navigation.yaml
  target: lib/navigation.voyager.dart
  widgetPlugin: true
  pagePlugin: true
```

Then you need to create `lib/navigation.dart` that will look something like this:

```dart
import 'package:voyager/voyager.dart';

part 'navigation.voyager.dart';
```

Now if you run again:

```
flutter packages pub run voyager:codegen --run-once
```

This should regenerate contents of `lib/navigation.voyager.dart`. If compiler complains about unresolved symbols, make sure you add necessary imports to `lib/navigation.dart`

__Dart Code Formatting__: If you want to have Flutter's default code formatting for the generated code, make sure you have dart-sdk in you PATH. Dart SDK is included with the flutter sdk, so you can e.g.:

```
export PATH="$PATH:/path/to/flutter/bin/cache/dart-sdk/bin"
```

__File Watching__: If you omit `--run-once` flag, the code generator will keep watching files and generating code in a loop.

You might want to add `.jarCache/` to your `.gitignore` to avoid checking in binary jars to your repo.

#### Schema Validation

Add your validation in `voyager-codegen.yaml`, for instance to cover `IconPlugin` you could do this:

```yaml
- name: Voyager
  source: lib/main.dart
  target: lib/navigation.voyager.dart
  schema:
    icon:
      pluginStub: true # add if you want to generate a plugin stub
      output: Icon # associated Dart class produced by the plugin
      input: # write schema for your the icon node (JSON Schema draft-07 layout)
        type: string
        pattern: "^[a-fA-F0-9]{4}$"
```

Now whenever you run `voyager:codegen` you'll get an extra message stating all is fine:

```
✅ Schema validated properly
```

...or an error specific to your router navigation map, e.g.:

```
🚨 /fab@icon: #/icon: string [e88fd] does not match pattern ^[a-fA-F0-9]{4}$
```

Furthermore you gain **strong typed** reference to the plugin output in extended `Voyager` instance:

```dart
assert(voyager.icon is Icon);
```

Finally, `pluginStub: true` gets you an abstract plugin class, so that you can avoid typing `voyager["node_name"]` manually. Just focus on parsing the node's config input and converting it into an expected output:

```dart
class IconPlugin extends IconPluginStub {
  @override
  Icon buildObject(RouterContext context, dynamic config) {
    /// write your code here
  }
}
```

