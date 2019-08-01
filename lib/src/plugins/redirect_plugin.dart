import '../router_context.dart';
import '../../voyager.dart';

class RedirectPlugin extends RouterPlugin {
  static const KEY = "redirect";

  RedirectPlugin() : super(KEY);

  @override
  void outputFor(RouterContext context, config, Voyager output) {
    if (!(config is String)) return;

    String targetUrl = config.toString();

    /// calculate combined parameters
    try {
      Uri originalUri = VoyagerUtils.fromPath(context.path);
      Uri targetUri = VoyagerUtils.fromPath(targetUrl);

      final combinedParameters = Map<String, String>();
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
    } catch (e) {
      print(e);
    }

    Voyager targetVoyager = context.router.find(targetUrl);
    output.merge(targetVoyager);
  }
}
