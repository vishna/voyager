import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/src/router.dart';
import 'disk_asset_bundle.dart';

// ignore_for_file: avoid_as

void main() {
  testWidgets('load paths from mock assets', (tester) async {
    final assetBundle = await tester.runAsync(
      () => DiskAssetBundle.loadGlob(['navigation.yaml'], from: pathPrefix()),
    );

    final paths = await loadPathsFromAssets("${pathPrefix()}/navigation.yaml",
        assetBundle: assetBundle);

    expect(paths.length, 2);

    expect(paths.map((it) => it.path),
        containsAll(<String>["/home", "/other/:title"]));
  });

  testWidgets('load paths from rootBundle', (tester) async {
    await tester.runAsync(() async {
      try {
        await loadPathsFromAssets("${pathPrefix()}/navigation.yaml");
      } catch (e) {
        expect(e, isInstanceOf<FlutterError>());
        expect((e as FlutterError).message,
            "Unable to load asset: ${pathPrefix()}/navigation.yaml");
      }
    });
  });
}
