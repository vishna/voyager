import 'dart:convert';
import 'dart:io';

/// fixed version for predictable builds
const voyagerVersion = "master-7607723340-1";

/// fat jar baked on jitpack
const voyagerJarPath =
    "https://jitpack.io/com/github/vishna/voyager-codegen/cli/$voyagerVersion/cli-$voyagerVersion-all.jar";

const cacheDir = ".jarCache";
const savePath = "$cacheDir/voyager-codegen-$voyagerVersion.jar";

// ignore: avoid_void_async
void main(List<String> arguments) async {
  await Directory(cacheDir).create(recursive: true);
  if (FileSystemEntity.typeSync(savePath) == FileSystemEntityType.notFound) {
    print("Trying to download voyager-codegen-$voyagerVersion.jar ...");

    try {
      await downloadJar(voyagerJarPath, savePath);
      print("Downloaded voyager-codegen-$voyagerVersion.jar");
    } catch (_) {
      // wget gets the job done while dart based http file download errors 500 ¯\_(ツ)_/¯
      stderr.writeln(
          "Failed to download $voyagerJarPath \nPlease download the jar manually and save it to $savePath.\nOnce this is complete just rerun pub command.");
      exit(1);
    }
  }

  final process = await Process.start('java', ['-jar', savePath] + arguments);
  process.stdout.transform(utf8.decoder).listen((data) {
    print("$data".trim());
  });
}

Future<ProcessResult> downloadJar(String url, String target) async {
  return await Process.run('wget', [url, '-O', target]);
}
