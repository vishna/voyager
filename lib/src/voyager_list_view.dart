import 'package:flutter/widgets.dart';
import 'voyager_argument.dart';
import 'voyager_stateless_widget.dart';

/// maps item instance to its id
typedef Identifier = String Function(dynamic item);

/// maps item type to a respective voyager path
typedef PathMapper = String Function(dynamic item);

/// Voyager backed ListView with stable ids.
/// You need to provide [Identifier] which will guarantee stable item IDs
/// across updates and [PathMapper] which will map object type to a relevant
/// voyager path. The item values are injected using [VoyagerArgument].
///
/// ValueKey(s) FTW: https://medium.com/flutter-community/elements-keys-and-flutters-performance-3ef15c90f607
/// ValueKey(s) + ListView sample: https://github.com/flutter/flutter/issues/21023#issuecomment-510950338
class VoyagerListView extends StatelessWidget {
  final Map<String, int> _idToIndex;
  final List<_VoyagerItem> _items;
  final ScrollController controller;

  VoyagerListView(List<dynamic> items, Identifier identifier,
      PathMapper pathMapper, this.controller)
      : _idToIndex = Map<String, int>(),
        _items = List<_VoyagerItem>(items.length) {
    final n = items.length;
    for (int index = 0; index < n; index++) {
      final item = items[index];
      final id = identifier(item);
      final path = pathMapper(item);
      _idToIndex[id] = index;
      _items[index] = _VoyagerItem(
          argument: VoyagerArgument(item), path: path, key: ValueKey(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.custom(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: controller,
      childrenDelegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final item = _items[index];
            return VoyagerStatelessWidget(
                path: item.path,
                useCache: true,
                argument: item.argument,
                key: item.key);
          },
          childCount: _items.length,
          findChildIndexCallback: (Key key) {
            final ValueKey valueKey = key;
            final String id = valueKey.value;
            return _idToIndex[id];
          }),
    );
  }
}

class _VoyagerItem {
  final VoyagerArgument argument;
  final ValueKey key;
  final String path;

  const _VoyagerItem({this.argument, this.path, this.key});
}
