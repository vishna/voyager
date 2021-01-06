import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// This class is a composite product of `RouterPlugin`s for the given router's path -
/// this means all the information resolved from the navigation file that is relevant to creating
/// new widget.
/// Once assembled the variables are locked - they can be read but you can't put more.
class Voyager {
  /// default constructor
  Voyager(
      {required this.path,
      required this.pathParams,
      this.parent,
      required Map<String, dynamic> config})
      : _config = Map<String, dynamic>.from(config);

  /// special node, type
  static const String KEY_TYPE = "type";

  /// parent voyager instance
  final Voyager? parent;
  final Map<String, dynamic> _config;
  final _output = <String, dynamic>{};

  final _onDispose = <VoidCallback>[];

  /// path of this voyager
  final String path;

  /// params of the path
  final Map<String, dynamic> pathParams;

  /// lockdown flag
  bool _locked = false;

  /// merges other [Voyager] instance into this one
  void merge(Voyager other) {
    if (_locked) {
      throw FlutterError("Voyager is in lockdown.");
    }
    _output.addAll(other._output);
    _config.addAll(other._config);
  }

  /// access field resolved by [VoyagerPlugin]
  dynamic operator [](String key) {
    final dynamic value = _output[key];
    if (value == nothing) {
      return null;
    }
    if (value != null) {
      return value;
    }

    return _config[key];
  }

  /// set field when accessing it from [VoyagerPlugin]
  operator []=(String key, dynamic value) {
    if (_locked) {
      throw FlutterError("Voyager is in lockdown.");
    }
    _output[key] = value;
  }

  /// register dispose callback
  void onDispose(VoidCallback callback) {
    _onDispose.add(callback);
  }

  /// dispose this voyager instance
  void dispose() {
    if (!_locked) {
      throw FlutterError("Can't dispose resources before Voyager is locked");
    }
    _onDispose.forEach((callback) => callback());
    _onDispose.clear();
    _output.clear();
    _config.clear();
  }

  /// lock this voyager instance
  void lock() {
    _locked = true;
  }

  /// Voyager's type
  String get type => this[KEY_TYPE];

  /// set voyager's type (works only )
  set type(String value) {
    this[KEY_TYPE] = value;
  }

  /// nothing
  static final VoyagerNothing nothing = VoyagerNothing._private();
}

/// nothingness, void, empty space
class VoyagerNothing {
  VoyagerNothing._private();
}

/// Voyager default extension on build context
extension VoyagerContextExtension on BuildContext {
  /// obtain a [Voyager] instance from the current [BuildContext]
  Voyager get voyager => Provider.of<Voyager>(this, listen: false);
}
