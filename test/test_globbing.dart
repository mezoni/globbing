import 'package:globbing/globbing.dart';
import 'package:test/test.dart';

void main() {
  Glob('[!a]');
  _testCommon();
  _testCharacterClass();
  _testChoice();
  _testCrossing();
  _testDotGlob();
  _testEscape();
  _testExtension();
  _testMetachars();
}

void _testCharacterClass() {
  test('CharacterClass', () {
    {
      final glob = Glob('[0-9a]');
      var path = '5';
      final result1 = glob.match(path);
      expect(result1, true, reason: glob.pattern);
      path = 'a';
      final result2 = glob.match(path);
      expect(result2, true, reason: glob.pattern);
    }
    {
      final glob = Glob('[!0-9]');
      final path = '5';
      final result = glob.match(path);
      expect(result, false, reason: glob.pattern);
    }

    {
      final glob = Glob('[-]');
      final path = '-';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }

    {
      final glob = Glob('[]]');
      final path = ']';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }

    {
      final glob = Glob('[]-]');
      var path = '-';
      final result1 = glob.match(path);
      expect(result1, true, reason: glob.pattern);
      path = ']';
      final result2 = glob.match(path);
      expect(result2, true, reason: glob.pattern);
    }

    {
      final glob = Glob('[--0]');
      var path = '-';
      final result1 = glob.match(path);
      expect(result1, true, reason: glob.pattern);
      path = '.';
      final result2 = glob.match(path);
      expect(result2, true, reason: glob.pattern);
      path = '0';
      final result3 = glob.match(path);
      expect(result3, true, reason: glob.pattern);
    }
  });
}

void _testChoice() {
  test('Choice', () {
    {
      final glob = Glob('a{b,c,}');
      final list = ['a', 'ab', 'ac'];
      for (final path in list) {
        final result = glob.match(path);
        expect(result, true, reason: path);
      }
    }
  });
}

void _testCommon() {
  test('', () {
    {
      final glob = Glob('c?*a');
      var path = 'c1a';
      final result1 = glob.match(path);
      expect(result1, true, reason: glob.pattern);
      path = 'c123a';
      final result2 = glob.match(path);
      expect(result2, true, reason: glob.pattern);
      path = 'ca';
      final result3 = glob.match(path);
      expect(result3, false, reason: glob.pattern);
    }
    {
      final glob = Glob('a*b*c');
      var path = 'abc';
      final result1 = glob.match(path);
      expect(result1, true, reason: glob.pattern);
      path = 'a1b1c';
      final result2 = glob.match(path);
      expect(result2, true, reason: glob.pattern);
    }
    {
      final glob = Glob('*a*b*c');
      var path = 'abc';
      final result1 = glob.match(path);
      expect(result1, true, reason: glob.pattern);
      path = '1a1b1c';
      final result2 = glob.match(path);
      expect(result2, true, reason: glob.pattern);
    }
    {
      final glob = Glob('*a?*b?*c');
      final path = '1a1b1c';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      final glob = Glob('?*a?*bcd?*def*');
      final path = 'xyza123bcd234def456';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      final glob = Glob('?*a?*bcd?*def*');
      final path = 'xyzabcd234def456';
      final result = glob.match(path);
      expect(result, false, reason: glob.pattern);
    }
  });
}

void _testCrossing() {
  test('Crossing', () {
    {
      final glob = Glob('/home/**/ab*');
      final path = '/home/foo/baz/abc';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      final glob = Glob('/home/**/ab*/**/def');
      final path = '/home/foo/abc/123/def';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      final glob = Glob('/home/**/ab*/**/def');
      final path = '/home/foo/agc/123/def';
      final result = glob.match(path);
      expect(result, false, reason: glob.pattern);
    }
    {
      final glob = Glob('/home/**ab*/def');
      final path = '/home/ab1/ab2/ab3/def';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
  });
}

void _testDotGlob() {
  test('Dotglob', () {
    {
      final glob = Glob('*');
      final path = '.hidden';
      final result = glob.match(path);
      expect(result, false, reason: glob.pattern);
    }
    {
      final glob = Glob('.*');
      final path = '.hidden';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      final glob = Glob('*');
      final path = '.hidden/.hidden';
      final result = glob.match(path);
      expect(result, false, reason: glob.pattern);
    }
  });
}

void _testEscape() {
  test('Escape', () {
    {
      final glob = Glob(r'\*');
      final path = '*';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      final glob = Glob(r'\?');
      final path = '?';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      final glob = Glob(r'\[');
      final path = '[';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      final glob = Glob(r'\{');
      final path = '{';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
  });
}

void _testExtension() {
  test('Extension', () {
    {
      final glob = Glob('*.h');
      final path = 'stdio.h';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      final glob = Glob('foo/a*.b*.*xt');
      final path = 'foo/abc.baz.txt';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
  });
}

void _testMetachars() {
  test('Metachars', () {
    {
      final glob = Glob('(');
      final path = '(';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      final glob = Glob('\s');
      final path = 's';
      final result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
  });
}
