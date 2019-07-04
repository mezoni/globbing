import "package:globbing/globbing.dart";
import "package:test/test.dart";

void main() {
  Glob("[!a]");
  _testCommon();
  _testCharacterClass();
  _testChoice();
  _testCrossing();
  _testDotGlob();
  _testEscape();
  _testExtension();
  _testMetachars();
}

void _testCommon() {
  test("", () {
    {
      var glob = Glob("c?*a");
      var path = "c1a";
      var result1 = glob.match(path);
      expect(result1, true, reason: glob.pattern);
      path = "c123a";
      var result2 = glob.match(path);
      expect(result2, true, reason: glob.pattern);
      path = "ca";
      var result3 = glob.match(path);
      expect(result3, false, reason: glob.pattern);
    }
    {
      var glob = Glob("a*b*c");
      var path = "abc";
      var result1 = glob.match(path);
      expect(result1, true, reason: glob.pattern);
      path = "a1b1c";
      var result2 = glob.match(path);
      expect(result2, true, reason: glob.pattern);
    }
    {
      var glob = Glob("*a*b*c");
      var path = "abc";
      var result1 = glob.match(path);
      expect(result1, true, reason: glob.pattern);
      path = "1a1b1c";
      var result2 = glob.match(path);
      expect(result2, true, reason: glob.pattern);
    }
    {
      var glob = Glob("*a?*b?*c");
      var path = "1a1b1c";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      var glob = Glob("?*a?*bcd?*def*");
      var path = "xyza123bcd234def456";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      var glob = Glob("?*a?*bcd?*def*");
      var path = "xyzabcd234def456";
      var result = glob.match(path);
      expect(result, false, reason: glob.pattern);
    }
  });
}

void _testCharacterClass() {
  test("CharacterClass", () {
    {
      var glob = Glob("[0-9a]");
      var path = "5";
      var result1 = glob.match(path);
      expect(result1, true, reason: glob.pattern);
      path = "a";
      var result2 = glob.match(path);
      expect(result2, true, reason: glob.pattern);
    }
    {
      var glob = Glob("[!0-9]");
      var path = "5";
      var result = glob.match(path);
      expect(result, false, reason: glob.pattern);
    }

    {
      var glob = Glob("[-]");
      var path = "-";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }

    {
      var glob = Glob("[]]");
      var path = "]";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }

    {
      var glob = Glob("[]-]");
      var path = "-";
      var result1 = glob.match(path);
      expect(result1, true, reason: glob.pattern);
      path = "]";
      var result2 = glob.match(path);
      expect(result2, true, reason: glob.pattern);
    }

    {
      var glob = Glob("[--0]");
      var path = "-";
      var result1 = glob.match(path);
      expect(result1, true, reason: glob.pattern);
      path = ".";
      var result2 = glob.match(path);
      expect(result2, true, reason: glob.pattern);
      path = "0";
      var result3 = glob.match(path);
      expect(result3, true, reason: glob.pattern);
    }
  });
}

void _testChoice() {
  test("Choice", () {
    {
      var glob = Glob("a{b,c,}");
      var list = ["a", "ab", "ac"];
      for (var path in list) {
        var result = glob.match(path);
        expect(result, true, reason: path);
      }
    }
  });
}

void _testCrossing() {
  test("Crossing", () {
    {
      var glob = Glob("/home/**/ab*");
      var path = "/home/foo/baz/abc";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      var glob = Glob("/home/**/ab*/**/def");
      var path = "/home/foo/abc/123/def";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      var glob = Glob("/home/**/ab*/**/def");
      var path = "/home/foo/agc/123/def";
      var result = glob.match(path);
      expect(result, false, reason: glob.pattern);
    }
    {
      var glob = Glob("/home/**ab*/def");
      var path = "/home/ab1/ab2/ab3/def";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
  });
}

void _testDotGlob() {
  test("Dotglob", () {
    {
      var glob = Glob("*");
      var path = ".hidden";
      var result = glob.match(path);
      expect(result, false, reason: glob.pattern);
    }
    {
      var glob = Glob(".*");
      var path = ".hidden";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      var glob = Glob("*");
      var path = ".hidden/.hidden";
      var result = glob.match(path);
      expect(result, false, reason: glob.pattern);
    }
  });
}

void _testEscape() {
  test("Escape", () {
    {
      var glob = Glob(r"\*");
      var path = "*";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      var glob = Glob(r"\?");
      var path = "?";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      var glob = Glob(r"\[");
      var path = "[";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      var glob = Glob(r"\{");
      var path = "{";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
  });
}

void _testExtension() {
  test("Extension", () {
    {
      var glob = Glob("*.h");
      var path = "stdio.h";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      var glob = Glob("foo/a*.b*.*xt");
      var path = "foo/abc.baz.txt";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
  });
}

void _testMetachars() {
  test("Metachars", () {
    {
      var glob = Glob("(");
      var path = "(";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
    {
      var glob = Glob("\s");
      var path = "s";
      var result = glob.match(path);
      expect(result, true, reason: glob.pattern);
    }
  });
}
