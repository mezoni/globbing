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

  // Find "CHANGELOG" in "pub cache"
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

  // Find executable files in "bin" folders
  if (pubCache != null) {
    var mask = "**/bin/*.dart";
    var files = new FileList(new Directory(pubCache), mask);
    if (!files.isEmpty) {
      var list = files.toList();
      var length = list.length;
      print("Found $length executable files in 'bin'");
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

  return result;
}
```
