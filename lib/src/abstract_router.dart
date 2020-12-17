import 'package:voyager/voyager.dart';

/// Base router implementation for given output/parameter.
/// Ported from eyeem/router OSS project and improved upon.
///
/// @param <O> the Output class
/// @param <P> the Params class
abstract class AbstractRouter<O, P> {
  /// Default params shared across all router paths
  final _globalParams = <String, dynamic>{};

  final _routes = <String, OutputBuilder<O, P>>{};
  final _wildcardRoutes = <String, OutputBuilder<O, P>>{};
  final _cachedRoutes = <String, RouterParams<O, P>>{};

  /// Map a URL to an OutputBuilder
  ///
  /// @param format  The URL being mapped; for example, "users/:id" or "groups/:id/topics/:topic_id"
  /// @param options The OutputBuilder that creates an output if the given format is matched
  void registerBuilder(String format, OutputBuilder<O, P> builder) {
    if (VoyagerUtils.isWildcard(format)) {
      _wildcardRoutes[format] = builder;
    } else {
      _routes[format] = builder;
    }
  }

  /// Open a map'd URL set using {@link #map(String, Class)} or {@link #map(String, BundleBuilder)}
  ///
  /// [path]    for example, "users/16" or "groups/5/topics/20"
  /// [extras]  The {@link P} which contains the extra params to be assigned to the generated {@link O}
  O outputFor(String path, {P? extras}) {
    final params = paramsForUrl(path);
    final outputBuilder = params.outputBuilder;

    // make params copy
    final openParams = Map<String, String>.from(params.openParams);

    // add global params to path specific params
    for (final entry in _globalParams.entries) {
      if (!openParams.containsKey(entry.key)) {
        // do not override locally set keys
        openParams[entry.key] = entry.value.toString();
      }
    }

    final routeContext = AbstractRouteContext<P>(openParams, extras, path);

    return outputBuilder.outputFor(routeContext);
  }

  /// Takes a url (i.e. "/users/16/hello") and breaks it into a {@link RouterParams} instance where
  /// each of the parameters (like ":id") has been parsed.
  RouterParams<O, P> paramsForUrl(String url) {
    final cleanedUrl = VoyagerUtils.cleanUrl(url);

    final parsedUri = Uri.parse("http://tempuri.org/" + cleanedUrl);

    final urlPath = parsedUri.path.substring(1);

    if (_cachedRoutes[cleanedUrl] != null) {
      return _cachedRoutes[cleanedUrl]!;
    }

    final givenParts = urlPath.split("/");

    // first check for matching non wildcard routes just to avoid being shadowed
    // by more generic wildcard routes
    var routerParams = _checkRouteSet(_routes.entries, givenParts, false);

    // still null, try matching to any wildcard routes
    routerParams ??= _checkRouteSet(_wildcardRoutes.entries, givenParts, true);

    if (routerParams == null) {
      throw RouteNotFoundException("No route found for url $url");
    }

    routerParams.openParams.addAll(parsedUri.queryParameters);

    _cachedRoutes[cleanedUrl] = routerParams;
    return routerParams;
  }

  RouterParams<O, P>? _checkRouteSet(
      Iterable<MapEntry<String, OutputBuilder<O, P>>> routeSet,
      List<String> givenParts,
      bool isWildcard) {
    RouterParams<O, P>? routerParams;

    for (final entry in routeSet) {
      final routerUrl = VoyagerUtils.cleanUrl(entry.key);
      final outputBuilder = entry.value;
      final routerParts = routerUrl.split("/");

      if (!isWildcard && (routerParts.length != givenParts.length)) {
        continue;
      }

      final givenParams = _urlToParamsMap(givenParts, routerParts, isWildcard);
      if (givenParams == null) {
        continue;
      }

      routerParams = RouterParams<O, P>(
        openParams: givenParams,
        outputBuilder: outputBuilder,
      );
      break;
    }

    return routerParams;
  }

  /// adds a global param accessible to anyone having
  /// a hold of this router instance
  AbstractRouter globalParam(String key, dynamic object) {
    _globalParams[key] = object;
    return this;
  }

