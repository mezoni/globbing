import "dart:io";
import "package:globbing/file_list.dart";
import "package:path/path.dart" as pathos;
import "package:unittest/unittest.dart";

void main() {
  testAbsolute();
  testCrossing();
  testRelative();
}

void testAbsolute() {
  var mask = "lib/src/*.dart";
  var path = Platform.script.toFilePath();
  path = pathos.dirname(path);
  path = pathos.dirname(path);
  mask = pathos.join(path, mask);

  // Path "/home/user/dart/globbing"
  // Mask "/home/user/dart/globbing/lib/src/*.dart"
  var files = new FileList(new Directory(path), mask);
  var expected = ["file_list.dart", "globbing.dart"];
  var result = <String>[];
  for (var file in files) {
    result.add(pathos.basename(file));
  }

  result.sort((a, b) => a.compareTo(b));
  expect(result, expected, reason: mask);

  // Path "/"
  // Mask "/home/user/dart/globbing/lib/src/*.dart"
  files = new FileList(new Directory("/"), mask);
  result = <String>[];
  for (var file in files) {
    result.add(pathos.basename(file));
  }

  result.sort((a, b) => a.compareTo(b));
  expect(result, expected, reason: mask);
}

void testCrossing() {
  var mask = "**/unittest.dart";
  var path = Platform.script.toFilePath();
  path = pathos.dirname(path);
  path = pathos.dirname(path);

  // Path "/home/user/dart/globbing"
  // Mask "**/unittest.dart"
  var files = new FileList(new Directory(path), mask);
  // "globbing/packages/unittest/unittest.dart"
  // "globbing/example/packages/unittest/unittest.dart"
  // "globbing/test/packages/unittest/unittest.dart"
  var expected = ["unittest.dart", "unittest.dart", "unittest.dart"];
  var result = <String>[];
  for (var file in files) {
    result.add(pathos.basename(file));
  }

  result.sort((a, b) => a.compareTo(b));
  expect(result, expected, reason: mask);
}

void testRelative() {
  var mask = "lib/src/*.dart";
  var path = Platform.script.toFilePath();
  path = pathos.dirname(path);
  path = pathos.dirname(path);

  // Path "/home/user/dart/globbing"
  // Mask "lib/src/*.dart"
  var files = new FileList(new Directory(path), mask);
  var expected = ["file_list.dart", "globbing.dart"];
  var result = <String>[];
  for (var file in files) {
    result.add(pathos.basename(file));
  }

  result.sort((a, b) => a.compareTo(b));
  expect(result, expected, reason: mask);
}
