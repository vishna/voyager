import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// wrapper class for argument passed via navigator
/// or in the constructor of `VoyagerWidget`
class VoyagerArgument {
  VoyagerArgument(this.value);
  final dynamic value;
}

extension VoyagerArgumentExtension on BuildContext {
  VoyagerArgument get voyagerArgument =>
      Provider.of<VoyagerArgument>(this, listen: false);
}
