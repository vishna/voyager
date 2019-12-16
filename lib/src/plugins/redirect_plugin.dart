import 'package:voyager/voyager.dart';

class RedirectPlugin extends RouterPlugin {
  RedirectPlugin() : super(KEY);
  static const KEY = "redirect";

  @override
  void outputFor(RouterContext context, dynamic config, Voyager output) {
    if (!(config is String)) {
      return;
    }

    var targetUrl = config.toString();

    /// calculate combined parameters
    final originalUri = VoyagerUtils.fromPath(context.path);
    var targetUri = VoyagerUtils.fromPath(targetUrl);

    final combinedParameters = <String, String>{};
    combinedParameters.addAll(targetUri.queryParameters);
    combinedParameters.addAll(originalUri.queryParameters);
    targetUri = Uri(
        scheme: targetUri.scheme,
        host: targetUri.host,
        path: targetUri.path,
        queryParameters: combinedParameters);
    final query = targetUri.query;
    if (query.isNotEmpty) {
      targetUrl = "${targetUri.path}?$query";
    }

    final targetVoyager = context.router.find(targetUrl);
    output.merge(targetVoyager);
  }
}
