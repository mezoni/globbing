part of globbing.file_list;

class FileList extends Object with IterableMixin<String> {
  final Directory directory;

  List<String> _files;

  Glob _glob;

  FileList(this.directory, String mask) {
    if (directory == null) {
      throw new ArgumentError("directory: $directory");
    }

    if (mask == null) {
      throw new ArgumentError("files: $mask");
    }

    if (_Utils.isWindows) {
      mask = mask.replaceAll("\\", "/");
    }

    _glob = new Glob(mask);
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

// TODO: Support of Windows network
class _DirectoryLister {
  final Glob glob;

  String _basePath;

  List<String> _files;

  GlobPath _globPath;

  int _offset;

  List<GlobSegment> _segments;

  _DirectoryLister(this.glob) {
    if (glob == null) {
      throw new ArgumentError("glob: $glob");
    }

    _segments = glob.segments;
  }

  List<String> list(Directory directory) {
    _files = <String>[];
    if (!directory.existsSync()) {
      return _files;
    }

    _basePath = directory.path;
    if (_Utils.isWindows) {
      _basePath = _basePath.replaceAll("\\", "/");
    }

    _globPath = new GlobPath(_basePath);
    var patternPath = glob.globPath;
    if (patternPath.isAbsolute) {
      _offset = 0;
    } else {
      _offset = _basePath.length;
    }

    if (patternPath.isAbsolute) {
      if (glob.crossing) {
        _listAbsoluteWithCrossing(directory);
      } else {
        _listAbsoluteWithoutCrossing(directory);
      }
    } else {
      if (_segments[0].crossing) {
        _listRecursive(directory);
      } else {
        _listRelative(directory, 0);
      }
    }

    return _files;
  }

  void _listAbsoluteWithCrossing(Directory directory) {
    if (!glob.canMatch(_basePath)) {
      return;
    }

    directory = new Directory(_basePath);
    if (directory.existsSync()) {
      _listRecursive(directory);
    }
  }

  void _listAbsoluteWithoutCrossing(Directory directory) {
    if (!glob.canMatch(_basePath)) {
      return;
    }

    var level = _globPath.segments.length;
    directory = new Directory(_basePath);
    if (directory.existsSync()) {
      _listAbsoluteWithoutCrossingStage2(directory, level);
    }
  }

  void _listAbsoluteWithoutCrossingStage2(Directory directory, int level) {
    var segment = _segments[level];
    assert(segment.crossing == false);
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
        _listAbsoluteWithoutCrossingStage2(entry, level + 1);
      }
    }
  }

  void _listRecursive(Directory directory) {
    for (var entry in directory.listSync()) {
      var entryPath = entry.path;
      if (_Utils.isWindows) {
        entryPath = entryPath.replaceAll("\\", "/");
      }

      var relativePath = entryPath;
      if (_offset > 0) {
        relativePath = entryPath.substring(_offset + 1);
      }

      if (!glob.canMatch(relativePath)) {
        continue;
      }

      if (glob.match(relativePath)) {
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
        var nextSegment = _segments[index];
        if (!nextSegment.crossing) {
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
}
