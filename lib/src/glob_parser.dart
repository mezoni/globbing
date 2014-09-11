part of globbing.glob_parser;

abstract class GlobNode {
  /**
   * Text source of this node;
   */
  final String source;

  /**
   * Start position of this node in the source.
   */
  final int position;

  GlobNode(this.source, this.position) {
    if (source == null) {
      throw new ArgumentError("source: $source");
    }

    if (position == null) {
      throw new ArgumentError("position: $position");
    }
  }

  /**
   * Returns true if node crosses directory; otherwise false.
   */
  bool get crossesDirectory;

  /**
   * Returns true if node is strict; otherwise false.
   */
  bool get strict;

  /**
   * Returns type of this node.
   */
  GlobNodeTypes get type;

  /**
   * Returns srting representation.
   */
  String toString() {
    return source;
  }
}

class GlobNodeAsterisk extends GlobNode {
  GlobNodeAsterisk(String source, int position): super(source, position);

  /**
   * Returns true if node crosses directory; otherwise false.
   */
  bool get crossesDirectory => false;

  /**
   * Returns true if node is strict; otherwise false.
   */
  bool get strict => false;

  /**
   * Returns type of this node.
   */
  GlobNodeTypes get type => GlobNodeTypes.ASTERISK;
}

class GlobNodeAsterisks extends GlobNode {
  GlobNodeAsterisks(String source, int position): super(source, position);

  /**
   * Returns true if node crosses directory; otherwise false.
   */
  bool get crossesDirectory => true;

  /**
   * Returns true if node is strict; otherwise false.
   */
  bool get strict => false;

  /**
   * Returns type of this node.
   */
  GlobNodeTypes get type => GlobNodeTypes.ASTERISKS;
}

class GlobNodeAsterisksSlash extends GlobNode {
  GlobNodeAsterisksSlash(String source, int position): super(source, position);

  /**
   * Returns true if node crosses directory; otherwise false.
   */
  bool get crossesDirectory => true;

  /**
   * Returns true if node is strict; otherwise false.
   */
  bool get strict => false;

  /**
   * Returns type of this node.
   */
  GlobNodeTypes get type => GlobNodeTypes.ASTERISKS_SLASH;
}

class GlobNodeBrace extends GlobNodeCollection {

  GlobNodeBrace(String source, int position, List<GlobNode> nodes): super(
      source, position, nodes) {
    if (_nodes.length < 2) {
      throw new ArgumentError(
          "The number of elements in the list of nodes must be at least 2");
    }
  }

  /**
   * Returns true if node is strict; otherwise false.
   */
  bool get strict => false;

  /**
   * Returns type of this node.
   */
  GlobNodeTypes get type => GlobNodeTypes.BRACE;
}

class GlobNodeCharacterClass extends GlobNode {
  GlobNodeCharacterClass(String source, int position): super(source, position) {
    if (source == null || source.length < 3) {
      throw new ArgumentError("source: $source");
    }

    if (source[0] != "[" || source[source.length - 1] != "]") {
      throw new ArgumentError("source: $source");
    }
  }

  /**
   * Returns true if node crosses directory; otherwise false.
   */
  bool get crossesDirectory => false;

  /**
   * Returns true if node is strict; otherwise false.
   */
  bool get strict => false;

  /**
   * Returns type of this node.
   */
  GlobNodeTypes get type => GlobNodeTypes.CHARACTER_CLASS;
}

abstract class GlobNodeCollection extends GlobNode {
  bool _crossesDirectory;

  List<GlobNode> _nodes;

  bool _strict;

  GlobNodeCollection(String source, int position, List<GlobNode> nodes): super(
      source, position) {
    if (nodes == null || nodes.isEmpty) {
      throw new ArgumentError("nodes: $nodes");
    }

    for (var node in nodes) {
      if (node is! GlobNode) {
        throw new ArgumentError("List of nodes contains invalid elements.");
      }
    }

    _nodes = nodes.toList();
  }

  /**
   * Returns true if node crosses directory; otherwise false.
   */
  bool get crossesDirectory {
    if (_crossesDirectory == null) {
      _crossesDirectory = false;
      for (var node in _nodes) {
        if (node.crossesDirectory) {
          _crossesDirectory = true;
          break;
        }
      }
    }

    return _crossesDirectory;
  }

  /**
   * Returns elements of this node.
   */
  List<GlobNode> get nodes => new UnmodifiableListView<GlobNode>(_nodes);

