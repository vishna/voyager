import 'package:voyager/voyager.dart';

class RouterContext {
  RouterContext({this.path, this.params, this.router, this.argument});
  final Map<String, String> params;
  final String path;
  final Router router;
  final VoyagerArgument argument;
}
