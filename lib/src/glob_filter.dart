part of '../glob_filter.dart';

class GlobFilter {
  /// Pattern for this glob filter.
  final String pattern;

  late Glob _glob;

  late bool Function(String) _isDirectory;

  late bool _isWindows;

  bool? _onlyDirectory;

  /// Creates new glob filter.
  ///
  /// Parameters:
  ///  [pattern]
  ///   Pattern for this glob filter.
  ///  [caseSensitive]
  ///   True, if the pattern is case sensitive; otherwise false.
  ///  [isDirectory]
  ///   Function that determines that specified path is a directory or not.
  ///  [isWindows]
  ///   True, if used the path in the Windows style; otherwise false.
  GlobFilter(this.pattern,
      {bool? caseSensitive,
      bool Function(String path)? isDirectory,
      bool? isWindows}) {
    if (isDirectory == null) {
      throw ArgumentError.notNull('isDirectory');
    }

    if (isWindows == null) {
      throw ArgumentError.notNull('isWindows');
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
    _glob = Glob(pattern, caseSensitive: caseSensitive);
    _onlyDirectory = false;
    final segments = _glob.segments!;
    if (segments.isNotEmpty) {
      _onlyDirectory = segments.last.onlyDirectory;
    }
  }

  /// Returns a list of paths from which will be removed elements that match this
  /// filter.
  ///
  /// Parameters:
  ///  [list]
  ///   List of paths.
  ///  [added]
  ///   A function that is called whenever an item is added.
  ///  [removed]
  ///   A function that is called whenever an item is removed.
  List<String> exclude(List<String>? list,
      {void Function(String path)? added,
      void Function(String path)? removed}) {
    if (list == null) {
      throw ArgumentError.notNull('list');
    }

    final result = <String>[];
    for (var element in list) {
      var path = element;
      if (_isWindows) {
        path = path.replaceAll('\\', '/');
      }

      if (_onlyDirectory!) {
        if (_isDirectory(path)) {
          path += '/';
        }
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

  /// Returns a list of paths from which will be removed elements that do not
  /// match this filter.
  ///
  /// Parameters:
  ///  [list]
  ///   List of paths.
  ///  [added]
  ///   A function that is called whenever an item is added.
  ///  [removed]
  ///   A function that is called whenever an item is removed.
  List<String> include(List<String>? list,
      {void Function(String path)? added,
      void Function(String path)? removed}) {
    if (list == null) {
      throw ArgumentError.notNull('list');
    }

    final result = <String>[];
    for (var element in list) {
      var path = element;
      if (_isWindows) {
        path = path.replaceAll('\\', '/');
      }

      if (_onlyDirectory!) {
        if (_isDirectory(path)) {
          path += '/';
        }
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
