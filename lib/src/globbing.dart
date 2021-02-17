part of '../globbing.dart';

class Glob implements Pattern {
  /// True, if the pattern is case sensitive; otherwise false.
  final bool caseSensitive;

  /// Pattern for this glob.
  final String pattern;

  bool? _crossesDirectory;

  Pattern? _expression;

  bool? _isAbsolute;

  List<GlobSegment>? _segments;

  /// Creates the glob.
  ///
  /// Parameters:
  ///  [pattern]
  ///   Pattern for this glob.
  ///  [caseSensitive]
  ///   True, if the pattern is case sensitive; otherwise false.
  Glob(this.pattern, {this.caseSensitive = true}) {
    _compile(caseSensitive);
  }

  /// Returns true if the glob [pattern] constains the segments that crosses
  /// the directoty.
  bool? get crossesDirectory => _crossesDirectory;

  /// Returns true if glob [pattern] is an absolute path; otherwise false;   *
  bool? get isAbsolute => _isAbsolute;

  /// Returns the glob segments.
  List<GlobSegment>? get segments => _segments;

  @override
  Iterable<Match> allMatches(String str, [int start = 0]) {
    return _expression!.allMatches(str, start);
  }

  /// Returns true if pattern matches thes string.
  bool match(String string) {
    return allMatches(string).isNotEmpty;
  }

  @override
  Match? matchAsPrefix(String string, [int start = 0]) {
    return _expression!.matchAsPrefix(string, start);
  }

  /// Returns the string representation.
  @override
  String toString() {
    return pattern;
  }

  void _compile(bool caseSensitive) {
    final compiler = _GlobCompiler();
    final result = compiler.compile(pattern, caseSensitive: caseSensitive);
    _crossesDirectory = result.crossesDirectory;
    _expression = result.expression;
    _isAbsolute = result.isAbsolute;
    _segments = result.segments;
  }
}

class GlobSegment implements Pattern {
  late Pattern _expression;

  /// True if the segment crosses the directory.
  final bool? crossesDirectory;

  /// True if segment should match only directory.
  final bool? onlyDirectory;

  /// Original glob pattern.
  final String? pattern;

  /// True if the segment pattern contains no wildcards '*', '?', no character
  /// classes '[]', no choices '{}'; otherwise false;
  /// false.
  final bool? strict;

  GlobSegment(this.pattern, Pattern expression,
      {this.crossesDirectory, this.onlyDirectory, this.strict}) {
    if (pattern == null) {
      throw ArgumentError.notNull('pattern');
    }

    if (crossesDirectory == null) {
      throw ArgumentError.notNull('crossesDirectory');
    }

    if (strict == null) {
      throw ArgumentError.notNull('strict');
    }

    if (onlyDirectory == null) {
      throw ArgumentError.notNull('onlyDirectory');
    }

    _expression = expression;
  }

  @override
  Iterable<Match> allMatches(String str, [int start = 0]) {
    return _expression.allMatches(str, start);
  }

  /// Returns true if pattern matches thes string.
  bool match(String string) {
    return allMatches(string).isNotEmpty;
  }

  @override
  Match? matchAsPrefix(String string, [int start = 0]) {
    return _expression.matchAsPrefix(string, start);
  }

  /// Returns the string representation.
  @override
  String toString() {
    return pattern!;
  }
}

class _GlobCompiler {
  static const String _MESSAGE_CANNOT_ESCAPE_SLASH_CHARACTER =
      'Cannot escape slash \'/\' character';

  static const String _MESSAGE_RANGE_OUT_OF_ORDER_IN_CHARACTER_CLASS =
      'Range out of order in character class';

  static const String _MESSAGE_SLASH_NOT_ALLOWED_IN_CHARACTER_CLASS =
      'Explicit slash \'/\' not allowed in character class';

  static const String _MESSAGE_UNTERMINATED_BACKSLASH_SEQUENCE =
      'Unterminated backslash \'\\\' escape sequence';

  static const String _MESSAGE_UNEXPECTED_END_OF_CHARACTER_CLASS =
      'Unexpected end of character class';

  late bool _caseSensitive;

  late StringBuffer _globalBuffer;

  String? _input;

  late StringBuffer _segmentBuffer;

  _GlobCompilerResult compile(String input, {bool caseSensitive = true}) {
    _caseSensitive = caseSensitive;
    _input = input;
    return _compile();
  }

  _GlobCompilerResult _compile() {
    _reset();
    final parser = GlobParser();
    final node = parser.parse(_input);
    final segments = _compileSegments(node.nodes);
    final result = _GlobCompilerResult();
    result.crossesDirectory = node.crossesDirectory;
    result.expression =
        RegExp(_globalBuffer.toString(), caseSensitive: _caseSensitive);
    result.isAbsolute = node.isAbsolute;
    result.segments = segments;
    return result;
  }

