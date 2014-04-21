globbing
========

Globbing is a library for the pattern matching based on wildcard characters. Includes helper for a list of files.

BETA VERSION

```dart
import "dart:io";
import "package:globbing/file_list.dart";

void main() {
  // Find "unittest" packages in "pub cache"
  var pubCache = getPubCachePath();
  if (pubCache != null) {
    var mask = "**/unittest*/pubspec.yaml";
    var files = new FileList(new Directory(pubCache), mask);
    if (!files.isEmpty) {
      var list = files.toList();
      var length = list.length;
      print("Found $length version(s) of unittest");
      for (var file in files) {
        print(file);
      }
    }
  }

  // Find CHANGELOG's in "pub cache"
  if (pubCache != null) {
    var mask = "**/CHANGELOG*";
    var files = new FileList(new Directory(pubCache), mask);
    if (!files.isEmpty) {
      var list = files.toList();
      var length = list.length;
      print("Found $length 'CHANGELOG' files");
      for (var file in files) {
        print(file);
      }
    }
  }

  // Find packages with major version (approximately)
  if (pubCache != null) {
    var mask = "**/*[1-9]*.[0-9]*.[0-9]*/pubspec.yaml";
    var files = new FileList(new Directory(pubCache), mask);
    if (!files.isEmpty) {
      var list = files.toList();
      var length = list.length;
      print("Found $length packages with major version");
      for (var file in files) {
        print(file);
      }
    }
  }
}

String getPubCachePath() {
  var result = Platform.environment["PUB_CACHE"];
  if (result != null) {
    return result;
  }

  if (Platform.isWindows) {
    var appData = Platform.environment["APPDATA"];
    if (appData != null) {
      result = "$appData/Pub/Cache";
    }
  } else {
    var home = Platform.environment["HOME"];
    result = "$home/.pub-cache";
  }

  if (result != null) {
    var dir = new Directory(result);
    if (dir.existsSync()) {
      return dir.path;
    }
  }

  return null;
}
```
