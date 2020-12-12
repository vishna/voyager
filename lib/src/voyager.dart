import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// This class is a composite product of `RouterPlugin`s for the given router's path -
/// this means all the information resolved from the navigation file that is relevant to creating
/// new widget.
/// Once assembled the variables are locked - they can be read but you can't put more.
///
/// Developer might choose to use `storage` to dynamically put any variables that should be available
/// to anyone having access to that instance of `Voyager`
class Voyager {
  Voyager(
      {required this.path, this.parent, required Map<String, dynamic> config})
      : _config = Map<String, dynamic>.from(config);
  static const String KEY_TYPE = "type";

  final Voyager? parent;
  final Map<String, dynamic> _config;
  final _output = <String, dynamic>{};
  final storage = <String, dynamic>{};
  final _onDispose = <OnDispose>[];
  final String path;
  bool _locked = false;

  void merge(Voyager other) {
    if (_locked) {
      throw FlutterError("Voyager is in lockdown.");
    }
    _output.addAll(other._output);
    _config.addAll(other._config);
  }

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

  operator []=(String key, dynamic value) {
    if (_locked) {
      throw FlutterError("Voyager is in lockdown.");
    }
    _output[key] = value;
  }

  void onDispose(OnDispose callback) {
    _onDispose.add(callback);
  }

  void dispose() {
    if (!_locked) {
      throw FlutterError("Can't dispose resources before Voyager is locked");
    }
    _onDispose.forEach((callback) => callback());
    _onDispose.clear();
    _output.clear();
    _config.clear();
  }

  void lock() {
    _locked = true;
  }

  String get type => this[KEY_TYPE];
  set type(String value) {
    this[KEY_TYPE] = value;
  }

  static final Nothing nothing = Nothing._private();
}

class Nothing {
  Nothing._private();
}

extension VoyagerContextExtension on BuildContext {
  Voyager get voyager => Provider.of<Voyager>(this, listen: false);
}

typedef OnDispose = void Function();
