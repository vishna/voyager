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