  void _compileAsterisk(GlobNodeAsterisk node, bool first) {
    if (first) {
      _write('(?![.])');
    }

    _write('[^/]*');
  }

  void _compileAsterisks(GlobNodeAsterisks node, bool first) {
    if (first) {
      _write('(?![.])');
    }

    _write('.*');
  }

  void _compileBrace(GlobNodeBrace node, bool first) {
    _write('(?:');
    final nodes = node.nodes;
    final length = nodes.length;
    for (var i = 0; i < length; i++) {
      final element = nodes[i];
      switch (element.type) {
        case GlobNodeTypes.ASTERISK:
          _compileAsterisk(element as GlobNodeAsterisk, first);
          break;
        case GlobNodeTypes.ASTERISKS:
          _compileAsterisks(element as GlobNodeAsterisks, first);
          break;
        case GlobNodeTypes.BRACE:
          _compileBrace(element as GlobNodeBrace, first);
          break;
        case GlobNodeTypes.CHARACTER_CLASS:
          _compileCharacterClass(element as GlobNodeCharacterClass);
          break;
        case GlobNodeTypes.LITERAL:
          _compileLiteral(element as GlobNodeLiteral);
          break;
        case GlobNodeTypes.QUESTION:
          _compileQuestion(element as GlobNodeQuestion);
          break;
        default:
          _errorIllegalElement(node, element);
      }

      first = false;
      if (i < length - 1) {
        _write('|');
      }
    }

    _write(')');
  }

  void _compileCharacterClass(GlobNodeCharacterClass node) {
    var ch = '';
    final source = node.source!;
    final length = source.length;
    var position = 0;
    final escapeCharacter = () {
      switch (ch) {
        case '/':
          final message = _MESSAGE_SLASH_NOT_ALLOWED_IN_CHARACTER_CLASS;
          _error(message, node.position! + position);
          break;
        case '\\':
          if (position >= length) {
            final message = _MESSAGE_UNTERMINATED_BACKSLASH_SEQUENCE;
            _error(message, node.position! + position);
          }

          ch = source[position++];
          switch (ch) {
            case '/':
              final message = _MESSAGE_SLASH_NOT_ALLOWED_IN_CHARACTER_CLASS;
              _error(message, node.position! + position);
              break;
            default:
              _write('\\');
              _write(ch);
              break;
          }

          break;
        case '^':
          _write(ch);
          break;
        default:
          _write(ch);
          break;
      }

      final result = ch.codeUnitAt(0);
      if (position < length) {
        ch = source[position++];
      } else {
        ch = '';
      }

      return result;
    };

    if (position < length) {
      ch = source[position++];
    }

    if (ch != '[') {
      _errorIllegalStartOrEndCharacter(node.type, 'starts', '[', 0);
    }

    _write('[');
    ch = source[position++];
    if (ch == '!') {
      _write('^');
      if (position < length) {
        ch = source[position++];
      } else {
        final message = _MESSAGE_UNEXPECTED_END_OF_CHARACTER_CLASS;
        _error(message, node.position! + position);
      }
    }

    if (ch == ']') {
      _write('\\]-\\]\'');
      if (position < length) {
        ch = source[position++];
      } else {
        final message = _MESSAGE_UNEXPECTED_END_OF_CHARACTER_CLASS;
        _error(message, node.position! + position);
      }
    }

    var stop = false;
    while (true) {
      if (ch == '') {
        _errorIllegalStartOrEndCharacter(node.type, 'ends', ']', 0);
      }

      switch (ch) {
        case '/':
          final message = _MESSAGE_SLASH_NOT_ALLOWED_IN_CHARACTER_CLASS;
          _error(message, node.position! + 1 + position);
          break;
        case ']':
          if (position != length) {
            _errorIllegalStartOrEndCharacter(node.type, 'ends', ']', 0);
          }

          stop = true;
          break;
        default:
          if (ch == '-') {
            if (position < length) {
              if (source[position] == ']') {
                ch = ']';
                position++;
                _write('-');
                break;
              }
            }
          }

          final start = escapeCharacter();
          var end = start;
          switch (ch) {
            case '-':
              if (position >= length) {
                final message = _MESSAGE_UNEXPECTED_END_OF_CHARACTER_CLASS;
                _error(message, node.position! + position);
              }

              ch = source[position++];
              if (ch == ']') {
                position -= 2;
                ch = source[position];
              } else {
                _write('-');
                end = escapeCharacter();
                if (start > end) {
                  final message =
                      _MESSAGE_RANGE_OUT_OF_ORDER_IN_CHARACTER_CLASS;
                  _error(message, position);
                }
              }

              break;
          }
      }

      if (stop) {
        break;
      }
    }

    _write(']');
  }

