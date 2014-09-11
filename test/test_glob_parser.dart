import "package:globbing/glob_parser.dart";
import "package:unittest/unittest.dart";

void main() {
  testAsterisk();
  testAsterisks();
  testAsterisksSlash();
  testBrace();
  testCharacterClass();
  testCrossesDirectory();
  testLiteral();
  testOnlyDirectory();
  testQuestion();
  testSegments();
}

void testAsterisk() {
  var subject = "Asterisk";

  // *
  var pattern = "*";
  var parser = new GlobParser();
  var segments = parser.parse(pattern);
  var result = segments.nodes.first.nodes.first is GlobNodeAsterisk;
  expect(result, true, reason: "$subject, $pattern");
  // source
  result = segments.nodes.first.nodes.first.source;
  expect(result, pattern, reason: "$subject, $pattern");

  // **
  pattern = "**";
  parser = new GlobParser();
  segments = parser.parse(pattern);
  result = segments.nodes.first.nodes.first is GlobNodeAsterisk;
  expect(result, false, reason: "$subject, $pattern");
}

void testAsterisks() {
  var subject = "Asterisks";

  // *
  var pattern = "*";
  var parser = new GlobParser();
  var segments = parser.parse(pattern);
  var result = segments.nodes.first.nodes.first is GlobNodeAsterisks;
  expect(result, false, reason: "$subject, $pattern");

  // **
  pattern = "**";
  parser = new GlobParser();
  segments = parser.parse(pattern);
  result = segments.nodes.first.nodes.first is GlobNodeAsterisks;
  expect(result, true, reason: "$subject, $pattern");
  // source
  result = segments.nodes.first.nodes.first.source;
  expect(result, pattern, reason: "$subject, $pattern");
}

void testAsterisksSlash() {
  var subject = "AsterisksSlash";

  // **
  var pattern = "*/";
  var parser = new GlobParser(gitignoreSemantics: true);
  var segments = parser.parse(pattern);
  var result = segments.nodes.first.nodes.first is GlobNodeAsterisk;
  expect(result, true, reason: "$subject, $pattern");

  // **
  pattern = "**";
  parser = new GlobParser(gitignoreSemantics: true);
  segments = parser.parse(pattern);
  result = segments.nodes.first.nodes.first is GlobNodeAsterisksSlash;
  expect(result, false, reason: "$subject, $pattern");

  // **/
  pattern = "**/";
  parser = new GlobParser(gitignoreSemantics: true);
  segments = parser.parse(pattern);
  result = segments.nodes.first.nodes.first is GlobNodeAsterisksSlash;
  expect(result, true, reason: "$subject, $pattern");
  // source
  result = segments.nodes.first.nodes.first.source;
  expect(result, pattern, reason: "$subject, $pattern");

  // **/ with gitignoreSemantics unset (and defaulting to false)
  pattern = "**/";
  parser = new GlobParser();
  segments = parser.parse(pattern);
  result = segments.nodes.first.nodes.first is GlobNodeAsterisksSlash;
  expect(result, false, reason: "$subject, $pattern");
  // source
  result = segments.nodes.first.nodes.first.source;
  expect(result, "**", reason: "$subject, $pattern");
}

void testBrace() {
  var subject = "Brace";

  // {a,[0]}
  var pattern = "{a,[0]}";
  var parser = new GlobParser();
  var segments = parser.parse(pattern);
  var result = segments.nodes.first.nodes.first is GlobNodeBrace;
  expect(result, true, reason: "$subject, $pattern");
  // first
  result = (segments.nodes.first.nodes.first as GlobNodeBrace).nodes.first is
      GlobNodeLiteral;
  expect(result, true, reason: "$subject, $pattern");
  // last
  result = (segments.nodes.first.nodes.first as GlobNodeBrace).nodes.last is
      GlobNodeCharacterClass;
  expect(result, true, reason: "$subject, $pattern");
  // source
  result = segments.nodes.first.nodes.first.source;
  expect(result, pattern, reason: "$subject, $pattern");
}

void testCharacterClass() {
  var subject = "CharacterClass";

  // [0-9a-zA-Z\n]
  var pattern = r"[0-9a-zA-Z\n]";
  var parser = new GlobParser();
  var segments = parser.parse(pattern);
  var result = segments.nodes.first.nodes.first is GlobNodeCharacterClass;
  expect(result, true, reason: "$subject, $pattern");
  // source
  result = segments.nodes.first.nodes.first.source;
  expect(result, pattern, reason: "$subject, $pattern");
  // characters
  result = (segments.nodes.first.nodes.first as GlobNodeCharacterClass).source;
  expect(result, pattern, reason: "$subject, $pattern");
}

