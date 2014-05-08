part of globbing.glob_filter;

class GlobFilter {
  /**
   * Pattern for this glob filter.
   */
  final String pattern;

  Glob _glob;

  Function _isDirectory;

  bool _isWindows;

  bool _onlyDirectory;

  /**
   * Creates new glob filter.
   *
   * Parameters:
   *  [pattern]
   *   Pattern for this glob filter.
   *  [caseSensitive]
   *   True, if the pattern is case sensitive; otherwise false.
   *  [isDirectory]
   *   Function that determines that specified path is a directory or not.
   *  [isWindows]
   *   True, if used the path in the Windows style; otherwise false.
   */
  GlobFilter(this.pattern, {bool caseSensitive, bool isDirectory(String
      path), bool isWindows}) {
    if (pattern == null) {
      throw new ArgumentError("pattern: $pattern");
    }

    if (isDirectory == null) {
      throw new ArgumentError("isDirectory: $isDirectory");
    }

    if (isWindows == null) {
      throw new ArgumentError("isWindows: $isWindows");
    }

    if (caseSensitive == null) {
      if (isWindows) {
        caseSensitive = false;
      } else {
        caseSensitive = true;
      }
    }

    _isDirectory = isDirectory;
    _isWindows = isWindows;
    _glob = new Glob(pattern, caseSensitive: caseSensitive);
    _onlyDirectory = false;
    var segments = _glob.segments;
    if (!segments.isEmpty) {
      _onlyDirectory = segments.last.onlyDirectory;
    }
  }

  /**
   * Returns a list of paths from which will be removed elements that match this
   * filter.
   *
   * Parameters:
   *  [list]
   *   List of paths.
   *  [added]
   *   A function that is called whenever an item is added.
   *  [removed]
   *   A function that is called whenever an item is removed.
   */
  List<String> exclude(List<String> list, {void added(String path), void
      removed(String path)}) {
    if (list == null) {
      throw new ArgumentError("list: $list");
    }

    var result = new List<String>();
    for (var element in list) {
      var path = element;
      if (_isWindows) {
        path = path.replaceAll("\\", "/");
      }

      if (_onlyDirectory) {
        path += "/";
      }

      if (!_glob.match(path)) {
        result.add(element);
        if (added != null) {
          added(path);
        }
      } else {
        if (removed != null) {
          removed(path);
        }
      }
    }

    return result;
  }

  /**
   * Returns a list of paths from which will be removed elements that do not
   * match this filter.
   *
   * Parameters:
   *  [list]
   *   List of paths.
   *  [added]
   *   A function that is called whenever an item is added.
   *  [removed]
   *   A function that is called whenever an item is removed.
   */
  List<String> include(List<String> list, {void added(String path), void
      removed(String path)}) {
    if (list == null) {
      throw new ArgumentError("list: $list");
    }

    var result = new List<String>();
    for (var element in list) {
      var path = element;
      if (_isWindows) {
        path = path.replaceAll("\\", "/");
      }

      if (_onlyDirectory) {
        path += "/";
      }

      if (_glob.match(path)) {
        result.add(element);
        if (added != null) {
          added(path);
        }
      } else {
        if (removed != null) {
          removed(path);
        }
      }
    }

    return result;
  }
}
