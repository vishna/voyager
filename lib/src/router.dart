import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:voyager/voyager.dart';
import 'package:yaml/yaml.dart';

List<RouterPath> loadPathsFromYamlSync(String yaml) {
  final YamlMap routerMap = loadYaml(yaml);
  final paths = <RouterPath>[];

  routerMap.keys.forEach((dynamic it) {
    paths.add(RouterPath.fromYaml(path: it, config: routerMap[it]));
  });

  return paths;
}

List<RouterPath> loadPathsFromJsonSync(String jsonString) {
  final Map<String, dynamic> routerMap = json.decode(jsonString);
  final paths = <RouterPath>[];

  routerMap.keys.forEach((it) {
    paths.add(RouterPath.fromMap(path: it, config: routerMap[it]));
  });

  return paths;
}

// e.g. "assets/navigation.yml"
Future<List<RouterPath>> loadPathsFromAssets(String path,
    {AssetBundle assetBundle}) async {
  assetBundle ??= rootBundle;
  final yaml = await assetBundle.loadString(path);
  return loadPathsFromYamlSync(yaml);
}

Future<List<RouterPath>> loadPathsFromString(String yaml) async {
  return compute(loadPathsFromYamlSync, yaml);
}

Future<List<RouterPath>> loadPathsFromJsonString(String json) async {
  return compute(loadPathsFromJsonSync, json);
}

Future<Router> loadRouter(
    Future<List<RouterPath>> paths, List<RouterPlugin> plugins,
    {VoyagerFactory voyagerFactory}) {
  final router = voyagerFactory != null
      ? Router(voyagerFactory: voyagerFactory)
      : Router();

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

class Router extends AbstractRouter<Voyager, RouteParam> {
  Router({this.voyagerFactory = _defaultFactory});
  final _plugins = <String, RouterPlugin>{};
  final _globalEntities = <String, dynamic>{};
  final _cache = <String, Voyager>{};
  final VoyagerFactory voyagerFactory;

  Router registerPlugin(RouterPlugin plugin) {
    _plugins[plugin.node] = plugin;
    return this;
  }

  Router registerGlobalEntity(String key, dynamic value) {
    _globalEntities[key] = value;
    return this;
  }

  dynamic getGlobalEntity(String key) {
    return _globalEntities[key];
  }

  void registerPath(RouterPath path) {
    registerBuilder(path.path, RouteBuilder(path: path, routerNG: this));
  }

  void registerConfig<T extends Voyager>(
      String path, VoyagerConfig<T> voyagerConfig,
      [ProgrammaticVoyagerFactory<T> voyagerFactory]) {
    registerBuilder(
        path,
        _ProgrammaticRouteBuilder(
            path: path,
            voyagerFactory: voyagerFactory,
            voyagerConfig: voyagerConfig,
            routerNG: this));
  }

  Map<String, RouterPlugin> getPlugins() {
    return _plugins;
  }

  Voyager find(String routerPath, {Voyager parent, VoyagerArgument argument}) {
    return outputFor(routerPath,
        extras: RouteParam(parent: parent, argument: argument));
  }

  Voyager findCached(String routerPath) {
    var voyager = _cache[routerPath];
    if (voyager == null) {
      voyager = find(routerPath);
      _cache[routerPath] = voyager;
    }
    return voyager;
  }

  static const int materialRoute = 0;
  static const int cupertinoRoute = 1;

  RouteFactory generator({int routeType = materialRoute}) {
    return (RouteSettings settings) {
      final path = settings.name;
      final builder = (BuildContext context) {
        var isWrappedWithRouter = false;

        // If App is not wrapped with RouterProvider we use
        // the current instance. this breaks hot reload until page
        // is off the stack as PageRoute will hold old router
        // reference
        try {
          isWrappedWithRouter =
              Provider.of<Router>(context, listen: false) != null;
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
        case materialRoute:
          return MaterialPageRoute<dynamic>(builder: builder);
        case cupertinoRoute:
          return CupertinoPageRoute<dynamic>(builder: builder);
        default:
          throw ArgumentError("routeType = $routeType not supported");
      }
    };
  }
}

class RouteParam {
  RouteParam({this.parent, this.argument});
  final Voyager parent;
  final VoyagerArgument argument;
}

class RouteBuilder extends OutputBuilder<Voyager, RouteParam> {
  RouteBuilder({this.path, this.routerNG});
  final RouterPath path;
  final Router routerNG;

  @override
  Voyager outputFor(AbstractRouteContext abstractContext) {
    final allTheParams = Map<String, String>.from(abstractContext.getParams());
    final dynamic extras = abstractContext.getExtras();
    VoyagerArgument argument;
    if (extras is RouteParam) {
      argument = extras.argument;
    }

    final context = RouterContext(
        path: abstractContext.url(),
        params: allTheParams,
        router: routerNG,
        argument: argument);

    final config = VoyagerUtils.copyIt(path.config);
    VoyagerUtils.interpolateDynamic(config, context);

    final output = routerNG.voyagerFactory(abstractContext, config);

    config.keys.forEach((String key) {
      if (key == Voyager.KEY_TYPE) {
        final dynamic type = config[key];
        assert(type is String,
            "Provided type value must be String but is $type instead!");
        output[Voyager.KEY_TYPE] = type;
      } else {
        final plugin = routerNG._plugins[key];
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
    extends OutputBuilder<Voyager, RouteParam> {
  _ProgrammaticRouteBuilder(
      {this.path, this.voyagerFactory, this.voyagerConfig, this.routerNG});
  final String path;
  final ProgrammaticVoyagerFactory<T> voyagerFactory;
  final VoyagerConfig<T> voyagerConfig;
  final Router routerNG;

  @override
  Voyager outputFor(AbstractRouteContext abstractContext) {
    final allTheParams = Map<String, String>.from(abstractContext.getParams());

    final context = RouterContext(
        path: abstractContext.url(), params: allTheParams, router: routerNG);

    final newInstance = voyagerFactory != null
        ? voyagerFactory(abstractContext, context)
        : _defaultProgrammaticFactory(abstractContext, context);

    voyagerConfig(context, newInstance);

    newInstance.lock();

    return newInstance;
  }
}

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
    RouterContext context, T voyager);

/// creates voyager instance, can be used to supply Voyager subclasses
typedef ProgrammaticVoyagerFactory<T extends Voyager> = T Function(
    AbstractRouteContext abstractContext, RouterContext context);

final ProgrammaticVoyagerFactory _defaultProgrammaticFactory =
    (abstractContext, context) => Voyager(
        path: abstractContext.url(),
        parent: abstractContext.getExtras().parent,
        config: <String, dynamic>{});
