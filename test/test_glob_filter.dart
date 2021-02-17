import 'dart:io';

import 'package:globbing/glob_filter.dart';
import 'package:globbing/glob_lister.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';

void main() {
  _testExclude();
  _testInclude();
}

GlobLister _getLister(String pattern) {
  final exists = (String path) {
    return FileStat.statSync(path).type != FileSystemEntityType.notFound;
  };

  final isDirectory = (String path) {
    return FileStat.statSync(path).type == FileSystemEntityType.directory;
  };

  final list = (String path, bool? followLinks) {
    return Directory(path)
        .listSync(followLinks: followLinks!)
        .map((e) => e.path)
        .toList();
  };

  final lister = GlobLister(pattern,
      exists: exists,
      isDirectory: isDirectory,
      isWindows: Platform.isWindows,
      list: list);

  return lister;
}

void _testExclude() {
  test('GlobFilter.exclude()', () {
    {
      var appRoot = Directory.current.path;
      appRoot = appRoot.replaceAll('\\', '/');
      final pattern = appRoot + '/lib/**/*.dart';
      final lister = _getLister(pattern);
      final list = lister.list(Directory.current.path);
      final isDirectory = (String path) => Directory(path).existsSync();
      final criteria = appRoot + '/**/src/glob_*.dart';
      final filter = GlobFilter(criteria,
          isDirectory: isDirectory, isWindows: Platform.isWindows);
      var result = filter.exclude(list);
      result.sort((a, b) => a.compareTo(b));
      result = result.map(pathos.basename).toList();
      final expected = ['globbing.dart'];
      expect(result, expected);
    }
  });
}

void _testInclude() {
  test('GlobFilter.include()', () {
    {
      var appRoot = Directory.current.path;
      appRoot = appRoot.replaceAll('\\', '/');
      final pattern = appRoot + '/lib/**/*.dart';
      final lister = _getLister(pattern);
      final list = lister.list(Directory.current.path);
      final isDirectory = (String path) => Directory(path).existsSync();
      final criteria = appRoot + '/**/src/glob_*.dart';
      final filter = GlobFilter(criteria,
          isDirectory: isDirectory, isWindows: Platform.isWindows);
      var result = filter.include(list);
      result.sort((a, b) => a.compareTo(b));
      result = result.map(pathos.basename).toList();
      final expected = [
        'glob_filter.dart',
        'glob_lister.dart',
        'glob_parser.dart'
      ];
      expect(result, expected);
    }
  });
}