void testCrossesDirectory() {
  var subject = "crossesDirectory";

  // **
  var pattern = "**";
  var parser = new GlobParser();
  var segments = parser.parse(pattern);
  var result = segments.crossesDirectory;
  expect(result, true, reason: "$subject, $pattern");

  // /**
  pattern = "/**";
  parser = new GlobParser();
  segments = parser.parse(pattern);
  result = segments.crossesDirectory;
  expect(result, true, reason: "$subject, $pattern");

  // *
  pattern = "*";
  parser = new GlobParser();
  segments = parser.parse(pattern);
  result = segments.crossesDirectory;
  expect(result, false, reason: "$subject, $pattern");

  // /*
  pattern = "/*";
  parser = new GlobParser();
  segments = parser.parse(pattern);
  result = segments.crossesDirectory;
  expect(result, false, reason: "$subject, $pattern");
}

void testLiteral() {
  var subject = "Literal";

  // hello
  var pattern = "hello";
  var parser = new GlobParser();
  var segments = parser.parse(pattern);
  var result = segments.nodes.first.nodes.first is GlobNodeLiteral;
  expect(result, true, reason: "$subject, $pattern");
  // source
  result = segments.nodes.first.nodes.first.source;
}

void testOnlyDirectory() {
  var subject = "onlyDirectory";

  // ///
  var pattern = "///";
  var parser = new GlobParser();
  var segments = parser.parse(pattern);
  var result = segments.nodes.last.onlyDirectory;
  expect(result, false, reason: "$subject, $pattern");

  // c://
  pattern = "c://";
  parser = new GlobParser();
  segments = parser.parse(pattern);
  result = segments.nodes.last.onlyDirectory;
  expect(result, false, reason: "$subject, $pattern");

  // a//
  pattern = "a//";
  parser = new GlobParser();
  segments = parser.parse(pattern);
  result = segments.nodes.last.onlyDirectory;
  expect(result, true, reason: "$subject, $pattern");

  // a[0]//
  pattern = "a[0]//";
  parser = new GlobParser();
  segments = parser.parse(pattern);
  result = segments.nodes.last.onlyDirectory;
  expect(result, true, reason: "$subject, $pattern");
}

void testQuestion() {
  var subject = "Question";

  // ?
  var pattern = "?";
  var parser = new GlobParser();
  var segments = parser.parse(pattern);
  var result = segments.nodes.first.nodes.first is GlobNodeQuestion;
  expect(result, true, reason: "$subject, $pattern");
  // source
  result = segments.nodes.first.nodes.first.source;
}

void testSegments() {
  var subject = "Segments";

  // *?hello
  var pattern = "*?hello";
  var parser = new GlobParser();
  var segments = parser.parse(pattern);
  var result = segments.nodes.first.source;
  expect(result, pattern, reason: "$subject, $pattern");

  // a/b
  pattern = "a/b";
  parser = new GlobParser();
  segments = parser.parse(pattern);
  // count
  result = segments.nodes.length;
  expect(result, 2, reason: "$subject, $pattern");
  // first
  result = segments.nodes.first.source;
  expect(result, "a", reason: "$subject, $pattern");
  // last
  result = segments.nodes.last.source;
  expect(result, "b", reason: "$subject, $pattern");

  // a/b/
  pattern = "a/b/";
  parser = new GlobParser();
  segments = parser.parse(pattern);
  // count
  result = segments.nodes.length;
  expect(result, 2, reason: "$subject, $pattern");
  // first
  result = segments.nodes.first.source;
  expect(result, "a", reason: "$subject, $pattern");
  // first isRoot
  result = segments.nodes.first.isRoot;
  expect(result, false, reason: "$subject, $pattern");
  // last
  result = segments.nodes.last.source;
  expect(result, "b/", reason: "$subject, $pattern");

  // /a/b
  pattern = "/a/b";
  parser = new GlobParser();
  segments = parser.parse(pattern);
  // count
  result = segments.nodes.length;
  expect(result, 3, reason: "$subject, $pattern");
  // first
  result = segments.nodes.first.source;
  expect(result, "/", reason: "$subject, $pattern");
  // first isRoot
  result = segments.nodes.first.isRoot;
  expect(result, true, reason: "$subject, $pattern");
  // last
  result = segments.nodes.last.source;
  expect(result, "b", reason: "$subject, $pattern");

  // //
  pattern = "//";
  parser = new GlobParser();
  segments = parser.parse(pattern);
  // count
  result = segments.nodes.length;
  expect(result, 1, reason: "$subject, $pattern");
  // first
  result = segments.nodes.first.source;
  expect(result, "/", reason: "$subject, $pattern");
  // first isRoot
  result = segments.nodes.first.isRoot;
  expect(result, true, reason: "$subject, $pattern");
}
