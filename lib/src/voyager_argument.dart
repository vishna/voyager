import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:voyager/voyager.dart';

/// wrapper class for argument passed via navigator
/// or in the constructor of `VoyagerWidget`
class VoyagerArgument extends Equatable {
  /// default constructor
  const VoyagerArgument(this.value);

  /// unwrapped value of the argument
  final dynamic value;

  @override
  List<Object?> get props => [value];

  @override
  bool? get stringify => true;

  /// [VoyagerPage] serialization adapter
  static final adapter =
      VoyagerAdapter<VoyagerArgument>(serialize: (dynamic argument) {
    return <String, dynamic>{"value": VoyagerAdapter.toJson(argument.value)};
  }, deserialize: (json) {
    final dynamic value =
        // ignore: avoid_as
        VoyagerAdapter.fromJson(json["value"] as Map<String, dynamic>?);
    return VoyagerArgument(value);
  });
}

/// allows access to voyager argument from build context
extension VoyagerArgumentExtension on BuildContext {
  /// voyagerArgument
  dynamic? get voyagerArgument =>
      Provider.of<VoyagerArgument?>(this, listen: false)?.value;
}
