import 'package:voyager/voyager.dart';

class RouterContext {
  RouterContext({
    required this.path,
    required this.params,
    required this.router,
    this.argument,
  });
  final Map<String, String> params;
  final String path;
  final Router router;
  final VoyagerArgument? argument;
}
