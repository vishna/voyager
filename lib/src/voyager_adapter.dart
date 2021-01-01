// ignore_for_file: avoid_as
import 'dart:convert';

import 'package:voyager/voyager.dart';

/// serializes and deserializes given type
class VoyagerAdapter<T> {
  /// default constructor
  const VoyagerAdapter({required this.serialize, required this.deserialize});

  /// runtime type of serialized/deserialized type
  Type get type => T;

  /// serialize item to a json encodable map
  final Map<String, dynamic> Function(dynamic) serialize;

  /// parse json encodable map to an instance
  final dynamic Function(Map<String, dynamic>) deserialize;
  static const _TYPE_SERIALIZABLE = "serializable";

  static final _adapterByType = <Type, VoyagerAdapter>{};
  static final _adapterByTypeStr = <String, VoyagerAdapter>{};

  /// registers adapter globally
  static void register(VoyagerAdapter adapter) {
    _init();
    assert(adapter.type != dynamic);
    assert(adapter.type.toString() != _TYPE_SERIALIZABLE);
    _adapterByType[adapter.type] = adapter;
    _adapterByTypeStr[adapter.type.toString()] = adapter;
  }

  /// converts instance to json
  static Map<String, dynamic>? toJson(dynamic? item) {
    _init();
    if (item == null) {
      return null;
    }
    final adapter = _adapterByType[item.runtimeType];
    if (adapter == null) {
      try {
        jsonEncode(item); // check if item can be encoded
        return <String, dynamic>{
          "type": _TYPE_SERIALIZABLE,
          "data": item,
        };
      } catch (_) {
        throw StateError(
            "Missing VoyagerAdapter type `${item.runtimeType}`=$item");
      }
    }
    return <String, dynamic>{
      "type": item.runtimeType.toString(),
      "data": adapter.serialize(item)
    };
  }

  /// converts json to an instance
  static dynamic? fromJson(Map<String, dynamic>? json) {
    _init();
    if (json == null) {
      return null;
    }
    final typeStr = json['type'] as String?;
    if (json['type'] == _TYPE_SERIALIZABLE) {
      return json['data'];
    }
    final adapter = _adapterByTypeStr[typeStr];
    if (adapter == null) {
      throw StateError("Missing VoyagerAdapter for type `$typeStr` in $json");
    }
    if (json['data'] == null) {
      throw StateError("Missing field `data` in $json");
    }
    return adapter.deserialize(json['data']);
  }

  static bool _wasInitialized = false;

  static void _init() {
    if (_wasInitialized) {
      return;
    }
    _wasInitialized = true;
    register(VoyagerPage.adapter);
    register(VoyagerStack.adapter);
    register(VoyagerArgument.adapter);
  }
}