  /**
   * Returns true if node is strict; otherwise false.
   */
  bool get strict {
    if (_strict == null) {
      _strict = true;
      for (var node in _nodes) {
        if (!node.strict) {
          _strict = false;
          break;
        }
      }
    }

    return _strict;
  }
}

class GlobNodeLiteral extends GlobNode {
  GlobNodeLiteral(String source, int position): super(source, position);

  /**
   * Returns true if node crosses directory; otherwise false.
   */
  bool get crossesDirectory => false;

  /**
   * Returns true if node is strict; otherwise false.
   */
  bool get strict => true;

  /**
   * Returns the type of this node.
   */
  GlobNodeTypes get type => GlobNodeTypes.LITERAL;
}

class GlobNodeQuestion extends GlobNode {
  GlobNodeQuestion(String source, int position): super(source, position);

  /**
   * Returns true if node crosses directory; otherwise false.
   */
  bool get crossesDirectory => false;

  /**
   * Returns true if node is strict; otherwise false.
   */
  bool get strict => false;

  /**
   * Returns the type of this node.
   */
  GlobNodeTypes get type => GlobNodeTypes.QUESTION;
}

class GlobNodeSegment extends GlobNodeCollection {
  bool _isRoot;

  bool _onlyDirectory;

  GlobNodeSegment(String source, int position, bool isRoot, List<GlobNode>
      nodes): super(source, position, nodes) {
    if (isRoot == null) {
      throw new ArgumentError("isRoot: $isRoot");
    }

    _isRoot = isRoot;
  }

  /**
   * Returns true if node if is a root segment; otherwise false.
   */
  bool get isRoot => _isRoot;

  /**
   * Returns true if node matches only directory; otherwise false.
   */
  bool get onlyDirectory {
    if (_onlyDirectory == null) {
      _onlyDirectory = false;
      if (!_isRoot) {
        var last = _nodes.last;
        if (last is GlobNodeLiteral) {
          _onlyDirectory = last.source.endsWith("/");
        }
      }
    }

    return _onlyDirectory;
  }

  GlobNodeTypes get type => GlobNodeTypes.SEGMENT;
}

class GlobNodeSegments extends GlobNodeCollection {
  bool _isAbsolute;

  List<GlobNodeSegment> _nodes;

  GlobNodeSegments(String source, int position, List<GlobNodeSegment> nodes):
      super(source, position, nodes);

  /**
   * Returns true if node if is an absolute path; otherwise false.
   */
  bool get isAbsolute {
    if (_isAbsolute == null) {
      _isAbsolute = _nodes.first.isRoot;
    }

    return _isAbsolute;
  }

  /**
   * Returns the elements of this node.
   */
  List<GlobNodeSegment> get nodes => new UnmodifiableListView<GlobNodeSegment>(
      _nodes);

  /**
   * Returns the type of this node.
   */
  GlobNodeTypes get type => GlobNodeTypes.SEGMENTS;
}

class GlobNodeTypes {
  static const GlobNodeTypes ASTERISK = const GlobNodeTypes("ASTERISK");

  static const GlobNodeTypes ASTERISKS = const GlobNodeTypes("ASTERISKS");

  static const GlobNodeTypes ASTERISKS_SLASH = const GlobNodeTypes(
      "ASTERISKS_SLASH");

  static const GlobNodeTypes BRACE = const GlobNodeTypes("BRACE");

  static const GlobNodeTypes CHARACTER_CLASS = const GlobNodeTypes(
      "CHARACTER_CLASS");

  static const GlobNodeTypes LITERAL = const GlobNodeTypes("LITERAL");

  static const GlobNodeTypes QUESTION = const GlobNodeTypes("QUESTION");

  static const GlobNodeTypes SEGMENT = const GlobNodeTypes("SEGMENT");

  static const GlobNodeTypes SEGMENTS = const GlobNodeTypes("SEGMENTS");

  final String name;

  const GlobNodeTypes(this.name);
}

class GlobParser {
  static const String _EOF = "";

  static const String _MESSAGE_CANNOT_ESCAPE_SLASH_CHARACTER =
      "Cannot escape slash '/' character";

  static const String _MESSAGE_CHOICE_SHOULD_CONTAINS_AT_LEAST_TWO_ELEMENTS =
      "Choice should contains at least two elements";

  static const String _MESSAGE_RANGE_OUT_OF_ORDER_IN_CHARACTER_CLASS =
      "Range out of order in character class";

  static const String _MESSAGE_SLASH_NOT_ALLOWED_IN_CHARACTER_CLASS =
      "Explicit slash '/' not allowed in character class";

