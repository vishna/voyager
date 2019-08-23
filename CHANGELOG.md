# 0.9.0

- support adding config for paths programatically 🎉

```dart
router.registerConfig('/home', (context, Voyager voyager) {
  voyager.type = "home";
  voyager[WidgetPlugin.KEY] =
      (BuildContext buildContext) => MockHomeWidget();
  voyager["title"] = "This is Home";
})
```

You can also supply a custom inherited Voyager instance...

```dart
final VoyagerFactory<CustomVoyager> customVoyagerFactory =
  (abstractContext, context) => CustomVoyager(
    abstractContext.url(), abstractContext.getExtras().parent);

router.registerConfig<CustomVoyager>('/other/:title', (context, voyager) {
  final title = context.params["title"];
  voyager.type = "other";
  voyager.widget = (BuildContext buildContext) => MockOtherWidget();
  voyager.title = "This is a $title";
}, customVoyagerFactory);
```

> If you aim for flexibility you should stick to YAML config and avoid this method. You can mix programmatic and YAML paths together. Code generator doesn't pick up programmatic paths. You have been warned. Use wisely.

- support supplying VoyagerArgument in automated tests

```dart
VoyagerTestObjectItemScenario.write("Talk", (WidgetTester tester) async {
        expect(find.text("Mountain View"), findsOneWidget);
      }, argument: const Talk("Mountain View", "Google I/O 2020", "19 May"))
```

- added static code analysis to the project
- over 90% code coverage

# 0.8.0

## SOME BREAKING CHANGES

- dropped `TypePlugin` since it was redundant, but since `type` has a special place in Voyager, it is exposed as getter and also is validated at runtime, so it must be a String if anything
- you can now pass custom AssetBundle to `loadPathsFromAssets` method
- massive work on improving test coverage of the library - gone from 57% to above 80%
- `WidgetPluginBuilder`, better API for adding widget mappings, allows you to skip manual Widget class name typing in the dart code.

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

You can still use the old syntax, but the above one brings more type safety to your code.

# 0.7.3

- expose `VoyagerParent` in build context when using a stateless widget

# 0.7.2

- `VoyagerListView`, a widget that allows mapping a list of items onto respective list of paths and then displaying them

# 0.7.1

- add optional `Key` constructor parameter to `VoyagerWidget` and `VoyagerStatelessWidget`

# 0.7.0

- ...and we're back to stateful widget by default - while you should use StatelessWidget whenever possible, navigation is causing widget recreation which means recreation of Voyager instance - and that's something we don't want to do.
- `generator` now supports CupertinoPageRoute that can be specified via additional parameter

```dart
generator(routeType: RouterNG.cupertinoRoute)
```

- `VoyagerArgument` is available via Provider whenever you navigate with an argument
- ability to dispose resources created with WidgetPlugins via onDispose callback:

```dart
output.onDispose(() {
  print("disposing resources");
});
```

# 0.6.1

- display information in case `dartfmt` is missing from your path and you're using code generation tool.

# 0.6.0

## SOME BREAKING CHANGES

- `VoyagerWidget` becomes stateless by default. If you want to have stateful behavior, please use `VoyagerStatefulWidget`
- Dropped `Voyager.fromPath` method, it was redundant and confusing. Use constructor directly instead.
- It is now recommended to wrap your app with `Provider<RouterNG>`. By doing this you can ommit passing the router parameter to every `VoyagerWidget` and thus making widget tree more compact since `VoyagerWidget` don't have to provide router instance themselves.

```
Provider<RouterNG>.value(
  value: router,
  child: MaterialApp(
    home: VoyagerWidget(path: initalPath),
    onGenerateRoute: router.generator()
  )
)
```

- `VoyagerWidget` has now extra cache parameter, meaning it will use RouterNG's caching internally to resolve `Voyager` instance faster. Depending on your use case you might want to use this or not. Such `Voyager` instance has no parent.

_The decision to change `VoyagerWidget` to stateless widget and removal of `fromPath` method was an inspiration after reading the following articles_:
- [Splitting Widgets To Methods is A Performance Antipattern](https://medium.com/flutter-community/splitting-widgets-to-methods-is-a-performance-antipattern-16aa3fb4026c) - Iiro Krankka
- [Flutter: Reducing widgets boilerplate](https://medium.com/@remirousselet/flutter-reducing-widgets-boilerplate-3e635f10685e) - Remi Rousselet

_It's a MUST READ for any Flutter developer._

# 0.5.2

- update to patched code generator version

# 0.5.1

- decrease occurences of voyager instance creation

# 0.5.0

> You will be automated, resistance is futile.

## BREAKING CHANGES

- automated widget tests (EXPERIMENTAL)
- removal of deprecated `VoyagerProvider`, see version `0.2.0` for migration steps (VoyagerProvider will return in a changed form...)
- removal of `TypePlugin` - it's redundant, omit it in plugins list but still use `type` in your specs for code generation goodness
- `RedirectPlugin`, allows mapping virtual paths to existing ones
- `ScreenPlugin` is now called `WidgetPlugin`, you also need to change `screen` to `widget` in your yaml/json specs

# 0.4.2

- use `dartfmt` to make sure generated code is formatted corectly

# 0.4.1

- package health

# 0.4.0

- [code generation](https://github.com/vishna/voyager#code-generation) for paths, simply run `flutter packages pub run voyager:codegen` at the top of your flutter project and behold!

# 0.3.0

- drop angel_route dependency in favor of [abstract_router.dart](https://github.com/vishna/voyager/blob/master/lib/src/abstract_router.dart)

# 0.2.3

- json support

# 0.2.2

- formatting

# 0.2.1

- fixes around how VoyagerWidget reacts to hot reload
- improve sample app
- add a sample app gif to README

# 0.2.0

**API DEPRECATION**

- `VoyagerProvider` is being phased out. Internally Voyager will depend on [provider](https://pub.dev/packages/provider) more popular within the community.

Migration:
- change `VoyagerProvider.of(context)` to `Provider.of<Voyager>(context)`
- change `VoyagerProvider.routerOf(context)` to `Provider.of<RouterNG>(context)`

# 0.1.1
- Package health fixes

# 0.1.0
- Initial release
