import 'dart:convert';
import 'dart:io';

/// fixed version for predictable builds
const voyagerVersion = "master-21624d082d-1";

/// fat jar baked on jitpack
const voyagerJarPath =
    "https://www.jitpack.io/com/github/vishna/voyager-codegen/cli/$voyagerVersion/cli-$voyagerVersion-all.jar";

const cacheDir = ".jarCache";
const savePath = "$cacheDir/voyager-codegen-$voyagerVersion.jar";

const MISSING_JDK_INFO = """

OpenJDK required by this code generator:

*-----------------------------------*
|     https://adoptopenjdk.net/     |
*-----------------------------------*

MacOSX + Homebrew Install Steps:

*-----------------------------------*
|  brew tap AdoptOpenJDK/openjdk    |
|  brew cask install adoptopenjdk8  |
*-----------------------------------*

""";

// ignore: avoid_void_async
void main(List<String> arguments) async {
  if (!(await hasJDK())) {
    print(MISSING_JDK_INFO);
    return;
  }

  await Directory(cacheDir).create(recursive: true);
  if (FileSystemEntity.typeSync(savePath) == FileSystemEntityType.notFound) {
    print("Trying to download voyager-codegen-$voyagerVersion.jar ...");

    try {
      await downloadFile(voyagerJarPath, savePath);
      print("Downloaded voyager-codegen-$voyagerVersion.jar");
    } catch (_) {
      stderr.writeln(
          "Failed to download $voyagerJarPath \nPlease try running this again or download the jar manually and save it to $savePath.\nOnce this is complete just rerun pub command.");
      exit(1);
    }
  }

  final process = await Process.start('java', ['-jar', savePath] + arguments);
  process.stdout.transform(utf8.decoder).listen((data) {
    print("$data".trim());
  });
}

Future<bool> hasJDK() async {
  try {
    final result = await Process.run('java', ['-version']);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

Future<void> downloadFile(String url, String filename) async {
  final _client = HttpClient();

  final request = await _client.getUrl(Uri.parse(url));

  final response = await request.close();

  await response.pipe(File(filename).openWrite());

  _client.close(force: true);

  return;
}
