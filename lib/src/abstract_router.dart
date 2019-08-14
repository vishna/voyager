import 'package:voyager/src/utils.dart';

/// Base router implementation for given output/parameter.
/// Ported from eyeem/router OSS project and improved upon.
///
/// @param <O> the Output class
/// @param <P> the Params class
abstract class AbstractRouter<O, P> {
  /// Default params shared across all router paths
  final _globalParams = new Map<String, dynamic>();

  final _routes = Map<String, OutputBuilder<O, P>>();
  final _wildcardRoutes = Map<String, OutputBuilder<O, P>>();
  final _cachedRoutes = Map<String, RouterParams>();

  /// Map a URL to an OutputBuilder
  ///
  /// @param format  The URL being mapped; for example, "users/:id" or "groups/:id/topics/:topic_id"
  /// @param options The OutputBuilder that creates an output if the given format is matched
  void registerBuilder(String format, OutputBuilder<O, P> builder) {
    if (builder == null) {
      throw ArgumentError("You need a non null builder for $format");
    }

    if (VoyagerUtils.isWildcard(format)) {
      this._wildcardRoutes[format] = builder;
    } else {
      this._routes[format] = builder;
    }
  }

  /// Open a map'd URL set using {@link #map(String, Class)} or {@link #map(String, OutputBuilder)}
  ///
  /// @param url The URL; for example, "users/16" or "groups/5/topics/20"
  O outputFor(String url) {
    return this.outputForExtras(url, null);
  }

  /// Open a map'd URL set using {@link #map(String, Class)} or {@link #map(String, BundleBuilder)}
  ///
  /// @param url     The URL; for example, "users/16" or "groups/5/topics/20"
  /// @param extras  The {@link P} which contains the extra params to be assigned to the generated {@link O}
  O outputForExtras(String url, P extras) {
    final params = paramsForUrl(url);
    final outputBuilder = params.outputBuilder;
    if (outputBuilder != null) {
      // make params copy
      final openParams = Map<String, String>.from(params.openParams);

      // add global params to path specific params
      for (MapEntry<String, dynamic> entry in _globalParams.entries) {
        if (!openParams.containsKey(entry.key)) {
          // do not override locally set keys
          openParams[entry.key] = entry.value.toString();
        }
      }

      final routeContext = AbstractRouteContext<P>(openParams, extras, url);

      return outputBuilder.outputFor(routeContext);
    }

    return null;
  }

  /// Takes a url (i.e. "/users/16/hello") and breaks it into a {@link RouterParams} instance where
  /// each of the parameters (like ":id") has been parsed.
  RouterParams<O, P> paramsForUrl(String url) {
    final String cleanedUrl = VoyagerUtils.cleanUrl(url);

    Uri parsedUri = Uri.parse("http://tempuri.org/" + cleanedUrl);

    String urlPath = parsedUri.path.substring(1);

    if (this._cachedRoutes[cleanedUrl] != null) {
      return this._cachedRoutes[cleanedUrl];
    }

    final givenParts = urlPath.split("/");

    // first check for matching non wildcard routes just to avoid being shadowed
    // by more generic wildcard routes
    RouterParams<O, P> routerParams =
        _checkRouteSet(this._routes.entries, givenParts, false);

    // still null, try matching to any wildcard routes
    if (routerParams == null) {
      routerParams =
          _checkRouteSet(this._wildcardRoutes.entries, givenParts, true);
    }

    if (routerParams == null) {
      throw new RouteNotFoundException("No route found for url $url");
    }

    routerParams.openParams.addAll(parsedUri.queryParameters);

    this._cachedRoutes[cleanedUrl] = routerParams;
    return routerParams;
  }

