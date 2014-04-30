import "dart:io";
import "package:globbing/file_list.dart";
import "package:globbing/file_path.dart";

void main() {
  // Directories in home directory, include hidden
  var home = FilePath.expand("~");
  var directory = new Directory(home);
  var mask = "~/{.*,*}/";
  var files = new FileList(directory, mask);
  if (!files.isEmpty) {
    var list = files.toList();
    var length = list.length;
    print("Found $length directories in $home");
    for (var file in files) {
      print(file);
    }
  }

  // Find "unittest" packages in "pub cache"
  var pubCache = getPubCachePath();
  if (pubCache != null) {
    var mask = "**/unittest*/pubspec.yaml";
    var directory = new Directory(pubCache);
    var files = new FileList(directory, mask);
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
    var directory = new Directory(pubCache);
    var files = new FileList(directory, mask, caseSensitive: false);
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
    var directory = new Directory(pubCache);
    var files = new FileList(directory, mask);
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
    var home = FilePath.expand("~");
    if(home != null) {
      result = "$home/.pub-cache";
    }
  }

  return result;
}
