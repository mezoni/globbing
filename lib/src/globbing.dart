part of globbing;

class Glob implements Pattern {
  final bool caseSensitive;

  final String pattern;

  bool _crossesDirectory;

  Pattern _expression;

  bool _isAbsolute;

  List<GlobSegment> _segments;

  Glob(this.pattern, {this.caseSensitive: true}) {
    if (pattern == null) {
      throw new ArgumentError("pattern: $pattern");
    }

    if (caseSensitive == null) {
      throw new ArgumentError("caseSensitive: $caseSensitive");
    }

    _compile(caseSensitive);
  }

  /**
   * Returns true if the glob [pattern] constains the segments that crosses
   * the directoty.
   */
  bool get crossesDirectory => _crossesDirectory;

  /**
   * Returns true if glob [pattern] is an absolute path; otherwise false;   *
   */
  bool get isAbsolute => _isAbsolute;

  /**
   * Returns the glob segments.
   */
  List<GlobSegment> get segments => _segments;

  Iterable<Match> allMatches(String str) {
    return _expression.allMatches(str);
  }

  /**
   * Returns true if pattern matches thes string.
   */
  bool match(String string) {
    return !allMatches(string).isEmpty;
  }

  Match matchAsPrefix(String string, [int start = 0]) {
    return _expression.matchAsPrefix(string, start);
  }

  /**
   * Returns the string representation.
   */
  String toString() {
    return pattern;
  }

  void _compile(bool caseSensitive) {
    var compiler = new _GlobCompiler();
    var result = compiler.compile(pattern, caseSensitive: caseSensitive);
    _crossesDirectory = result.crossesDirectory;
    _expression = result.expression;
    _isAbsolute = result.isAbsolute;
    _segments = result.segments;
  }
}

class GlobSegment implements Pattern {
  Pattern _expression;

  /**
   * True if the segment crosses the directory.
   */
  final bool crossesDirectory;

  /**
   * True if segment should match only directory.
   */
  final bool onlyDirectory;

  /**
   * Original glob pattern.
   */
  final String pattern;

  /**
   * True if the segment pattern contains no wildcards '*', '?', no character
   * classes '[]', no choices '{}'; otherwise false;
   * false.
   */
  final bool strict;

  GlobSegment(this.pattern, Pattern
      expression, {this.crossesDirectory, this.onlyDirectory, this.strict}) {
    if (pattern == null) {
      throw new ArgumentError("pattern: $pattern");
    }

    if (expression == null) {
      throw new ArgumentError("expression: $expression");
    }

    if (crossesDirectory == null) {
      throw new ArgumentError("crossing: $crossesDirectory");
    }

    if (strict == null) {
      throw new ArgumentError("strict: $strict");
    }

    if (onlyDirectory == null) {
      throw new ArgumentError("trailingSlash: $onlyDirectory");
    }

    _expression = expression;
  }

  Iterable<Match> allMatches(String str) {
    return _expression.allMatches(str);
  }

  /**
   * Returns true if pattern matches thes string.
   */
  bool match(String string) {
    return !allMatches(string).isEmpty;
  }

  Match matchAsPrefix(String string, [int start = 0]) {
    return _expression.matchAsPrefix(string, start);
  }

  /**
   * Returns the string representation.
   */
  String toString() {
    return pattern;
  }
}

class _GlobCompiler {
  static const String _EOF = "";

  static const String _MESSAGE_CANNOT_ESCAPE_SLASH_CHARACTER =
      "Cannot escape slash '/' character";

  static const String _MESSAGE_CHOICE_SHOULD_CONTAINS_AT_LEAST_TWO_ELEMENTS =
      "Choice should contains at least two elements";

  static const String _MESSAGE_CROSSING_DIRECTORY_NOT_ALLOWED_IN_CHOICE =
      "Crossing the directory '**' not allowed in choice";

  static const String _MESSAGE_RANGE_OUT_OF_ORDER_IN_CHARACTER_CLASS =
      "Range out of order in character class";

  static const String _MESSAGE_SLASH_NOT_ALLOWED_IN_CHARACTER_CLASS =
      "Explicit slash '/' not allowed in character class";

