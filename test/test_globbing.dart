import "package:globbing/globbing.dart";
import "package:unittest/unittest.dart";

void main() {
  new Glob("[!a]");
  test();
  testCharacterClass();
  testChoice();
  testCrossing();
  testDotglob();
  testEscape();
  testExtension();
  testMetachars();
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
  // "[0-9a]"
  var glob = new Glob("[0-9a]");
  var path = "5";
  var result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  path = "a";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);

  // "[!0-9]"
  glob = new Glob("[!0-9]");
  path = "5";
  result = glob.match(path);
  expect(result, false, reason: glob.pattern);

  // "[-]"
  glob = new Glob("[-]");
  path = "-";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);

  // "[]]"
  glob = new Glob("[]]");
  path = "]";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);

  // "[]-]"
  glob = new Glob("[]-]");
  path = "-";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  path = "]";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);

  // "[--0]"
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

void testChoice() {
  // "a{b,c,}"
  var glob = new Glob("a{b,c,}");
  var list = ["a", "ab", "ac"];
  for(var path in list) {
    var result = glob.match(path);
      expect(result, true, reason: path);
  }
}

void testCrossing() {
  // "/home/**/ab*"
  var glob = new Glob("/home/**/ab*");
  var path = "/home/foo/baz/abc";
  var result = glob.match(path);
  expect(result, true, reason: glob.pattern);

  // "/home/**/ab*/**/def"
  glob = new Glob("/home/**/ab*/**/def");
  path = "/home/foo/abc/123/def";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);

  // "/home/**/ab*/**/def"
  glob = new Glob("/home/**/ab*/**/def");
  path = "/home/foo/agc/123/def";
  result = glob.match(path);
  expect(result, false, reason: glob.pattern);

  // "/home/**ab*/def"
  glob = new Glob("/home/**ab*/def");
  path = "/home/ab1/ab2/ab3/def";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
}

void testDotglob() {
  // *
  var glob = new Glob("*");
  var path = ".hidden";
  var result = glob.match(path);
  expect(result, false, reason: glob.pattern);
  // .*
  glob = new Glob(".*");
  path = ".hidden";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
  // **
  /*
  glob = new Glob("*");
  path = ".hidden/.hidden";
  result = glob.match(path);
  expect(result, false, reason: glob.pattern);
  */
}

void testEscape() {
  // '*'
  var glob = new Glob(r"\*");
  var path = "*";
  var result = glob.match(path);
  expect(result, true, reason: glob.pattern);

  // '?'
  glob = new Glob(r"\?");
  path = "?";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);

  // '['
  glob = new Glob(r"\[");
  path = "[";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);

  // '{'
  glob = new Glob(r"\{");
  path = "{";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
}

void testExtension() {
  // "*.h"
  var glob = new Glob("*.h");
  var path = "stdio.h";
  var result = glob.match(path);
  expect(result, true, reason: glob.pattern);

  // "a*.b*.*xt"
  glob = new Glob("foo/a*.b*.*xt");
  path = "foo/abc.baz.txt";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
}

void testMetachars() {
  // '('
  var glob = new Glob("(");
  var path = "(";
  var result = glob.match(path);
  expect(result, true, reason: glob.pattern);

  // '\s'
  glob = new Glob("\s");
  path = "s";
  result = glob.match(path);
  expect(result, true, reason: glob.pattern);
}