part of globbing;

class Glob {
  final String pattern;

  bool _crossing;

  GlobPath _globPath;

  List<GlobSegment> _segments;

  // TODO: dotglob
  Glob(this.pattern) {
    if (pattern == null) {
      throw new ArgumentError("pattern: $pattern");
    }

    _parse();
  }

  /**
   * Returns true if the glob [pattern] constains the cross directoty
   * [segments].
   */
  bool get crossing {
    if (_crossing == null) {
      _crossing = false;
      for (var segment in _segments) {
        if (segment.crossing) {
          _crossing = true;
          break;
        }
      }
    }

    return _crossing;
  }

  /**
   * Returns the pattern path.
   */
  GlobPath get globPath => _globPath;

  /**
   * Returns the glob segments in this glob.
   */
  List<GlobSegment> get segments => new WrappedList(_segments);

  /**
   * Returns true if the specified [path] can be matched as a potential part of
   * the route; otherwise false.
   */
  bool canMatch(String path) {
    var matcher = new _GlobMatcher();
    return matcher.canMatch(path, _segments);
  }

  /**
   * Returns true if the specified [path] matches the glob [pattern]; otherwise
   * false.
   */
  bool match(String path) {
    var matcher = new _GlobMatcher();
    return matcher.match(path, _segments);
  }

  /**
   * Returns the string representation.
   */
  String toString() {
    return pattern;
  }

  void _parse() {
    _segments = <GlobSegment>[];
    _globPath = new GlobPath(pattern);
    for (var pathSegment in globPath.segments) {
      var parser = new _GlobParser();
      var segment = parser.parse(pathSegment);
      _segments.add(segment);
    }
  }
}

/**
 * The [GlobPath] class not intended for practical use. The main purpose of
 * this class is to standardizing the splitting paths separated by "/"
 * character.
 * This class transparently used by the other consumers of the [Glob] and
 * [GlobSegment] classes.
 */
class GlobPath {
  final String path;

  bool _isAbsolute;

  String _root;

  List<String> _segments;

  GlobPath(this.path) {
    if (path == null) {
      throw new ArgumentError("path: $path");
    }

    _parse();
  }

  /**
   * Returns true if the path is absolute.
   */
  bool get isAbsolute => _isAbsolute;

  /**
   * Returns true if path is relative.
   */
  bool get isRelative => !_isAbsolute;

  /**
   * Returns true if the path is absolute and contains only the root segment.
   * otherwise false.
   */
  bool get isRoot => _segments.length == 1 && _root != null;

  /**
   * Returns the root segment; otherwise null.
   */
  String get root => _root;

  /*
   * Returns the segments of the path.
   */
  List<String> get segments => new WrappedList(_segments);

  void _parse() {
    _isAbsolute = false;
    _segments = <String>[];
    if (path.isEmpty) {
      _segments.add("");
      return;
    }

    var position = 0;
    var charCode = path.codeUnitAt(position);
    if (charCode == Ascii.SLASH) {
      _isAbsolute = true;
      _root = "/";
      position++;
    } else if (path.length > 2) {
      if (charCode >= Ascii.A && charCode <= Ascii.Z || charCode >= Ascii.a &&
          charCode <= Ascii.z) {
        if (path.codeUnitAt(1) == Ascii.COLON) {
          if (path.codeUnitAt(2) == Ascii.SLASH || path.codeUnitAt(2) ==
              Ascii.BACKSLASH) {
            _isAbsolute = true;
            _root = path.substring(0, 2);
            position += 3;
          }
        }
      }
    }

    if (root != null) {
      _segments.add(_root);
      if(root.length == path.length) {
        return;
      }
    }

    _segments.addAll(path.substring(position).split("/"));
  }

  /**
   * Returns the string representation.
   */
  String toString() {
    return path;
  }
}

class GlobSegment {
  bool _crossing;

  _GlobRule _rule;

  /**
   *  The pattern of glob segment.
   */
  final String pattern;

