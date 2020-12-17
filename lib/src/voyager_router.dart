import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:voyager/voyager.dart';
import 'package:yaml/yaml.dart';

/// loads voyager paths from yaml string synchronously
List<VoyagerPath> loadPathsFromYamlSync(String yaml) {
  final YamlMap routerMap = loadYaml(yaml);
  final paths = <VoyagerPath>[];

  routerMap.keys.forEach((dynamic it) {
    paths.add(VoyagerPath.fromYaml(path: it, config: routerMap[it]));
  });

  return paths;
}

/// loads voyager paths from json string synchronously
List<VoyagerPath> loadPathsFromJsonSync(String jsonString) {
  final Map<String, dynamic> routerMap = json.decode(jsonString);
  final paths = <VoyagerPath>[];

  routerMap.keys.forEach((it) {
    paths.add(VoyagerPath.fromMap(path: it, config: routerMap[it]));
  });

  return paths;
}

/// loads voyager paths from yaml file in assets asynchronously
/// where [path] is e.g. "assets/navigation.yml"
Future<List<VoyagerPath>> loadPathsFromAssets(String path,
    {AssetBundle? assetBundle}) async {
  assetBundle ??= rootBundle;
  final yaml = await assetBundle.loadString(path);
  return loadPathsFromYamlSync(yaml);
}

/// loads voyager paths from yaml string asynchronously
Future<List<VoyagerPath>> loadPathsFromYamlString(String yaml) async {
  return compute(loadPathsFromYamlSync, yaml);
}

/// loads voyager paths from yaml string asynchronously
Future<List<VoyagerPath>> loadPathsFromJsonString(String json) async {
  return compute(loadPathsFromJsonSync, json);
}

/// given [paths] and [plugins] resolves you a router.
Future<VoyagerRouter> loadRouter(
    Future<List<VoyagerPath>> paths, List<VoyagerPlugin> plugins,
    {VoyagerFactory? voyagerFactory}) {
  final router = voyagerFactory != null
      ? VoyagerRouter(voyagerFactory: voyagerFactory)
      : VoyagerRouter();

  plugins.forEach((plugin) {
    router.registerPlugin(plugin);
  });

  return paths.then((paths) {
    paths.forEach((path) {
      router.registerPath(path);
    });
  }).then((_) {
    return router;
  });
}

/// contains navigation map and plugins, resolves requested paths to
/// instances of [Voyager]
class VoyagerRouter extends AbstractRouter<Voyager, VoyagerParam> {
  /// default constructor
  VoyagerRouter({this.voyagerFactory = _defaultFactory});
  final _plugins = <String, VoyagerPlugin>{};
  final _globalEntities = <String, dynamic>{};
  final _cache = <String, Voyager>{};

  /// voyager factory
  final VoyagerFactory voyagerFactory;

  /// register a plugin
  VoyagerRouter registerPlugin(VoyagerPlugin plugin) {
    _plugins[plugin.node] = plugin;
    return this;
  }

  /// register a global entity
  VoyagerRouter registerGlobalEntity(String key, dynamic value) {
    _globalEntities[key] = value;
    return this;
  }

  /// obtain a global entity by [key]
  dynamic getGlobalEntity(String key) {
    return _globalEntities[key];
  }

  /// register a [VoyagerPath] mapping
  void registerPath(VoyagerPath path) {
    registerBuilder(path.path, VoyagerBuilder(path: path, router: this));
  }

  /// register a [VoyagerConfig] mapping with a custom [ProgrammaticVoyagerFactory]
  void registerConfig<T extends Voyager>(
      String path, VoyagerConfig<T> voyagerConfig,
      [ProgrammaticVoyagerFactory<T>? voyagerFactory]) {
    registerBuilder(
        path,
        _ProgrammaticRouteBuilder(
            path: path,
            voyagerFactory: voyagerFactory,
            voyagerConfig: voyagerConfig,
            routerNG: this));
  }

  /// obtain registered plugins
  Map<String, VoyagerPlugin> getPlugins() {
    return _plugins;
  }

  /// lookup path
  Voyager? find(String path, {Voyager? parent, VoyagerArgument? argument}) {
    return outputFor(path,
        extras: VoyagerParam(parent: parent, argument: argument));
  }

  /// lookup path in cache
  Voyager? findCached(String routerPath) {
    var voyager = _cache[routerPath];
    if (voyager == null) {
      voyager = find(routerPath);
      if (voyager != null) {
        _cache[routerPath] = voyager;
      }
    }
    return voyager;
  }

