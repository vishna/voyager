import 'router.dart';

class RouterContext {
  RouterContext({this.path, this.params, this.router});
  final Map<String, String> params;
  final String path;
  final RouterNG router;
}