  RouterParams<O, P> _checkRouteSet(
      Iterable<MapEntry<String, OutputBuilder<O, P>>> routeSet,
      List<String> givenParts,
      bool isWildcard) {
    RouterParams<O, P> routerParams;

    for (MapEntry<String, OutputBuilder<O, P>> entry in routeSet) {
      String routerUrl = VoyagerUtils.cleanUrl(entry.key);
      OutputBuilder<O, P> outputBuilder = entry.value;
      List<String> routerParts = routerUrl.split("/");

      if (!isWildcard && (routerParts.length != givenParts.length)) {
        continue;
      }

      Map<String, String> givenParams =
          _urlToParamsMap(givenParts, routerParts, isWildcard);
      if (givenParams == null) {
        continue;
      }

      routerParams = new RouterParams<O, P>();
      routerParams.openParams = givenParams;
      routerParams.outputBuilder = outputBuilder;
      break;
    }

    return routerParams;
  }

  AbstractRouter globalParam(String key, dynamic object) {
    _globalParams[key] = object;
    return this;
  }

  void clearCache() {
    _cachedRoutes.clear();
  }
}

/// Thrown if a given route is not found.
class RouteNotFoundException implements Exception {
  final String cause;
  const RouteNotFoundException(this.cause);
}

/// The class used when you want to map a function (given in `run`)
/// to a Router URL.
abstract class OutputBuilder<O, P> {
  O outputFor(AbstractRouteContext<P> context);
}

/// The class supplied to custom callbacks to describe the route route
class AbstractRouteContext<P> {
  Map<String, String> _params;
  P _extras;
  String _url;

  AbstractRouteContext(Map<String, String> params, P extras, String url) {
    _params = params;
    _extras = extras;
    _url = url;
  }

  /// Returns the route parameters as specified by the configured route
  Map<String, String> getParams() {
    return _params;
  }

  /// Returns the extras supplied with the route
  P getExtras() {
    return _extras;
  }

  /// Returns the url that is being resolved by the router
  String url() {
    return _url;
  }
}

class RouterParams<O, P> {
  OutputBuilder<O, P> outputBuilder;
  Map<String, String> openParams;
}

/// @param givenUrlSegments  An array representing the URL path attempting to be opened (i.e. ["users", "42"])
/// @param routerUrlSegments An array representing a possible URL match for the router (i.e. ["users", ":id"])
/// @param hasWildcard       Tells whether there is a :wildcard: param or not
/// @return A map of URL parameters if it's a match (i.e. {"id" => "42"}) or null if there is no match
Map<String, String> _urlToParamsMap(List<String> givenUrlSegments,
    List<String> routerUrlSegments, bool hasWildcard) {
  final formatParams = Map<String, String>();
  for (int routerIndex = 0, givenIndex = 0;
      routerIndex < routerUrlSegments.length &&
          givenIndex < givenUrlSegments.length;
      routerIndex++) {
    String routerPart = routerUrlSegments[routerIndex];
    String givenPart = givenUrlSegments[givenIndex];

    if (routerPart.length > 0 && routerPart[0] == ':') {
      String key = routerPart.substring(1, routerPart.length);

      // (1) region standard router behavior
      if (!hasWildcard) {
        formatParams[key] = givenPart;
        givenIndex++;
        continue;
      }

      // (2) first we check if param is indeed a wildcard param
      bool isWildcard = false;
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
      String nextRouterPart = (routerIndex + 1) < routerUrlSegments.length
          ? routerUrlSegments[routerIndex + 1]
          : null;

      // we need to eat everything up till next recognizable path
      // e.g. :whatever:/:id should be forbidden thus the following check
      if (!VoyagerUtils.isNullOrBlank(nextRouterPart) &&
          nextRouterPart[0] == ':') {
        throw StateError(
            "Wildcard parameter $routerPart cannot be directly followed by a parameter $nextRouterPart");
      }

      // (5) all is good, it's time to eat some segments
      final segments = List<String>();
      for (int i = givenIndex; i < givenUrlSegments.length; i++) {
        String tmpPart = givenUrlSegments[i];
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
