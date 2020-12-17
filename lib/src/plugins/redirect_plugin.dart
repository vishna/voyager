import 'package:voyager/voyager.dart';

/// redirect plugin
class RedirectPlugin extends VoyagerPlugin {
  /// default constructor
  const RedirectPlugin() : super(KEY);

  /// plugin node name
  static const KEY = "redirect";

  @override
  void outputFor(VoyagerContext context, dynamic config, Voyager output) {
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
    output.merge(targetVoyager!);
  }
}
