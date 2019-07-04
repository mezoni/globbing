import "package:globbing/glob_parser.dart";
import "package:test/test.dart";

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
  test("Asterisk", () {
    {
      var pattern = "*";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result = segments.nodes.first.nodes.first is GlobNodeAsterisk;
      expect(result, true);
      // source
      var result2 = segments.nodes.first.nodes.first.source;
      expect(result2, pattern);
    }
    {
      var pattern = "**";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result = segments.nodes.first.nodes.first is GlobNodeAsterisk;
      expect(result, false);
    }
  });
}

void _testAsterisks() {
  test("Asterisks", () {
    {
      var pattern = "*";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result = segments.nodes.first.nodes.first is GlobNodeAsterisks;
      expect(result, false);
    }
    {
      var pattern = "**";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result1 = segments.nodes.first.nodes.first is GlobNodeAsterisks;
      expect(result1, true);
      // source
      var result2 = segments.nodes.first.nodes.first.source;
      expect(result2, pattern);
    }
  });
}

void _testBrace() {
  test("Brace", () {
    {
      var pattern = "{a,[0]}";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result1 = segments.nodes.first.nodes.first is GlobNodeBrace;
      expect(result1, true);
      var result2 = (segments.nodes.first.nodes.first as GlobNodeBrace)
          .nodes
          .first is GlobNodeLiteral;
      expect(result2, true);
      var result3 = (segments.nodes.first.nodes.first as GlobNodeBrace)
          .nodes
          .last is GlobNodeCharacterClass;
      expect(result3, true);
      var result4 = segments.nodes.first.nodes.first.source;
      expect(result4, pattern);
    }
  });
}

void _testCharacterClass() {
  test("CharacterClass", () {
    {
      var pattern = r"[0-9a-zA-Z\n]";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result1 = segments.nodes.first.nodes.first is GlobNodeCharacterClass;
      expect(result1, true);
      var result2 = segments.nodes.first.nodes.first.source;
      expect(result2, pattern);
      var result3 =
          (segments.nodes.first.nodes.first as GlobNodeCharacterClass).source;
      expect(result3, pattern);
    }
  });
}

void _testCrossesDirectory() {
  test("crossesDirectory", () {
    {
      var pattern = "**";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result = segments.crossesDirectory;
      expect(result, true);
    }
    {
      var pattern = "/**";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result = segments.crossesDirectory;
      expect(result, true);
    }
    {
      var pattern = "*";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result = segments.crossesDirectory;
      expect(result, false);
    }
    {
      var pattern = "/*";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result = segments.crossesDirectory;
      expect(result, false);
    }
  });
}

void _testLiteral() {
  test("Literal", () {
    {
      var pattern = "hello";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result1 = segments.nodes.first.nodes.first is GlobNodeLiteral;
      expect(result1, true);
      var result2 = segments.nodes.first.nodes.first.source;
      expect(result2, pattern);
    }
  });
}

void _testOnlyDirectory() {
  test("OnlyDirectory", () {
    {
      var pattern = "///";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result = segments.nodes.last.onlyDirectory;
      expect(result, false);
    }
    {
      var pattern = "c://";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result = segments.nodes.last.onlyDirectory;
      expect(result, false);
    }
    {
      var pattern = "a//";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result = segments.nodes.last.onlyDirectory;
      expect(result, true);
    }
    {
      var pattern = "a[0]//";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result = segments.nodes.last.onlyDirectory;
      expect(result, true);
    }
  });
}

void _testQuestion() {
  test("Question", () {
    {
      var pattern = "?";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result1 = segments.nodes.first.nodes.first is GlobNodeQuestion;
      expect(result1, true);
      var result2 = segments.nodes.first.nodes.first.source;
      expect(result2, pattern);
    }
  });
}

void _testSegments() {
  test("Segments", () {
    {
      var pattern = "*?hello";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result = segments.nodes.first.source;
      expect(result, pattern);
    }
    {
      var pattern = "a/b";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result1 = segments.nodes.length;
      expect(result1, 2);
      var result2 = segments.nodes.first.source;
      expect(result2, "a");
      var result3 = segments.nodes.last.source;
      expect(result3, "b");
    }
    {
      var pattern = "a/b/";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result1 = segments.nodes.length;
      expect(result1, 2);
      var result2 = segments.nodes.first.source;
      expect(result2, "a");
      var result3 = segments.nodes.first.isRoot;
      expect(result3, false);
      var result4 = segments.nodes.last.source;
      expect(result4, "b/");
    }
    {
      var pattern = "/a/b";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result1 = segments.nodes.length;
      expect(result1, 3);
      var result2 = segments.nodes.first.source;
      expect(result2, "/");
      var result3 = segments.nodes.first.isRoot;
      expect(result3, true);
      var result4 = segments.nodes.last.source;
      expect(result4, "b");
    }
    {
      var pattern = "//";
      var parser = GlobParser();
      var segments = parser.parse(pattern);
      var result1 = segments.nodes.length;
      expect(result1, 1);
      var result2 = segments.nodes.first.source;
      expect(result2, "/");
      var result3 = segments.nodes.first.isRoot;
      expect(result3, true);
    }
  });
}
