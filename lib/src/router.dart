import 'package:angel_route/angel_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:voyager/src/voyager_widget.dart';
import 'package:yaml/yaml.dart';

import 'utils.dart';
import 'voyager.dart';
import 'router_path.dart';
import 'router_plugin.dart';
import 'router_context.dart';

List<RouterPath> _loadYaml(String yaml) {
  final routerMap = loadYaml(yaml) as YamlMap;
  final paths = new List<RouterPath>();

  routerMap.keys.forEach((it) {
    paths.add(RouterPath.fromYaml(path: it, config: routerMap[it]));
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

class RouterNG extends Router<RouterPath> {
  final _plugins = Map<String, RouterPlugin>();
  final _globalParams = Map<String, dynamic>();
  final _globalEntities = Map<String, dynamic>();

  RouterNG registerPlugin(RouterPlugin plugin) {
    _plugins[plugin.node] = plugin;
    return this;
  }

  RouterNG registerGlobalParam(String key, dynamic value) {
    if (!value is String &&
        !value is int &&
        !value is double &&
        !value is bool) {
      throw ArgumentError(
          "${value?.runtimeType} is not suitable for global param");
    }

    _globalParams[key] = value;
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
    addRoute("GET", path.path, path);
  }

  Voyager find(String routerPath, {Voyager parent}) {
    Uri uri = Uri.parse("https://www.flutter.dev$routerPath");
    final allTheParams = Map<String, dynamic>();

    final result = resolveAbsolute(uri.path).first;

    allTheParams.addAll(uri.queryParameters);

    if (result == null) {
      return null;
    }

    final path = result.allHandlers.first;

    if (path == null) {
      return null;
    }

    allTheParams.addAll(result.allParams);

    // include global params
    allTheParams.addAll(this._globalParams);

    final context =
        RouterContext(path: path.path, params: allTheParams, router: this);

    final config = VoyagerUtils.copyIt(path.config);
    VoyagerUtils.interpolateDynamic(config, context);

    final output = Voyager(parent: parent, config: config);

    config.keys.forEach((key) {
      final plugin = _plugins[key];
      if (plugin != null) {
        plugin.outputFor(context, config[key], output);
      }
    });

    output.lock();

    return output;
  }

  RouteFactory generator() {
    return (RouteSettings settings) {
      String path = settings.name;
      return MaterialPageRoute(builder: (context) {
        bool isWrappedWithRouter = false;

        try {
          isWrappedWithRouter = Provider.of<RouterNG>(context) != null;
        } catch (t) {}

        // If MaterialApp is not wrapped with RouterProvider we use
        // the current instance. this breaks hot reload until page
        // is off the stack as MaterialPageRoute will hold old router
        // reference
        return VoyagerWidget(
            path: path, router: isWrappedWithRouter ? null : this);
      });
    };
  }
}