  GlobSegment._internal(this.pattern, _GlobRule rule, [bool crossing = false]) {
    if (pattern == null) {
      throw new ArgumentError("pattern: $pattern");
    }

    if (rule == null) {
      throw new ArgumentError("rule: $rule");
    }

    if (crossing == null) {
      crossing = false;
    }

    _crossing = crossing;
    _rule = rule;
  }

  /**
   * Returns true if this glob segment constains the cross directoty "**"
   * mask.
   */
  bool get crossing => _crossing;

  /**
   * Returns true if the specified [pathSegment] matches the segment [pattern];
   * otherwise false.
   */
  bool match(String pathSegment) {
    var state = new _GlobState(pathSegment);
    var matches = _rule.match(state);
    if (!matches) {
      return false;
    }

    if (state.position == state.length) {
      return true;
    }

    return false;
  }

  /**
   * Returns the string representation.
   */
  String toString() {
    return pattern;
  }
}

class _GlobMatcher {
  int _patternCount;

  List<GlobSegment> _patterns;

  int _segmentCount;

  List<String> _segments;

  bool canMatch(String path, List<GlobSegment> patterns) {
    if (path == null) {
      throw new ArgumentError("path: $path");
    }

    if (patterns == null) {
      throw new ArgumentError("patterns: $patterns");
    }

    _patterns = patterns;
    _patternCount = _patterns.length;
    _segments = new GlobPath(path).segments;
    _segmentCount = _segments.length;
    return _canMatch(0, 0) == _segmentCount;
  }

  bool match(String path, List<GlobSegment> patterns) {
    if (path == null) {
      throw new ArgumentError("path: $path");
    }

    if (patterns == null) {
      throw new ArgumentError("patterns: $patterns");
    }

    _patterns = patterns;
    _segments = new GlobPath(path).segments;
    return _match(_patterns.length - 1, _segments.length - 1) == -1;
  }

  int _canMatch(int pi, int si) {
    for ( ; si < _segmentCount; pi++, si++) {
      if (pi >= _patternCount) {
        break;
      }

      var pattern = _patterns[pi];
      var segment = _segments[si];
      var matches = pattern.match(segment);
      if (!matches) {
        break;
      }

      if (pattern.crossing) {
        si++;
        var start = si;
        while (true) {
          if (si == _segmentCount) {
            break;
          }

          if (si < _segmentCount) {
            segment = _segments[si];
            if (pattern.match(segment)) {
              si++;
              continue;
            }
          }

          pi++;
          for ( ; si >= start; si--) {
            if (_canMatch(pi, si) == _segmentCount) {
              return _segmentCount;
            }
          }

          break;
        }

        break;
      }
    }

    return si;
  }

  int _match(int pi, int si) {
    for ( ; si >= 0; pi--, si--) {
      if (pi < 0) {
        break;
      }

      var pattern = _patterns[pi];
      var segment = _segments[si];
      var matches = pattern.match(segment);
      if (!matches) {
        break;
      }

      if (!pattern.crossing) {
        continue;
      }

      pi--;
      si--;
      for ( ; si >= 0; si--) {
        if (pi >= 0) {
          if (_match(pi, si) == -1) {
            return -1;
          }
        }

        if (pi < 0 && si < 0) {
          return pi;
        }

        if (si >= 0) {
          var segment = _segments[si];
          if (!pattern.match(segment)) {
            return pi;
          }
        } else {
          return pi;
        }
      }

      break;
    }

    return pi;
  }
}

class _GlobParser {
  static const int _EOF = 1;

  int _ch;

  bool _crossing;

  bool _commaDelimiter;

  String _input;

  int _length;

  int _position;

  bool get crossing => _crossing;

  GlobSegment parse(String input) {
    _input = input;
    _length = _input.length;
    _reset(0);
    var rules = _parseRules();
    _GlobRule rule;
    if(rules.length == 1) {
      rule = rules[0];
    } else {
      rule = new _GlobRuleSequence(rules);
    }

    return new GlobSegment._internal(input, rule, _crossing);
  }

  void _error(String message, int position) {
    throw new FormatException("($position), $message in '$_input'.");
  }

  int _nextChar() {
    if (_position + 1 >= _length) {
      _ch = _EOF;
      _position = _length;
      return _EOF;
    }

    _ch = _input.codeUnitAt(++_position);
    return _ch;
  }

