part of globbing.file_list;

class FileList extends Object with IterableMixin<String> {
  final Directory directory;

  List<String> _files;

  Glob _glob;

  FileList(this.directory, String files) {
    if (directory == null) {
      throw new ArgumentError("directory: $directory");
    }

    if (files == null) {
      throw new ArgumentError("files: $files");
    }

    if (_Utils.isWindows) {
      files = files.replaceAll("\\", "/");
    }

    _glob = new Glob(files);
  }

  /**
   * Returns the iterator.
   */
  Iterator<String> get iterator {
    if (_files == null) {
      _files = _getFiles();
    }

    return _files.iterator;
  }

  List<String> _getFiles() {
    var lister = new _DirectoryLister(_glob);
    return lister.list(directory);
  }
}

class _DirectoryLister {
  final Glob glob;

  List<String> _files;

  List<GlobSegment> _segments;

  _DirectoryLister(this.glob) {
    if (glob == null) {
      throw new ArgumentError("glob: $glob");
    }

    _segments = glob.segments;
  }

  List<String> list(Directory directory) {
    _files = <String>[];
    var segment = _segments[0];
    if (segment.crossing) {
      _listRecursive(directory);
    } else {
      if (_Utils.isAbsolute(glob.pattern)) {
        _listAbsolute(directory);
      } else {
        _listRelative(directory, 0);
      }
    }

    return _files;
  }

  void _listAbsolute(Directory directory) {
    for (var entry in directory.listSync()) {
      var entryPath = entry.path;
      if (_Utils.isWindows) {
        entryPath = entryPath.replaceAll("\\", "/");
      }

      if (!glob.canMatch(entryPath)) {
        continue;
      }

      if (glob.match(entryPath)) {
        _files.add(entryPath);
      }

      if (entry is Directory) {
        _listAbsolute(entry);
      }
    }
  }

  void _listRecursive(Directory directory) {
    for (var entry in directory.listSync()) {
      var entryPath = entry.path;
      if (_Utils.isWindows) {
        entryPath = entryPath.replaceAll("\\", "/");
      }

      if (!glob.canMatch(entryPath)) {
        continue;
      }

      if (glob.match(entryPath)) {
        _files.add(entryPath);
      }

      if (entry is Directory) {
        _listRecursive(entry);
      }
    }
  }

  void _listRelative(Directory directory, int level) {
    var segment = _segments[level];
    for (var entry in directory.listSync()) {
      var entryPath = entry.path;
      if (_Utils.isWindows) {
        entryPath = entryPath.replaceAll("\\", "/");
      }

      var index = entryPath.lastIndexOf("/");
      String part;
      if (index != -1) {
        part = entryPath.substring(index + 1);
      } else {
        part = entryPath;
      }

      if (!segment.match(part)) {
        continue;
      }

      if (level == _segments.length - 1) {
        _files.add(entryPath);
        continue;
      }

      if (entry is Directory) {
        var index = level + 1;
        var segment = _segments[index];
        if (!segment.crossing) {
          _listRelative(entry, index);
        } else {
          _listRecursive(entry);
        }
      }
    }
  }
}

class _Utils {
  static final bool isWindows = Platform.isWindows;

  static bool isAbsolute(String path) {
    var result = false;
    if (isWindows) {
      if (path.length >= 3) {
        var charCode = path.codeUnitAt(0);
        if (charCode >= Ascii.A && charCode <= Ascii.Z || charCode >= Ascii.a &&
            charCode <= Ascii.z) {
          if (path.codeUnitAt(1) == Ascii.COLON) {
            if (path.codeUnitAt(2) == Ascii.SLASH || path.codeUnitAt(2) ==
                Ascii.BACKSLASH) {
              result = true;
            }
          }
        }
      }
    } else {
      if (path.startsWith("/")) {
        result = true;
      }
    }

    return result;
  }
}