  /// method's output should be passed to [MaterialApp.onGenerateRoute] or
  /// [CupertinoApp.onGenerateRoute]
  RouteFactory generator(
      {VoyagerRouteType routeType = VoyagerRouteType.material}) {
    return (RouteSettings settings) {
      final path = settings.name!;
      final builder = (BuildContext context) {
        var isWrappedWithRouter = false;

        // If App is not wrapped with RouterProvider we use
        // the current instance. this breaks hot reload until page
        // is off the stack as PageRoute will hold old router
        // reference
        try {
          isWrappedWithRouter =
              Provider.of<VoyagerRouter?>(context, listen: false) != null;
        } catch (_) {}

        dynamic argument;
        if (settings.arguments != null) {
          if (settings.arguments is VoyagerArgument) {
            argument = settings.arguments;
          } else {
            argument = VoyagerArgument(settings.arguments);
          }
        }

        return VoyagerWidget(
            path: path,
            router: isWrappedWithRouter ? null : this,
            argument: argument);
      };

      switch (routeType) {
        case VoyagerRouteType.material:
          return MaterialPageRoute<dynamic>(
              builder: builder, settings: settings);
        case VoyagerRouteType.cupertino:
          return CupertinoPageRoute<dynamic>(
              builder: builder, settings: settings);
      }
    };
  }
}

/// voyager route type
enum VoyagerRouteType {
  /// use when using [CupertinoApp]
  cupertino,

  /// use when using [MaterialApp]
  material
}

/// Mid value passed to [VoyagerBuilder] where it's
/// used to construct final [Voyager] instance
class VoyagerParam {
  /// default constructor
  VoyagerParam({this.parent, this.argument});

  /// parent voyager (if this is e.g. a nested widget)
  final Voyager? parent;

  /// argument coming from navigation or [VoyagerWidget]
  final VoyagerArgument? argument;
}

/// a builder that is registered at [VoyagerRouter]'s each path,
/// this creates [Voyager] from the config that is hidden behind the [path]
/// using all the plugins that are available in [VoyagerRouter]
class VoyagerBuilder extends OutputBuilder<Voyager, VoyagerParam> {
  /// default constructor
  VoyagerBuilder({required this.path, required this.router});

  /// path where this voyager builder is used
  final VoyagerPath path;

  /// router instance
  final VoyagerRouter router;

  @override
  Voyager outputFor(AbstractRouteContext abstractContext) {
    final allTheParams = Map<String, String>.from(abstractContext.getParams());
    final dynamic extras = abstractContext.getExtras();
    VoyagerArgument? argument;
    if (extras is VoyagerParam) {
      argument = extras.argument;
    }

    final context = VoyagerContext(
        path: abstractContext.url(),
        params: allTheParams,
        router: router,
        argument: argument);

    final config = VoyagerUtils.copyIt(path.config);
    VoyagerUtils.interpolateDynamic(config, context);

    final output = router.voyagerFactory(abstractContext, config);

    config.keys.forEach((String key) {
      if (key == Voyager.KEY_TYPE) {
        final dynamic type = config[key];
        assert(type is String,
            "Provided type value must be String but is $type instead!");
        output[Voyager.KEY_TYPE] = type;
      } else {
        final plugin = router._plugins[key];
        if (plugin != null) {
          plugin.outputFor(context, config[key], output);
        }
      }
    });

    output.lock();

    return output;
  }
}

class _ProgrammaticRouteBuilder<T extends Voyager>
    extends OutputBuilder<Voyager, VoyagerParam> {
  _ProgrammaticRouteBuilder(
      {required this.path,
      this.voyagerFactory,
      required this.voyagerConfig,
      required this.routerNG});
  final String path;
  final ProgrammaticVoyagerFactory<T>? voyagerFactory;
  final VoyagerConfig<T> voyagerConfig;
  final VoyagerRouter routerNG;

  @override
  Voyager outputFor(AbstractRouteContext abstractContext) {
    final allTheParams = Map<String, String>.from(abstractContext.getParams());

    final context = VoyagerContext(
        path: abstractContext.url(), params: allTheParams, router: routerNG);

    final newInstance = voyagerFactory != null
        ? voyagerFactory!(abstractContext, context)
        : _defaultProgrammaticFactory(abstractContext, context);

    // ignore: avoid_as
    voyagerConfig(context, newInstance as T);

    newInstance.lock();

    return newInstance;
  }
}

/// alias for creating programatic voyager instances
typedef VoyagerFactory<T extends Voyager> = T Function(
    AbstractRouteContext abstractContext, Map<String, dynamic> config);

Voyager _defaultFactory(
        AbstractRouteContext abstractContext, Map<String, dynamic> config) =>
    Voyager(
        path: abstractContext.url(),
        parent: abstractContext.getExtras().parent,
        config: config);

/// allows programmatic path specification
typedef VoyagerConfig<T extends Voyager> = void Function(
    VoyagerContext context, T voyager);

/// creates voyager instance, can be used to supply Voyager subclasses
typedef ProgrammaticVoyagerFactory<T extends Voyager> = T Function(
    AbstractRouteContext abstractContext, VoyagerContext context);

final ProgrammaticVoyagerFactory _defaultProgrammaticFactory =
    (abstractContext, context) => Voyager(
        path: abstractContext.url(),
        parent: abstractContext.getExtras().parent,
        config: <String, dynamic>{});
