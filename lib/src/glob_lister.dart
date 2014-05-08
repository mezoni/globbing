part of globbing.glob_lister;

class GlobLister {
  /**
   * Pattern of this glob lister.
   */
  final String pattern;

  bool _caseSensitive;

  Function _exists;

  List<String> _files;

  bool _followLinks;

  Glob _glob;

  Function _isDirectory;

  bool _isWindows;

  Function _list;

  Function _notify;

  int _offset;

  bool _onlyDirectory;

  List<GlobSegment> _segments;

  bool _useStrict;

  /**
   * Creates the glob lister.
   *
   * Parameters:
   *  [pattern]
   *   Pattern of this glob lister.
   *  [caseSensitive]
   *   True, if the pattern is case sensitive; otherwise false.
   *  [exists]
   *   Function that determines that the specified path exists or not.
   *  [followLinks]
   *   True, if lister should follow symbolic links; otherwise false.
   *  [isDirectory]
   *    Function that determines that the specified path is a directory or not.
   *  [isWindows]
   *   True, if used the path in the Windows style; otherwise false.
   *  [list]
   *   Function that lists the specified directory.
   */
  GlobLister(this.pattern, {bool caseSensitive, bool exists(String path), bool
      followLinks: true, bool isDirectory(String path), bool isWindows, List<String>
      list(String path, bool followLinks)}) {
    if (pattern == null) {
      throw new ArgumentError("pattern: $pattern");
    }

    if (exists == null) {
      throw new ArgumentError("exists: $exists");
    }

    if (followLinks == null) {
      throw new ArgumentError("followLinks: $followLinks");
    }

    if (isDirectory == null) {
      throw new ArgumentError("isDirectory: $isDirectory");
    }

    if (isWindows == null) {
      throw new ArgumentError("isWindows: $isWindows");
    }

    if (list == null) {
      throw new ArgumentError("list: $list");
    }

    if (caseSensitive == null) {
      if (isWindows) {
        caseSensitive = false;
      } else {
        caseSensitive = true;
      }
    }

    _caseSensitive = caseSensitive;
    _exists = exists;
    _followLinks = followLinks;
    _isDirectory = isDirectory;
    _isWindows = isWindows;
    _list = list;
    _glob = new Glob(pattern, caseSensitive: caseSensitive);
    _segments = _glob.segments;
    if (!_segments.isEmpty) {
      _onlyDirectory = _segments.last.onlyDirectory;
    } else {
      _onlyDirectory = false;
    }
  }

  /**
   * Lists the directory and returns content of this directory.
   *
   * Parameters:
   *  [directory]
   *   Directory wich will be listed.
   *  [notify]
   *   A function that is called whenever an item is added.
   */
  List<String> list(String directory, {void notify(String path)}) {
    _files = <String>[];
    if (!_isDirectory(directory)) {
      return _files;
    }

    _notify = notify;
    if (_caseSensitive) {
      if (_isWindows) {
        _useStrict = false;
      } else {
        _useStrict = true;
      }
    } else {
      if (_isWindows) {
        _useStrict = true;
      } else {
        _useStrict = false;
      }
    }

    var isAbsolute = _glob.isAbsolute;
    if (isAbsolute) {
      _offset = 0;
    } else {
      _offset = directory.length;
    }

    if (isAbsolute) {
      if (_glob.crossesDirectory) {
        _listAbsoluteWithCrossing(directory);
      } else {
        _listAbsoluteWithoutCrossing(directory);
      }
    } else {
      if (_segments[0].crossesDirectory) {
        _listRecursive(directory);
      } else {
        _listRelative(directory, 0);
      }
    }

    return _files;
  }

  void _listAbsoluteWithCrossing(String path) {
    if (_isWindows) {
      path = path.replaceAll("\\", "/");
    }

    var pathSegments = pathos.split(path);
    var length = pathSegments.length;
    if (length > _segments.length) {
      length = _segments.length;
    }

    for (var i = 0; i < length; i++) {
      var segment = _segments[i];
      if (segment.crossesDirectory) {
        break;
      }

      if (!_segments[i].match(pathSegments[i])) {
        return;
      }
    }

    if (_exists(path) && _isDirectory(path)) {
      _listRecursive(path);
    }
  }

  void _listAbsoluteWithoutCrossing(String path) {
    if (_isWindows) {
      path = path.replaceAll("\\", "/");
    }

    var pathSegments = pathos.split(path);
    var length = pathSegments.length;
    if (length > _segments.length) {
      return;
    }

    var index = 0;
    for ( ; index < length; index++) {
      var pathSegment = pathSegments[index];
      var segment = _segments[index];
      if (segment.onlyDirectory) {
        pathSegment += "/";
      }

      if (!segment.match(pathSegment)) {
        return;
      }
    }

    if (index == _segments.length) {
      var segment = _segments[index - 1];
      var exists = false;
      if (segment.onlyDirectory) {
        exists = _isDirectory(path);
      } else {
        exists = _exists(path);
      }

      if (exists) {
        _files.add(path);
        if (_notify != null) {
          _notify(path);
        }
      }

      return;
    }

    if (_isDirectory(path)) {
      _listAbsoluteWithoutCrossingStage2(path, length);
    }
  }

