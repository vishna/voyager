import 'router.dart';

class RouterContext {
  final Map<String, String> params;
  final String path;
  final RouterNG router;

  RouterContext({this.path, this.params, this.router});
}