  static const String _MESSAGE_SLASH_NOT_ALLOWED_IN_CHOICE =
      "Explicit slash '/' not allowed in choice";

  static const String _MESSAGE_UNTERMINATED_BACKSLASH_SEQUENCE =
      "Unterminated backslash '\\' escape sequence";

  static const String _MESSAGE_UNEXPECTED_END_OF_CHARACTER_CLASS =
      "Unexpected end of character class";

  static const String _MESSAGE_UNEXPECTED_END_OF_CHOICE =
      "Unexpected end of choice";

  Pattern expression;

  bool _caseSensitive;

  String _ch;

  bool _firstInSegment;

  StringBuffer _gbuf;

  bool _globCrossing;

  bool _globStrict;

  String _input;

  bool _insideChoice;

  bool _isAbsolute;

  int _length;

  int _position;

  StringBuffer _sbuf;

  bool _segmentCrossing;

  List<GlobSegment> _segments;

  int _segmentStart;

  bool _segmentStrict;

  _GlobCompilerResult compile(String input, {bool caseSensitive: true}) {
    if (input == null) {
      throw new ArgumentError("input: $input");
    }

    this._input = input;
    this._caseSensitive = caseSensitive;
    _reset();
    _parse();
    var source = _gbuf.toString();
    var result = new _GlobCompilerResult();
    result.crossesDirectory = _globCrossing;
    result.expression = new RegExp(source, caseSensitive: caseSensitive);
    result.isAbsolute = _isAbsolute;
    result.segments = _segments;
    return result;
  }

  bool _alpha(String s) {
    if (s.isEmpty) {
      return false;
    }

    var c = s.codeUnitAt(0);
    if (c >= 65 && c <= 90 || c >= 97 && c <= 122) {
      return true;
    }

    return false;
  }

  GlobSegment _createSegment() {
    if (_segmentCrossing) {
      _globCrossing = true;
    }

    if (!_segmentStrict) {
      _globStrict = false;
    }

    var text = _input.substring(_segmentStart, _position);
    var trailingSlash = false;
    if (_ch == "/") {
      while (true) {
        _nextChar();
        if (_ch != "/") {
          break;
        }
      }

      _gbuf.write("/");
      if (_ch == _EOF) {
        trailingSlash = true;
      }
    }

    _sbuf.write("\$");
    var source = _sbuf.toString();
    var expression = new RegExp(source, caseSensitive: _caseSensitive);
    var segment = new GlobSegment(text, expression, crossesDirectory:
        _segmentCrossing, strict: _segmentStrict, onlyDirectory: trailingSlash);
    _segments.add(segment);
    _resetSegment();
    return segment;
  }

  void _error(String message, int position) {
    throw new FormatException(
        "(column: ${position + 1}), $message in '$_input'.");
  }

  int _escapeRangeCharacter() {
    int charCode;
    switch (_ch) {
      case _EOF:
        var message = _MESSAGE_UNEXPECTED_END_OF_CHARACTER_CLASS;
        _error(message, _position - 1);
        break;
      case "/":
        var message = _MESSAGE_SLASH_NOT_ALLOWED_IN_CHARACTER_CLASS;
        _error(message, _position);
        break;
      case "\\":
        _nextChar();
        switch (_ch) {
          case _EOF:
            var message = _MESSAGE_UNTERMINATED_BACKSLASH_SEQUENCE;
            _error(message, _position - 1);
            break;
          case "/":
            var message = _MESSAGE_SLASH_NOT_ALLOWED_IN_CHARACTER_CLASS;
            _error(message, _position);
            break;
          default:
            charCode = _ch.codeUnitAt(0);
            _write("\\");
            _write(_ch);
            _nextChar();
            break;
        }

        break;
      case "^":
        charCode = _ch.codeUnitAt(0);
        _write("\\");
        _write(_ch);
        _nextChar();
        break;
      default:
        charCode = _ch.codeUnitAt(0);
        _write(_ch);
        _nextChar();
        break;
    }

    return charCode;
  }

