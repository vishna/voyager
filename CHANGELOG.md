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
