import 'package:voyager/voyager.dart';

/// voyager context, accessible for plugins, contains relevant information
class VoyagerContext {
  /// default constructor
  const VoyagerContext({
    required this.path,
    required this.params,
    required this.router,
    this.argument,
  });

  /// resolved path (and non path parameters) parameters
  final Map<String, String> params;

  /// path
  final String path;

  /// router instance
  final VoyagerRouter router;

  /// argument
  final VoyagerArgument? argument;
}