  static const String _MESSAGE_SLASH_NOT_ALLOWED_IN_BRACE =
      "Explicit slash '/' not allowed in brace";

  static const String _MESSAGE_UNTERMINATED_BACKSLASH_SEQUENCE =
      "Unterminated backslash '\\' escape sequence";

  static const String _MESSAGE_UNEXPECTED_END_OF_CHARACTER_CLASS =
      "Unexpected end of character class";

  static const String _MESSAGE_UNEXPECTED_END_OF_BRACE =
      "Unexpected end of brace";

  GlobParser({gitignoreSemantics: false}) {
    if (gitignoreSemantics == null) {
      throw new ArgumentError("gitignoreSemantics: gitignoreSemantics");
    }

    _gitignoreSemantics = gitignoreSemantics;
  }

  String _ch;

  String _input;

  bool _insideChoice;

  bool _isRoot;

  bool _gitignoreSemantics;

  int _length;

  int _position;

  List<GlobNode> _rules;

  List<GlobNodeSegment> _segments;

  int _segmentStart;

  GlobNodeSegments parse(String input) {
    if (input == null) {
      throw new ArgumentError("input: $input");
    }

    if (input.isEmpty) {
      var literal = new GlobNodeLiteral("", 0);
      var segment = new GlobNodeSegment("", 0, false, [literal]);
      return new GlobNodeSegments("", 0, [segment]);
    }

    this._input = input;
    _reset();
    _parse();
    return new GlobNodeSegments(_input, 0, _segments);
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

  GlobNodeSegment _createSegment() {
    var start = _position;
    var source = _input.substring(_segmentStart, _position);
    var trailingSlash = false;
    if (_ch == "/") {
      while (true) {
        _nextChar();
        if (_ch != "/") {
          break;
        }
      }

      if (_ch == _EOF && !_isRoot) {
        trailingSlash = true;
      }
    }

    if (trailingSlash) {
      source += "/";
      if (!_rules.isEmpty) {
        var last = _rules.last;
        if (last is GlobNodeLiteral) {
          var rule = new GlobNodeLiteral(last.source + "/", last.position);
          _rules[_rules.length - 1] = rule;
        } else {
          var rule = new GlobNodeLiteral("/", start);
          _rules.add(rule);
        }
      }
    }

    var segment = new GlobNodeSegment(source, _segmentStart, _isRoot, _rules);
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
        _error(message, _position);
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
            _error(message, _position);
            break;
          case "/":
            var message = _MESSAGE_SLASH_NOT_ALLOWED_IN_CHARACTER_CLASS;
            _error(message, _position);
            break;
          default:
            charCode = _ch.codeUnitAt(0);
            _nextChar();
            break;
        }

        break;
      case "^":
        charCode = _ch.codeUnitAt(0);
        _nextChar();
        break;
      default:
        charCode = _ch.codeUnitAt(0);
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
    switch (_ch) {
      case _EOF:
        break;
      case "/":
        _nextChar();
        _isRoot = true;
        var rule = new GlobNodeLiteral("/", 0);
        _rules.add(rule);
        var segment = _createSegment();
        _segments.add(segment);
        break;
      default:
        if (_alpha(_ch) && _lookup(1) == ":" && _lookup(2) == "/") {
          _isRoot = true;
          _position += 2;
          _nextChar();
          var source = _input.substring(0, 3);
          var rule = new GlobNodeLiteral(source, 0);
          _rules.add(rule);
          var segment = _createSegment();
          _segments.add(segment);
        }

        break;
    }

    if (_ch != _EOF) {
      _parseSegments();
    }
  }

  GlobNodeBrace _parseBrace() {
    var start = _position;
    var index = _rules.length;
    _nextChar();
    var empty = true;
    var insideChoice = _insideChoice;
    var stop = false;
    _insideChoice = true;
    while (true) {
      switch (_ch) {
        case _EOF:
          var message = _MESSAGE_UNEXPECTED_END_OF_BRACE;
          _error(message, _position);
          break;
        case "/":
          var message = _MESSAGE_SLASH_NOT_ALLOWED_IN_BRACE;
          _error(message, _position);
          break;
        case ",":
          _nextChar();
          if (_ch == "}") {
            _nextChar();
            var literal = new GlobNodeLiteral("", _position);
            _rules.add(literal);
            stop = true;
          }

          empty = false;
          break;
        case "}":
          _nextChar();
          stop = true;
          break;
        default:
          _parseBraceElement();
          break;
      }

      if (stop) {
        break;
      }
    }

    if (empty) {
      var message = _MESSAGE_CHOICE_SHOULD_CONTAINS_AT_LEAST_TWO_ELEMENTS;
      _error(message, _position);
    }

    _insideChoice = insideChoice;
    _rules.sublist(index, _rules.length);
    var rules = _rules.sublist(index, _rules.length);
    _rules.length = index;
    var source = _input.substring(start, _position);
    return new GlobNodeBrace(source, start, rules);
  }

