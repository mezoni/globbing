import 'package:globbing/glob_parser.dart';
import 'package:test/test.dart';

void main() {
  _testAsterisk();
  _testAsterisks();
  _testBrace();
  _testCharacterClass();
  _testCrossesDirectory();
  _testLiteral();
  _testOnlyDirectory();
  _testQuestion();
  _testSegments();
}

void _testAsterisk() {
  test('Asterisk', () {
    {
      final pattern = '*';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result = segments.nodes.first.nodes.first is GlobNodeAsterisk;
      expect(result, true);
      // source
      final result2 = segments.nodes.first.nodes.first.source;
      expect(result2, pattern);
    }
    {
      final pattern = '**';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result = segments.nodes.first.nodes.first is GlobNodeAsterisk;
      expect(result, false);
    }
  });
}

void _testAsterisks() {
  test('Asterisks', () {
    {
      final pattern = '*';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result = segments.nodes.first.nodes.first is GlobNodeAsterisks;
      expect(result, false);
    }
    {
      final pattern = '**';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result1 = segments.nodes.first.nodes.first is GlobNodeAsterisks;
      expect(result1, true);
      // source
      final result2 = segments.nodes.first.nodes.first.source;
      expect(result2, pattern);
    }
  });
}

void _testBrace() {
  test('Brace', () {
    {
      final pattern = '{a,[0]}';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result1 = segments.nodes.first.nodes.first is GlobNodeBrace;
      expect(result1, true);
      final result2 = (segments.nodes.first.nodes.first as GlobNodeBrace)
          .nodes
          .first is GlobNodeLiteral;
      expect(result2, true);
      final result3 = (segments.nodes.first.nodes.first as GlobNodeBrace)
          .nodes
          .last is GlobNodeCharacterClass;
      expect(result3, true);
      final result4 = segments.nodes.first.nodes.first.source;
      expect(result4, pattern);
    }
  });
}

void _testCharacterClass() {
  test('CharacterClass', () {
    {
      final pattern = r'[0-9a-zA-Z\n]';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result1 =
          segments.nodes.first.nodes.first is GlobNodeCharacterClass;
      expect(result1, true);
      final result2 = segments.nodes.first.nodes.first.source;
      expect(result2, pattern);
      final result3 =
          (segments.nodes.first.nodes.first as GlobNodeCharacterClass).source;
      expect(result3, pattern);
    }
  });
}

void _testCrossesDirectory() {
  test('crossesDirectory', () {
    {
      final pattern = '**';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result = segments.crossesDirectory;
      expect(result, true);
    }
    {
      final pattern = '/**';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result = segments.crossesDirectory;
      expect(result, true);
    }
    {
      final pattern = '*';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result = segments.crossesDirectory;
      expect(result, false);
    }
    {
      final pattern = '/*';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result = segments.crossesDirectory;
      expect(result, false);
    }
  });
}

void _testLiteral() {
  test('Literal', () {
    {
      final pattern = 'hello';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result1 = segments.nodes.first.nodes.first is GlobNodeLiteral;
      expect(result1, true);
      final result2 = segments.nodes.first.nodes.first.source;
      expect(result2, pattern);
    }
  });
}

void _testOnlyDirectory() {
  test('OnlyDirectory', () {
    {
      final pattern = '///';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result = segments.nodes.last.onlyDirectory;
      expect(result, false);
    }
    {
      final pattern = 'c://';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result = segments.nodes.last.onlyDirectory;
      expect(result, false);
    }
    {
      final pattern = 'a//';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result = segments.nodes.last.onlyDirectory;
      expect(result, true);
    }
    {
      final pattern = 'a[0]//';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result = segments.nodes.last.onlyDirectory;
      expect(result, true);
    }
  });
}

void _testQuestion() {
  test('Question', () {
    {
      final pattern = '?';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result1 = segments.nodes.first.nodes.first is GlobNodeQuestion;
      expect(result1, true);
      final result2 = segments.nodes.first.nodes.first.source;
      expect(result2, pattern);
    }
  });
}

void _testSegments() {
  test('Segments', () {
    {
      final pattern = '*?hello';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result = segments.nodes.first.source;
      expect(result, pattern);
    }
    {
      final pattern = 'a/b';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result1 = segments.nodes.length;
      expect(result1, 2);
      final result2 = segments.nodes.first.source;
      expect(result2, 'a');
      final result3 = segments.nodes.last.source;
      expect(result3, 'b');
    }
    {
      final pattern = 'a/b/';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result1 = segments.nodes.length;
      expect(result1, 2);
      final result2 = segments.nodes.first.source;
      expect(result2, 'a');
      final result3 = segments.nodes.first.isRoot;
      expect(result3, false);
      final result4 = segments.nodes.last.source;
      expect(result4, 'b/');
    }
    {
      final pattern = '/a/b';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result1 = segments.nodes.length;
      expect(result1, 3);
      final result2 = segments.nodes.first.source;
      expect(result2, '/');
      final result3 = segments.nodes.first.isRoot;
      expect(result3, true);
      final result4 = segments.nodes.last.source;
      expect(result4, 'b');
    }
    {
      final pattern = '//';
      final parser = GlobParser();
      final segments = parser.parse(pattern);
      final result1 = segments.nodes.length;
      expect(result1, 1);
      final result2 = segments.nodes.first.source;
      expect(result2, '/');
      final result3 = segments.nodes.first.isRoot;
      expect(result3, true);
    }
  });
}