  void _listAbsoluteWithoutCrossingStage2(String path, int level) {
    var segment = _segments[level];
    if (segment.strict && _useStrict) {
      path = pathos.join(path, segment.pattern);
      var dirExists = _isDirectory(path);
      var exists = false;
      if (!dirExists) {
        exists = _exists(path);
      }

      if (!(dirExists || exists)) {
        return;
      }

      if (level == _segments.length - 1) {
        if (_isWindows) {
          path = path.replaceAll("\\", "/");
        }

        if (segment.onlyDirectory) {
          if (dirExists) {
            _files.add(path);
            if (_notify != null) {
              _notify(path);
            }
          }

        } else {
          _files.add(path);
          if (_notify != null) {
            _notify(path);
          }
        }

        return;
      }

      if (dirExists) {
        _listAbsoluteWithoutCrossingStage2(path, level + 1);
      }

      return;
    }

    List<String> list = _list(path, _followLinks);
    for (var entry in list) {
      var entryPath = entry;
      if (_isWindows) {
        entryPath = entryPath.replaceAll("\\", "/");
      }

      var index = entryPath.lastIndexOf("/");
      String part;
      if (index != -1) {
        part = entryPath.substring(index + 1);
      } else {
        part = entryPath;
      }

      bool isDirectory = _isDirectory(entry);
      if (segment.onlyDirectory) {
        if (isDirectory) {
          part += "/";
        }
      }

      if (!segment.match(part)) {
        continue;
      }

      if (level == _segments.length - 1) {
        if (segment.onlyDirectory) {
          if (isDirectory) {
            _files.add(entryPath);
            if (_notify != null) {
              _notify(path);
            }
          }

        } else {
          _files.add(entryPath);
          if (_notify != null) {
            _notify(path);
          }
        }

        continue;
      }

      if (isDirectory) {
        _listAbsoluteWithoutCrossingStage2(entry, level + 1);
      }
    }
  }

  void _listRecursive(String path) {
    List<String> list = _list(path, _followLinks);
    for (var entry in list) {
      var entryPath = entry;
      if (_isWindows) {
        entryPath = entryPath.replaceAll("\\", "/");
      }

      var relativePath = entryPath;
      if (_offset > 0) {
        relativePath = entryPath.substring(_offset + 1);
      }

      bool isDirectory = _isDirectory(entry);
      if (_onlyDirectory) {
        if (isDirectory) {
          relativePath += "/";
          if (_glob.match(relativePath)) {
            _files.add(entryPath);
            if (_notify != null) {
              _notify(path);
            }
          }
        }

      } else {
        if (_glob.match(relativePath)) {
          _files.add(entryPath);
          if (_notify != null) {
            _notify(path);
          }
        }
      }

      if (isDirectory) {
        _listRecursive(entry);
      }
    }
  }

  void _listRelative(String path, int level) {
    var segment = _segments[level];
    if (segment.strict && _useStrict) {
      path = pathos.join(path, segment.pattern);
      bool dirExists = _isDirectory(path);
      var exists = false;
      if (!dirExists) {
        exists = _exists(path);
      }

      if (!(dirExists || exists)) {
        return;
      }

      if (level == _segments.length - 1) {
        if (_isWindows) {
          path = path.replaceAll("\\", "/");
        }

        if (segment.onlyDirectory) {
          if (dirExists) {
            _files.add(path);
            if (_notify != null) {
              _notify(path);
            }
          }

        } else {
          _files.add(path);
          if (_notify != null) {
            _notify(path);
          }
        }

        return;
      }

      if (dirExists) {
        var index = level + 1;
        var nextSegment = _segments[index];
        if (!nextSegment.crossesDirectory) {
          _listRelative(path, index);
        } else {
          _listRecursive(path);
        }
      }

      return;
    }

    List<String> list = _list(path, _followLinks);
    for (var entry in list) {
      var entryPath = entry;
      if (_isWindows) {
        entryPath = entryPath.replaceAll("\\", "/");
      }

      var index = entryPath.lastIndexOf("/");
      String part;
      if (index != -1) {
        part = entryPath.substring(index + 1);
      } else {
        part = entryPath;
      }

      bool isDirectory = _isDirectory(entry);
      if (segment.onlyDirectory) {
        if (isDirectory) {
          part += "/";
        }
      }

      if (!segment.match(part)) {
        continue;
      }

      if (level == _segments.length - 1) {
        if (segment.onlyDirectory) {
          if (isDirectory) {
            _files.add(entryPath);
            if (_notify != null) {
              _notify(path);
            }
          }

        } else {
          _files.add(entryPath);
          if (_notify != null) {
            _notify(path);
          }
        }

        continue;
      }

      if (isDirectory) {
        var index = level + 1;
        var nextSegment = _segments[index];
        if (!nextSegment.crossesDirectory) {
          _listRelative(entry, index);
        } else {
          _listRecursive(entry);
        }
      }
    }
  }
}