  /// clears cache
  void clearCache() {
    _cachedRoutes.clear();
  }
}

/// Thrown if a given route is not found.
class RouteNotFoundException implements Exception {
  /// default constructor
  const RouteNotFoundException(this.cause);

  /// cause of the exception
  final String cause;
}

/// The class used when you want to map a function (given in `run`)
/// to a Router URL.
abstract class OutputBuilder<O, P> {
  /// returns [O] based on the given input [AbstractRouteContext<P>]
  O outputFor(AbstractRouteContext<P> abstractContext);
}

/// The class supplied to custom callbacks to describe the route route
class AbstractRouteContext<P> {
  /// default constructor
  const AbstractRouteContext(this._params, this._extras, this._url);

  final Map<String, String> _params;
  final P? _extras;
  final String _url;

  /// Returns the route parameters as specified by the configured route
  Map<String, String> getParams() {
    return _params;
  }

  /// Returns the extras supplied with the route
  P? getExtras() {
    return _extras;
  }

  /// Returns the url that is being resolved by the router
  String url() {
    return _url;
  }
}

/// class containg broken down parameters and builder, a result of path
/// lookup
class RouterParams<O, P> {
  /// default constructor
  RouterParams({required this.outputBuilder, required this.openParams});

  /// output builder
  final OutputBuilder<O, P> outputBuilder;

  /// open params
  final Map<String, String> openParams;
}

/// @param givenUrlSegments  An array representing the URL path attempting to be opened (i.e. ["users", "42"])
/// @param routerUrlSegments An array representing a possible URL match for the router (i.e. ["users", ":id"])
/// @param hasWildcard       Tells whether there is a :wildcard: param or not
/// @return A map of URL parameters if it's a match (i.e. {"id" => "42"}) or null if there is no match
Map<String, String>? _urlToParamsMap(List<String> givenUrlSegments,
    List<String> routerUrlSegments, bool hasWildcard) {
  final formatParams = <String, String>{};
  for (var routerIndex = 0, givenIndex = 0;
      routerIndex < routerUrlSegments.length &&
          givenIndex < givenUrlSegments.length;
      routerIndex++) {
    final routerPart = routerUrlSegments[routerIndex];
    final givenPart = givenUrlSegments[givenIndex];

    if (routerPart.isNotEmpty && routerPart[0] == ':') {
      var key = routerPart.substring(1, routerPart.length);

      // (1) region standard router behavior
      if (!hasWildcard) {
        formatParams[key] = givenPart;
        givenIndex++;
        continue;
      }

      // (2) first we check if param is indeed a wildcard param
      var isWildcard = false;
      if (key[key.length - 1] == ':') {
        key = key.substring(0, key.length - 1);
        isWildcard = true;
      }

      // (3) if it's not, just do standard processing --> (1)
      if (!isWildcard) {
        formatParams[key] = givenPart;
        givenIndex++;
        continue;
      }

      // (4) check remaining segments before consuming wildcard parameter
      final nextRouterPart = (routerIndex + 1) < routerUrlSegments.length
          ? routerUrlSegments[routerIndex + 1]
          : null;

      // we need to eat everything up till next recognizable path
      // e.g. :whatever:/:id should be forbidden thus the following check
      if (!VoyagerUtils.isNullOrBlank(nextRouterPart) &&
          nextRouterPart![0] == ':') {
        throw StateError(
            "Wildcard parameter $routerPart cannot be directly followed by a parameter $nextRouterPart");
      }

      // (5) all is good, it's time to eat some segments
      final segments = <String>[];
      for (var i = givenIndex; i < givenUrlSegments.length; i++) {
        final tmpPart = givenUrlSegments[i];
        if (tmpPart == nextRouterPart) {
          break;
        } else {
          segments.add(tmpPart);
        }
      }

      // (6) put it all assembled as a wildcard param
      formatParams[key] = segments.join("/");
      givenIndex += segments.length;
      continue;
      // endregion
    }

    if (routerPart != givenPart) {
      return null;
    }
    givenIndex++; // casual increment
  }

  return formatParams;
}
