import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// wrapper class for argument passed via navigator
/// or in the constructor of `VoyagerWidget`
class VoyagerArgument {
  /// default constructor
  VoyagerArgument(this.value);

  /// unwrapped value of the argument
  final dynamic value;
}

/// allows access to voyager argument from build context
extension VoyagerArgumentExtension on BuildContext {
  /// voyagerArgument
  VoyagerArgument? get voyagerArgument =>
      Provider.of<VoyagerArgument?>(this, listen: false);
}