  void _compileLiteral(GlobNodeLiteral node) {
    final source = node.source!;
    final length = source.length;
    var position = 0;
    while (true) {
      if (position == length) {
        break;
      }

      var ch = source[position++];
      switch (ch) {
        case '\\':
          if (position == length) {
            final message = _MESSAGE_UNTERMINATED_BACKSLASH_SEQUENCE;
            _error(message, node.position! + position);
          }

          ch = source[position++];
          switch (ch) {
            case '/':
              final message = _MESSAGE_CANNOT_ESCAPE_SLASH_CHARACTER;
              _error(message, node.position! + position);
              break;
            case '*':
            case '{':
            case '[':
            case '?':
            case '}':
              _write('\\');
              _write(ch);
              break;
            case '\\':
              _write('\\');
              _write(ch);
              break;
            default:
              _write(ch);
          }

          break;
        case '\$':
        case '(':
        case ')':
        case '*':
        case '+':
        case '.':
        case '?':
        case '[':
        case ']':
        case '^':
        case '{':
        case '|':
        case '}':
          _write('\\');
          _write(ch);
          break;
        default:
          _write(ch);
          break;
      }
    }
  }

  void _compileQuestion(GlobNodeQuestion node) {
    _write('.');
  }

  GlobSegment _compileSegment(GlobNodeSegment node) {
    _resetSegment();
    var first = true;
    for (final element in node.nodes) {
      switch (element.type) {
        case GlobNodeTypes.ASTERISK:
          _compileAsterisk(element as GlobNodeAsterisk, first);
          break;
        case GlobNodeTypes.ASTERISKS:
          _compileAsterisks(element as GlobNodeAsterisks, first);
          break;
        case GlobNodeTypes.BRACE:
          _compileBrace(element as GlobNodeBrace, first);
          break;
        case GlobNodeTypes.CHARACTER_CLASS:
          _compileCharacterClass(element as GlobNodeCharacterClass);
          break;
        case GlobNodeTypes.LITERAL:
          _compileLiteral(element as GlobNodeLiteral);
          break;
        case GlobNodeTypes.QUESTION:
          _compileQuestion(element as GlobNodeQuestion);
          break;
        default:
          _errorIllegalElement(node, element);
      }

      first = false;
    }

    _segmentBuffer.write('\$');
    final pattern = _segmentBuffer.toString();
    final expression = RegExp(pattern, caseSensitive: _caseSensitive);
    final crossesDirectory = node.crossesDirectory;
    final onlyDirector = node.onlyDirectory;
    final source = node.source;
    final strict = node.strict;
    final segment = GlobSegment(source, expression,
        crossesDirectory: crossesDirectory,
        onlyDirectory: onlyDirector,
        strict: strict);
    return segment;
  }

  List<GlobSegment> _compileSegments(List<GlobNodeSegment> nodes) {
    _globalBuffer.write('^');
    final segments = <GlobSegment>[];
    final length = nodes.length;
    for (var i = 0; i < length; i++) {
      final node = nodes[i];
      switch (node.type) {
        case GlobNodeTypes.SEGMENT:
          final segment = _compileSegment(node);
          segments.add(segment);
          break;
        default:
          throw StateError('Illegal node: \'$node\'.');
      }
      if (i < length - 1) {
        if (!node.isRoot!) {
          _globalBuffer.write('/');
        }
      }
    }

    _globalBuffer.write('\$');
    return segments;
  }

  void _error(String message, int position) {
    throw FormatException(
        '(column: ${position + 1}), $message in \'$_input\'.');
  }

  void _errorIllegalElement(GlobNode owner, GlobNode element) {
    var position = owner.position;
    final elementType = element.type.toString();
    position = element.position;

    final ownerType = owner.type;
    final message =
        'Illegal element \'$elementType\' in $ownerType node \'$owner\'';
    _error(message, position!);
  }

  void _errorIllegalStartOrEndCharacter(
      GlobNodeTypes type, String should, String ch, int position) {
    final message = '\'$type\' should $should with \'$ch\'';
    _error(message, position);
  }

  //String _lookup(String source, int position, int offset) {
  //  final index = position + offset;
  //  if (index < source.length) {
  //    return source[index];
  //  }
  //
  //  return '';
  //}

  void _reset() {
    _globalBuffer = StringBuffer();
  }

  void _resetSegment() {
    _segmentBuffer = StringBuffer();
    _segmentBuffer.write('^');
  }

  void _write(String string) {
    _globalBuffer.write(string);
    _segmentBuffer.write(string);
  }
}

class _GlobCompilerResult {
  bool? isAbsolute;

  bool? crossesDirectory;

  Pattern? expression;

  List<GlobSegment>? segments;
}