  String _lookup(int offset) {
    var position = _position + offset;
    if (position < _length) {
      return _input[position];
    }

    return _EOF;
  }

  String _nextChar() {
    if (_position + 1 >= _length) {
      _ch = _EOF;
      _position = _length;
      return _EOF;
    }

    _ch = _input[++_position];
    return _ch;
  }

  void _parse() {
    _gbuf.write("^");
    switch (_ch) {
      case _EOF:
        break;
      case "/":
        _write("/");
        while (true) {
          _nextChar();
          if (_ch != "/") {
            break;
          }
        }

        _isAbsolute = true;
        _createSegment();
        break;
      default:
        if (_alpha(_ch) && _lookup(1) == ":" && _lookup(2) == "/") {
          _write(_ch);
          _write(":/");
          _isAbsolute = true;
          _position += 2;
          _nextChar();
          _createSegment();
        }

        break;
    }

    if (_ch != _EOF) {
      _parseSegments();
    }

    _gbuf.write("\$");
  }

  void _parseCharacterClass() {
    _nextChar();
    _firstInSegment = false;
    _segmentStrict = false;
    var position = _position;
    _write("[");
    if (_ch == "!") {
      _write("^");
      _nextChar();
    }

    if (_ch == "]") {
      _write("\\]-\\]'");
      _nextChar();
    }

    var stop = false;
    while (true) {
      switch (_ch) {
        case "/":
          var message = _MESSAGE_SLASH_NOT_ALLOWED_IN_CHARACTER_CLASS;
          _error(message, _position);
          break;
        case _EOF:
          var message = _MESSAGE_UNEXPECTED_END_OF_CHARACTER_CLASS;
          _error(message, _position);
          break;
        case "]":
          _nextChar();
          stop = true;
          break;
        default:
          _parseRange();
          break;
      }

      if (stop) {
        break;
      }
    }

    _write("]");
  }

  void _parseChoice() {
    _nextChar();
    _segmentStrict = false;
    _write("(?:");
    var empty = true;
    var insideChoice = _insideChoice;
    var firstInSegment = _firstInSegment;
    var stop = false;
    _insideChoice = true;
    while (true) {
      switch (_ch) {
        case _EOF:
          var message = _MESSAGE_UNEXPECTED_END_OF_CHOICE;
          _error(message, _position - 1);
          break;
        case "/":
          var message = _MESSAGE_SLASH_NOT_ALLOWED_IN_CHOICE;
          _error(message, _position);
          break;
        case ",":
          _nextChar();
          _write("|");
          if (_ch == "}") {
            _nextChar();
            stop = true;
          } else {
            _firstInSegment = firstInSegment;
          }

          empty = false;
          break;
        case "}":
          _nextChar();
          stop = true;
          break;
        default:
          _parseChoiceElement();
          break;
      }

      if (stop) {
        break;
      }
    }

    if (empty) {
      var message = _MESSAGE_CHOICE_SHOULD_CONTAINS_AT_LEAST_TWO_ELEMENTS;
      _error(message, _position - 1);
    }

    _insideChoice = insideChoice;
    _write(")");
  }

  void _parseChoiceElement() {
    switch (_ch) {
      case "*":
        _parseZeroOrMore();
        break;
      case "?":
        _parseOneOrMore();
        break;
      case "[":
        _parseCharacterClass();
        break;
      case "{":
        _parseChoice();
        break;
      default:
        _parseLiteral();
        break;
    }
  }

