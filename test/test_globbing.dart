import "package:globbing/globbing.dart";
import "package:unittest/unittest.dart";

void main() {
  test();
  testCharacterClass();
  testCanMatch();
  testCrossing();
  testDotglob();
  testExtension();
}

void test() {
  var glob = new Glob("c?*a");
  var path = "c1a";
  var result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  path = "c123a";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  path = "ca";
  result = glob.match(path);
  expect(result, false, reason: glob.pattern);
  glob = new Glob("a*b*c");
  path = "abc";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  path = "a1b1c";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  glob = new Glob("*a*b*c");
  path = "abc";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  path = "1a1b1c";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  glob = new Glob("*a?*b?*c");
  path = "1a1b1c";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  glob = new Glob("?*a?*bcd?*def*");
  path = "xyza123bcd234def456";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  glob = new Glob("?*a?*bcd?*def*");
  path = "xyzabcd234def456";
  result = glob.match(path);
  expect(result, false, reason: glob.pattern);
}

void testCharacterClass() {
  var glob = new Glob("[0-9a]");
  var path = "5";
  var result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  path = "a";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  glob = new Glob("[!0-9]");
  path = "5";
  result = glob.match(path);
  expect(result, false, reason: glob.pattern);
  glob = new Glob("[]]");
  path = "]";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  glob = new Glob("[]-]");
  path = "-";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  path = "]";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  glob = new Glob("[--0]");
  path = "-";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  path = ".";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  path = "0";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
}

void testCanMatch() {
  var glob = new Glob("/home/foo/baz");
  var path = "/home/foo/baz";
  var result = glob.canMatch(path);
  expect(result, true, reason: glob.pattern);
  glob = new Glob("/home/**/ab*");
  path = "/home/foo/baz";
  result = glob.canMatch(path);
  expect(result, true, reason: glob.pattern);
  glob = new Glob("/home/**a*/**b*/*.txt");
  path = "/home/a1/a2/b1/b2";
  result = glob.canMatch(path);
  expect(result, true, reason: glob.pattern);
  glob = new Glob("/home/**a*/**b*/*.txt");
  path = "/home/a1/c2/b1";
  result = glob.canMatch(path);
  expect(result, false, reason: glob.pattern);
  glob = new Glob("/home/**a*/**b*/**c*/*.txt");
  path = "/home/a/ab/c";
  result = glob.canMatch(path);
  expect(result, true, reason: glob.pattern);
}

void testCrossing() {
  var glob = new Glob("/home/**/ab*");
  var path = "/home/foo/baz/abc";
  var result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  glob = new Glob("/home/**/ab*/**/def");
  path = "/home/foo/abc/123/def";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  glob = new Glob("/home/**/ab*/**/def");
  path = "/home/foo/agc/123/def";
  result = glob.match(path);
  expect(result, false, reason: glob.pattern);
  glob = new Glob("/home/**ab*/def");
  path = "/home/ab1/ab2/ab3/def";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
}

void testDotglob() {
  // TODO:
}

void testExtension() {
  var glob = new Glob("/**/*.c");
  var path = "/home/foo/baz/abc.c";
  var result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  glob = new Glob("a*.b*.*xt");
  path = "foo/abc.baz.txt";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
}
