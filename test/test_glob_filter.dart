import "dart:io";
import "package:globbing/glob_filter.dart";
import "package:globbing/glob_lister.dart";
import "package:path/path.dart" as pathos;
import "package:unittest/unittest.dart";

void main() {
  testExclude();
  testInclude();
}

void testExclude() {
  var subject = "GlobFilter.include()";

  //
  var appRoot = Directory.current.parent.path;
  var pattern = appRoot + "/lib/**/*.dart";
  var lister = _getLister(pattern);
  var list = lister.list(Directory.current.parent.path);
  var isDirectory = (String path) => new Directory(path).existsSync();
  var criteria = appRoot + "/**/src/glob_*.dart";
  var filter = new GlobFilter(criteria, isDirectory: isDirectory, isWindows:
      Platform.isWindows);
  var result = filter.exclude(list);
  result.sort((a, b) => a.compareTo(b));
  result = result.map((e) => pathos.basename(e)).toList();
  var expected = ["globbing.dart"];
  expect(result, expected, reason: "$subject, ");
}

void testInclude() {
  var subject = "GlobFilter.include()";

  //
  var appRoot = Directory.current.parent.path;
  var pattern = appRoot + "/lib/**/*.dart";
  var lister = _getLister(pattern);
  var list = lister.list(Directory.current.parent.path);
  var isDirectory = (String path) => new Directory(path).existsSync();
  var criteria = appRoot + "/**/src/glob_*.dart";
  var filter = new GlobFilter(criteria, isDirectory: isDirectory, isWindows:
      Platform.isWindows);
  var result = filter.include(list);
  result.sort((a, b) => a.compareTo(b));
  result = result.map((e) => pathos.basename(e)).toList();
  var expected = ["glob_filter.dart", "glob_lister.dart", "glob_parser.dart"];
  expect(result, expected, reason: "$subject, ");
}

GlobLister _getLister(String pattern) {
  var exists = (String path) {
    return FileStat.statSync(path).type != FileSystemEntityType.NOT_FOUND;
  };

  var isDirectory = (String path) {
    return FileStat.statSync(path).type == FileSystemEntityType.DIRECTORY;
  };

  var list = (String path, bool followLinks) {
    return new Directory(path).listSync(followLinks: followLinks).map((e) =>
        e.path).toList();
  };

  var lister = new GlobLister(pattern, exists: exists, isDirectory: isDirectory,
      isWindows: Platform.isWindows, list: list);

  return lister;
}