  void _parseBraceElement() {
    GlobNode rule;
    switch (_ch) {
      case "*":
        rule = _parseZeroOrMore();
        break;
      case "?":
        rule = _parseQuestion();
        break;
      case "[":
        rule = _parseCharacterClass();
        break;
      case "{":
        rule = _parseBrace();
        break;
      default:
        rule = _parseLiteral();
        break;
    }

    _rules.add(rule);
  }

  GlobNodeCharacterClass _parseCharacterClass() {
    var start = _position;
    _nextChar();
    var position = _position;
    if (_ch == "!") {
      _nextChar();
    }

    if (_ch == "]") {
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

    var source = _input.substring(start, _position);
    return new GlobNodeCharacterClass(source, start);
  }

  GlobNodeLiteral _parseLiteral() {
    var start = _position;
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
            _nextChar();
          }

          break;
        case "\\":
          _nextChar();
          if (_ch == _EOF) {
            var message = _MESSAGE_UNTERMINATED_BACKSLASH_SEQUENCE;
            _error(message, _position);
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
              _nextChar();
              break;
            case "\\":
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
          _nextChar();
          break;
        default:
          _nextChar();
          break;
      }

      if (stop) {
        break;
      }
    }

    var source = _input.substring(start, _position);
    return new GlobNodeLiteral(source, start);
  }

  GlobNodeQuestion _parseQuestion() {
    _nextChar();
    return new GlobNodeQuestion("?", _position - 1);
  }

  void _parseRange() {
    if (_ch == "-") {
      if (_lookup(1) == "]") {
        _nextChar();
        return;
      }
    }

    var start = _escapeRangeCharacter();
    var end = start;
    switch (_ch) {
      case "-":
        _nextChar();
        if (_ch == _EOF) {
          var message = _MESSAGE_UNEXPECTED_END_OF_CHARACTER_CLASS;
          _error(message, _position);
          return;
        } else if (_ch == "]") {
          _position -= 2;
          _nextChar();
        } else {
          var position = _position;
          end = _escapeRangeCharacter();
          if (start > end) {
            var message = _MESSAGE_RANGE_OUT_OF_ORDER_IN_CHARACTER_CLASS;
            _error(message, position);
          }
        }

        break;
    }
  }

  void _parseSegment() {
    while (true) {
      GlobNode rule;
      switch (_ch) {
        case _EOF:
        case "/":
          break;
        case "*":
          rule = _parseZeroOrMore();
          break;
        case "?":
          rule = _parseQuestion();
          break;
        case "[":
          rule = _parseCharacterClass();
          break;
        case "{":
          rule = _parseBrace();
          break;
        default:
          rule = _parseLiteral();
          break;
      }

      if (rule != null) {
        _rules.add(rule);
      } else {
        break;
      }
    }
  }

  void _parseSegments() {
    var stop = false;
    while (true) {
      _parseSegment();
      var segment = _createSegment();
      _segments.add(segment);
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

  GlobNode _parseZeroOrMore() {
    var start = _position;
    _nextChar();
    var crossesDirectory = false;
    var endsInSlash = false;
    switch (_ch) {
      case "*":
        crossesDirectory = true;
        while (true) {
          _nextChar();
          if (_ch != "*") {
            if(_ch == "/") {
              if(_gitignoreSemantics) {
                _nextChar();
              }
              endsInSlash = true;
            }

            break;
          }
        }

        crossesDirectory = true;
        break;
    }

    var source = _input.substring(start, _position);
    if (crossesDirectory) {
      if(endsInSlash && _gitignoreSemantics) {
        return new GlobNodeAsterisksSlash(source, start);
      } else {
        return new GlobNodeAsterisks(source, start);
      }
    } else {
      return new GlobNodeAsterisk(source, start);
    }
  }

  void _reset() {
    _insideChoice = false;
    _length = _input.length;
    _position = 0;
    _segments = <GlobNodeSegment>[];
    if (_position < _length) {
      _ch = _input[_position];
    } else {
      _position = _length;
      _ch = _EOF;
    }

    _resetSegment();
  }

  void _resetSegment() {
    _isRoot = false;
    _rules = new List<GlobNode>();
    _segmentStart = _position;
  }
}