  _GlobRuleAny _parseAny() {
    _nextChar();
    var count = 1;
    var stop = false;
    while (true) {
      switch (_ch) {
        case Ascii.QUESTION_MARK:
          _nextChar();
          count++;
          break;
        default:
          stop = true;
          break;
      }

      if (stop) {
        break;
      }
    }

    return new _GlobRuleAny(count);
  }

  _GlobRuleCharacterClass _parserCharacterClass() {
    var not = false;
    var position = _position;
    var ranges = <RangeList>[];
    _nextChar();
    if (_ch == Ascii.EXCLAMATION_MARK) {
      not = true;
      _nextChar();
    }

    if (_ch == Ascii.RIGHT_SQUARE_BRACKET) {
      var range = new RangeList(_ch, _ch);
      ranges.add(range);
      _nextChar();
    }

    var stop = false;
    while (true) {
      switch (_ch) {
        case Ascii.SLASH:
          var subject = _input.substring(position, _position + 1);
          var message =
              "Explicit '/' not allowed in character class '$subject'";
          _error(message, _position);
          break;
        case _EOF:
          var subject = _input.substring(position, _position);
          var message = "Unterminated character class '$subject'";
          _error(message, _position);
          break;
        case Ascii.RIGHT_SQUARE_BRACKET:
          _nextChar();
          stop = true;
          break;
        default:
          var range = _parseRange();
          if (range == null) {
            var subject = _input.substring(position, _position);
            var message = "Unterminated character class '$subject'";
            _error(message, _position);
          }

          if (range.start == Ascii.SLASH || range.end == Ascii.SLASH) {
            var subject = _input.substring(position, _position);
            var message =
                "Explicit '/' not allowed in character class '$subject'";
            _error(message, _position);
          }

          ranges.add(range);
          break;
      }

      if (stop) {
        break;
      }
    }

    return new _GlobRuleCharacterClass(ranges, not);
  }

  _parseChoice() {
    // TODO: choice
    throw new UnimplementedError("_parseChoice()");
  }

  _GlobRuleLiteral _parserLiteral() {
    var charCodes = <int>[];
    var position = _position;
    var stop = false;
    while (true) {
      charCodes.add(_ch);
      _nextChar();
      switch (_ch) {
        case _EOF:
        case Ascii.ASTERISK:
        case Ascii.QUESTION_MARK:
        case Ascii.LEFT_SQUARE_BRACKET:
        case Ascii.LEFT_CURLY_BRACKET:
          stop = true;
          break;
        case Ascii.BACKSLASH:
          _nextChar();
          if (_ch == _EOF) {
            var subject = _input.substring(position, _position);
            var message = "Unterminated escape sequence '$subject'";
            _error(message, _position);
          }

          break;
        case Ascii.COMMA:
          if (_commaDelimiter) {
            stop = true;
          }

          break;
      }

      if (stop) {
        break;
      }
    }

    var literal = new String.fromCharCodes(charCodes);
    return new _GlobRuleLiteral(literal);
  }

  RangeList _parseRange() {
    var end = _ch;
    var start = _ch;
    _nextChar();
    switch (_ch) {
      case Ascii.MINUS_SIGN:
        _nextChar();
        if (_ch == _EOF) {
          return null;
        } else if (_ch == Ascii.RIGHT_SQUARE_BRACKET) {
          _position -= 2;
          _nextChar();
        } else {
          end = _ch;
          _nextChar();
        }

        break;
    }

    if (start > end) {
      var start = _input[_position - 3];
      var end = _input[_position - 1];
      var subject = "$start-$end";
      var message = "Illegal range '$subject'";
      _error(message, _position - 3);
    }

    return new RangeList(start, end);
  }

  List<_GlobRule> _parseRules() {
    var rules = <_GlobRule>[];
    var stop = false;
    while (true) {
      _GlobRule rule;
      switch (_ch) {
        case Ascii.ASTERISK:
          rule = _parseZeroOrMore();
          break;
        case Ascii.QUESTION_MARK:
          rule = _parseAny();
          break;
        case Ascii.LEFT_SQUARE_BRACKET:
          rule = _parserCharacterClass();
          break;
        case Ascii.LEFT_CURLY_BRACKET:
          rule = _parseChoice();
          break;
        case _EOF:
          stop = true;
          break;
        default:
          rule = _parserLiteral();
          break;
      }

      if (stop) {
        break;
      }

      rules.add(rule);
    }

    return rules;
  }