  void _parseLiteral() {
    _firstInSegment = false;
    var stop = false;
    while (true) {
      switch (_ch) {
        case _EOF:
        case "*":
        case "{":
        case "[":
        case "}":
        case "?":
        case "/":
          stop = true;
          break;
        case ",":
          if (_insideChoice) {
            stop = true;
          } else {
            _write(_ch);
            _nextChar();
          }

          break;
        case "\\":
          _nextChar();
          if (_ch == _EOF) {
            var message = _MESSAGE_UNTERMINATED_BACKSLASH_SEQUENCE;
            _error(message, _position - 1);
          }

          switch (_ch) {
            case "/":
              var message = _MESSAGE_CANNOT_ESCAPE_SLASH_CHARACTER;
              _error(message, _position);
              break;
            case "*":
            case "{":
            case "[":
            case "?":
            case "}":
              _write("\\");
              _write(_ch);
              _nextChar();
              break;
            case "\\":
              _write("\\");
              _write(_ch);
              _nextChar();
              break;
            default:
              break;
          }

          break;
        case "^":
        case "\$":
        case "(":
        case ".":
        case "+":
        case ")":
        case "|":
          _write("\\");
          _write(_ch);
          _nextChar();
          break;
        default:
          _write(_ch);
          _nextChar();
          break;
      }

      if (stop) {
        break;
      }
    }
  }

  void _parseOneOrMore() {
    _firstInSegment = false;
    _segmentStrict = false;
    var count = 1;
    while (true) {
      _nextChar();
      if (_ch != "?") {
        break;
      }

      count++;
    }

    _write(".{");
    _write(count.toRadixString(10));
    _write("}");
  }

  void _parseRange() {
    var position = _position;
    var start = _escapeRangeCharacter();
    var end = start;
    switch (_ch) {
      case "-":
        _nextChar();
        if (_ch == _EOF) {
          var message = _MESSAGE_UNEXPECTED_END_OF_CHARACTER_CLASS;
          _error(message, _position - 1);
          return;
        } else if (_ch == "]") {
          _position -= 2;
          _nextChar();
        } else {
          _write("-");
          end = _escapeRangeCharacter();
        }

        break;
    }

    if (start > end) {
      var message = _MESSAGE_RANGE_OUT_OF_ORDER_IN_CHARACTER_CLASS;
      _error(message, position);
    }
  }

  void _parseSegment() {
    var stop = false;
    while (true) {
      switch (_ch) {
        case _EOF:
        case "/":
          stop = true;
          break;
        case "*":
          _parseZeroOrMore();
          break;
        case "?":
          _parseOneOrMore();
          break;
        case "[":
          _parseCharacterClass();
          break;
        case "{":
          _parseChoice();
          break;
        default:
          _parseLiteral();
          break;
      }

      if (stop) {
        break;
      }
    }
  }

  void _parseSegments() {
    var stop = false;
    while (true) {
      _parseSegment();
      _createSegment();
      switch (_ch) {
        case _EOF:
          stop = true;
          break;
      }

      if (stop) {
        break;
      }
    }
  }

  void _parseZeroOrMore() {
    _nextChar();
    _segmentStrict = false;
    var crossing = false;
    switch (_ch) {
      case "*":
        if (_insideChoice) {
          var message = _MESSAGE_CROSSING_DIRECTORY_NOT_ALLOWED_IN_CHOICE;
          _error(message, _position - 1);
        }

        crossing = true;
        while (true) {
          _nextChar();
          if (_ch != "*") {
            break;
          }
        }

        crossing = true;
        break;
    }

    if (_firstInSegment) {
      _write("(?![.])");
    }

    if (crossing) {
      _segmentCrossing = true;
      _write(".*");
    } else {
      _write("[^/]*");
    }

    _firstInSegment = false;
  }

  void _reset() {
    expression = null;
    _globCrossing = false;
    _insideChoice = false;
    _isAbsolute = false;
    _gbuf = new StringBuffer();
    _globStrict = true;
    _length = _input.length;
    _position = 0;
    _segments = <GlobSegment>[];
    if (_position < _length) {
      _ch = _input[_position];
    } else {
      _position = _length;
      _ch = _EOF;
    }

    _resetSegment();
  }

  void _resetSegment() {
    _firstInSegment = true;
    _sbuf = new StringBuffer();
    _sbuf.write("^");
    _segmentCrossing = false;
    _segmentStart = _position;
    _segmentStrict = true;
  }

  void _write(String string) {
    _gbuf.write(string);
    _sbuf.write(string);
  }
}

class _GlobCompilerResult {
  bool isAbsolute;

  bool crossesDirectory;

  Pattern expression;

  List<GlobSegment> segments;
}
