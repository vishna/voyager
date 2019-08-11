import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:voyager/src/voyager_widget.dart';
import 'package:voyager/voyager.dart';
import 'package:yaml/yaml.dart';

import 'utils.dart';
import 'voyager.dart';
import 'router_path.dart';
import 'router_plugin.dart';
import 'router_context.dart';
import 'abstract_router.dart';

List<RouterPath> _loadYaml(String yaml) {
  final routerMap = loadYaml(yaml) as YamlMap;
  final paths = new List<RouterPath>();

  routerMap.keys.forEach((it) {
    paths.add(RouterPath.fromYaml(path: it, config: routerMap[it]));
  });

  return paths;
}

List<RouterPath> _loadJson(String jsonString) {
  final routerMap = json.decode(jsonString) as Map<String, dynamic>;
  final paths = new List<RouterPath>();

  routerMap.keys.forEach((it) {
    paths.add(RouterPath.fromMap(path: it, config: routerMap[it]));
  });

  return paths;
}

// e.g. "assets/navigation.yml"
Future<List<RouterPath>> loadPathsFromAssets(String path) async {
  final yaml = await rootBundle.loadString(path);
  return _loadYaml(yaml);
}

Future<List<RouterPath>> loadPathsFromString(String yaml) async {
  return compute(_loadYaml, yaml);
}

Future<List<RouterPath>> loadPathsFromJsonString(String json) async {
  return compute(_loadJson, json);
}

Future<RouterNG> loadRouter(
    Future<List<RouterPath>> paths, List<RouterPlugin> plugins) {
  final router = RouterNG();

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

class RouterNG extends AbstractRouter<Voyager, RouteParam> {
  final _plugins = Map<String, RouterPlugin>();
  final _globalEntities = Map<String, dynamic>();
  final _cache = Map<String, Voyager>();

  RouterNG registerPlugin(RouterPlugin plugin) {
    _plugins[plugin.node] = plugin;
    return this;
  }

  RouterNG registerGlobalEntity(String key, dynamic value) {
    _globalEntities[key] = value;
    return this;
  }

  dynamic getGlobalEntity(String key) {
    return _globalEntities[key];
  }

  void registerPath(RouterPath path) {
    registerBuilder(path.path, RouteBuilder(path: path, routerNG: this));
  }

  Map<String, RouterPlugin> getPlugins() {
    return _plugins;
  }

  Voyager find(String routerPath, {Voyager parent}) {
    return outputForExtras(routerPath, RouteParam(parent: parent));
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
      String path = settings.name;
      final builder = (context) {
        bool isWrappedWithRouter = false;

        // If App is not wrapped with RouterProvider we use
        // the current instance. this breaks hot reload until page
        // is off the stack as PageRoute will hold old router
        // reference
        try {
          isWrappedWithRouter = Provider.of<RouterNG>(context) != null;
        } catch (t) {}

        var argument;
        if (settings.arguments != null) {
          argument = VoyagerArgument(settings.arguments);
        }

        return VoyagerWidget(
            path: path,
            router: isWrappedWithRouter ? null : this,
            argument: argument);
      };

      switch (routeType) {
        case materialRoute:
          return MaterialPageRoute(builder: builder);
        case cupertinoRoute:
          return CupertinoPageRoute(builder: builder);
        default:
          throw ArgumentError("routeType = $routeType not supported");
      }
    };
  }
}

class RouteParam {
  final Voyager parent;
  final dynamic data;

  RouteParam({this.parent, this.data});
}

class RouteBuilder extends OutputBuilder<Voyager, RouteParam> {
  final RouterPath path;
  final RouterNG routerNG;

  RouteBuilder({this.path, this.routerNG});

  @override
  Voyager outputFor(AbstractRouteContext abstractContext) {
    final allTheParams = Map<String, String>.from(abstractContext.getParams());

    final context = RouterContext(
        path: abstractContext.url(), params: allTheParams, router: routerNG);

    final config = VoyagerUtils.copyIt(path.config);
    VoyagerUtils.interpolateDynamic(config, context);

    Voyager parent = abstractContext.getExtras().parent;

    final output =
        Voyager(path: abstractContext.url(), parent: parent, config: config);

    config.keys.forEach((key) {
      final plugin = routerNG._plugins[key];
      if (plugin != null) {
        plugin.outputFor(context, config[key], output);
      }
    });

    output.lock();

    return output;
  }
}