  _GlobRuleZeroOrMore _parseZeroOrMore() {
    _nextChar();
    switch (_ch) {
      case Ascii.ASTERISK:
        _nextChar();
        _crossing = true;
        break;
    }

    var rules = _parseRules();
    return new _GlobRuleZeroOrMore(rules);
  }

  void _reset(int position) {
    _commaDelimiter = false;
    _crossing = false;
    _position = position;
    if (_position < _length) {
      _ch = _input.codeUnitAt(_position);
    } else {
      _position = _length;
      _ch = _EOF;
    }
  }
}

abstract class _GlobRule {
  bool match(_GlobState state);
}

class _GlobRuleAny extends _GlobRule {
  final count;

  _GlobRuleAny(this.count);

  bool match(_GlobState state) {
    if (state.position + count <= state.length) {
      state.position += count;
      return true;
    }

    return false;
  }
}

class _GlobRuleCharacterClass extends _GlobRule {
  final List<RangeList> ranges;

  final bool not;

  _GlobRuleCharacterClass(this.ranges, this.not);

  bool match(_GlobState state) {
    var position = state.position;
    if (position < state.length) {
      var charCode = state.intput.codeUnitAt(position);
      var length = ranges.length;
      for (var i = 0; i < length; i++) {
        var range = ranges[i];
        if (range.contains(charCode)) {
          if (not) {
            return false;
          } else {
            state.position++;
            return true;
          }
        }
      }
    }

    if (not) {
      state.position++;
      return true;
    } else {
      return false;
    }
  }
}

class _GlobRuleChoice extends _GlobRule {
  final List<_GlobRule> rules;

  _GlobRuleChoice(this.rules);

  bool match(_GlobState state) {
    var length = rules.length;
    for (var i = 0; i < length; i++) {
      var rule = rules[i];
      if (rule.match(state)) {
        return true;
      }
    }

    return false;
  }
}

class _GlobRuleLiteral extends _GlobRule {
  final String literal;

  _GlobRuleLiteral(this.literal);

  bool match(_GlobState state) {
    var count = literal.length;
    var length = state.length;
    var position = state.position;
    if (position + count <= length) {
      var input = state.intput;
      var matches = true;
      for (var i = 0; i < count; i++) {
        var charCode = literal.codeUnitAt(i);
        if (charCode != input.codeUnitAt(position + i)) {
          return false;
        }
      }
    } else {
      return false;
    }

    state.position += count;
    return true;
  }
}

class _GlobRuleSequence extends _GlobRule {
  final List<_GlobRule> rules;

  _GlobRuleSequence(this.rules);

  bool match(_GlobState state) {
    var count = rules.length;
    var matches = true;
    var position = state.position;
    for (var i = 0; i < count; i++) {
      var rule = rules[i];
      if (!rule.match(state)) {
        matches = false;
        break;
      }
    }

    if (!matches) {
      state.position = position;
      return false;
    }

    return true;
  }
}

class _GlobRuleZeroOrMore extends _GlobRule {
  final List<_GlobRule> rules;

  _GlobRuleZeroOrMore(this.rules);

  bool match(_GlobState state) {
    var count = rules.length;
    if (count == 0) {
      state.position = state.length;
      return true;
    }

    var length = state.length;
    var position = state.position;
    for (var i = length - 1; i >= position; i--) {
      var matches = true;
      state.position = i;
      for (var i = 0; i < count; i++) {
        var rule = rules[i];
        if (!rule.match(state)) {
          matches = false;
          break;
        }
      }

      if (matches) {
        return true;
      }
    }

    state.position = position;
    return false;
  }
}

class _GlobState {
  final String intput;

  int length;

  int position = 0;

  _GlobState(String input)
      : this.intput = input,
        this.length = input.length;
}
