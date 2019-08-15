// import 'package:flutter/widgets.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:voyager/src/router.dart';
// import 'disk_asset_bundle.dart';

void main() {
  // this doesn't work well with codemagic :_()
  // testWidgets('load paths from mock assets', (tester) async {
  //   final assetBundle = await tester.runAsync(
  //     () => DiskAssetBundle.loadGlob(['navigation.yaml'], from: "assets/"),
  //   );

  //   final paths = await loadPathsFromAssets("assets/navigation.yaml",
  //       assetBundle: assetBundle);

  //   expect(paths.length, 2);

  //   expect(
  //       paths.map((it) => (it.path)), containsAll(["/home", "/other/:title"]));
  // });

  // testWidgets('load paths from rootBundle', (tester) async {
  //   try {
  //     await loadPathsFromAssets("navigation.yaml");
  //   } catch (e) {
  //     // this should fail, see: https://github.com/flutter/flutter/issues/12999
  //     expect(e, isInstanceOf<FlutterError>());
  //     expect(
  //         (e as FlutterError).message, "Unable to load asset: navigation.yaml");
  //   }
  // });
}
