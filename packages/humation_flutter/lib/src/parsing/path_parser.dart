import 'dart:ui';

/// Parse an SVG path `d` string into a [Path].
///
/// Supports the command set present in the asset library: `M/m L/l H/h V/v C/c
/// S/s Z/z` (absolute and relative). No arcs (`A/a`) or quadratics (`Q/q/T/t`)
/// occur in the data. Handles SVG number quirks: implicit command repetition, an
/// implicit `L` after `M`, and concatenated numbers (`1.5.3` -> `1.5, 0.3`).
Path parsePath(String d) {
  final path = Path();
  final tokens = _Tokenizer(d);

  var currentX = 0.0, currentY = 0.0;
  var startX = 0.0, startY = 0.0;
  double? lastCtrlX, lastCtrlY;
  String? command;

  double? num() => tokens.nextNumber();

  while (true) {
    final letter = tokens.peekCommand();
    if (letter != null) {
      command = letter;
      tokens.consumeCommand();
    } else if (tokens.peekNumber() == null) {
      break; // end of input
    } else if (command == null) {
      break; // numbers with no command
    }

    final cmd = command;
    final relative = cmd == cmd.toLowerCase();
    final upper = cmd.toUpperCase();

    switch (upper) {
      case 'M':
        final x = num(), y = num();
        if (x == null || y == null) return path;
        currentX = relative ? currentX + x : x;
        currentY = relative ? currentY + y : y;
        path.moveTo(currentX, currentY);
        startX = currentX;
        startY = currentY;
        lastCtrlX = null;
        lastCtrlY = null;
        // Subsequent pairs after an M are implicit L commands.
        command = relative ? 'l' : 'L';
      case 'L':
        final x = num(), y = num();
        if (x == null || y == null) return path;
        currentX = relative ? currentX + x : x;
        currentY = relative ? currentY + y : y;
        path.lineTo(currentX, currentY);
        lastCtrlX = null;
        lastCtrlY = null;
      case 'H':
        final x = num();
        if (x == null) return path;
        currentX = relative ? currentX + x : x;
        path.lineTo(currentX, currentY);
        lastCtrlX = null;
        lastCtrlY = null;
      case 'V':
        final y = num();
        if (y == null) return path;
        currentY = relative ? currentY + y : y;
        path.lineTo(currentX, currentY);
        lastCtrlX = null;
        lastCtrlY = null;
      case 'C':
        final c1x = num(), c1y = num();
        final c2x = num(), c2y = num();
        final ex = num(), ey = num();
        if (c1x == null ||
            c1y == null ||
            c2x == null ||
            c2y == null ||
            ex == null ||
            ey == null) {
          return path;
        }
        final a1x = relative ? currentX + c1x : c1x;
        final a1y = relative ? currentY + c1y : c1y;
        final a2x = relative ? currentX + c2x : c2x;
        final a2y = relative ? currentY + c2y : c2y;
        final endX = relative ? currentX + ex : ex;
        final endY = relative ? currentY + ey : ey;
        path.cubicTo(a1x, a1y, a2x, a2y, endX, endY);
        currentX = endX;
        currentY = endY;
        lastCtrlX = a2x;
        lastCtrlY = a2y;
      case 'S':
        // Smooth cubic: first control reflects the previous cubic's second
        // control about the current point.
        final c2x = num(), c2y = num();
        final ex = num(), ey = num();
        if (c2x == null || c2y == null || ex == null || ey == null) return path;
        final a2x = relative ? currentX + c2x : c2x;
        final a2y = relative ? currentY + c2y : c2y;
        final endX = relative ? currentX + ex : ex;
        final endY = relative ? currentY + ey : ey;
        final a1x = lastCtrlX != null ? 2 * currentX - lastCtrlX : currentX;
        final a1y = lastCtrlY != null ? 2 * currentY - lastCtrlY : currentY;
        path.cubicTo(a1x, a1y, a2x, a2y, endX, endY);
        currentX = endX;
        currentY = endY;
        lastCtrlX = a2x;
        lastCtrlY = a2y;
      case 'Z':
        path.close();
        currentX = startX;
        currentY = startY;
        lastCtrlX = null;
        lastCtrlY = null;
      default:
        return path; // unsupported command, stop safely
    }
  }
  return path;
}

/// Build a [Path] for a primitive element. Returns null for unknown names.
Path? parsePrimitive(String name, double Function(String) attr) {
  switch (name) {
    case 'circle':
      final r = attr('r');
      return Path()..addOval(
        Rect.fromCircle(center: Offset(attr('cx'), attr('cy')), radius: r),
      );
    case 'ellipse':
      final rx = attr('rx'), ry = attr('ry');
      return Path()..addOval(
        Rect.fromCenter(
          center: Offset(attr('cx'), attr('cy')),
          width: 2 * rx,
          height: 2 * ry,
        ),
      );
    case 'rect':
      final rect = Rect.fromLTWH(
        attr('x'),
        attr('y'),
        attr('width'),
        attr('height'),
      );
      final rx = attr('rx'), ry = attr('ry');
      if (rx > 0 || ry > 0) {
        return Path()..addRRect(
          RRect.fromRectXY(rect, rx > 0 ? rx : ry, ry > 0 ? ry : rx),
        );
      }
      return Path()..addRect(rect);
    case 'line':
      return Path()
        ..moveTo(attr('x1'), attr('y1'))
        ..lineTo(attr('x2'), attr('y2'));
    default:
      return null;
  }
}

/// Build a polygon or polyline [Path] from a `points` list.
Path parsePolygon(String rawPoints, {required bool closed}) {
  final path = Path();
  final nums = rawPoints
      .split(RegExp(r'[\s,]+'))
      .where((s) => s.isNotEmpty)
      .map((s) => double.tryParse(s))
      .whereType<double>()
      .toList();
  if (nums.length < 2) return path;
  path.moveTo(nums[0], nums[1]);
  for (var i = 2; i + 1 < nums.length; i += 2) {
    path.lineTo(nums[i], nums[i + 1]);
  }
  if (closed) path.close();
  return path;
}

// SVG number/command tokenizer.
class _Tokenizer {
  _Tokenizer(String source) : _chars = source.codeUnits;

  final List<int> _chars;
  int _index = 0;

  static const _commandSet = {
    'M', 'm', 'L', 'l', 'H', 'h', 'V', 'v', 'C', 'c', 'S', 's', 'Z', 'z', //
    'Q',
    'q',
    'T',
    't',
    'A',
    'a', // recognised so an unsupported cmd stops parse
  };

  void _skipSeparators() {
    while (_index < _chars.length) {
      final c = _chars[_index];
      if (c == 0x20 || c == 0x2c || c == 0x0a || c == 0x09 || c == 0x0d) {
        _index++;
      } else {
        break;
      }
    }
  }

  String? peekCommand() {
    _skipSeparators();
    if (_index >= _chars.length) return null;
    final ch = String.fromCharCode(_chars[_index]);
    return _commandSet.contains(ch) ? ch : null;
  }

  void consumeCommand() => _index++;

  int? peekNumber() {
    _skipSeparators();
    if (_index >= _chars.length) return null;
    final c = _chars[_index];
    final isDigit = c >= 0x30 && c <= 0x39;
    if (isDigit || c == 0x2e || c == 0x2d || c == 0x2b) return c;
    return null;
  }

  bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

  double? nextNumber() {
    _skipSeparators();
    if (_index >= _chars.length) return null;

    final start = _index;
    final c = _chars[_index];
    if (c == 0x2d || c == 0x2b) _index++; // sign
    var sawDigit = false;
    while (_index < _chars.length && _isDigit(_chars[_index])) {
      _index++;
      sawDigit = true;
    }
    if (_index < _chars.length && _chars[_index] == 0x2e) {
      _index++; // dot
      while (_index < _chars.length && _isDigit(_chars[_index])) {
        _index++;
        sawDigit = true;
      }
    }
    if (sawDigit &&
        _index < _chars.length &&
        (_chars[_index] == 0x65 || _chars[_index] == 0x45)) {
      final mark = _index;
      _index++; // e/E
      if (_index < _chars.length &&
          (_chars[_index] == 0x2d || _chars[_index] == 0x2b)) {
        _index++;
      }
      var expDigit = false;
      while (_index < _chars.length && _isDigit(_chars[_index])) {
        _index++;
        expDigit = true;
      }
      if (!expDigit) _index = mark; // not a real exponent, rewind
    }

    if (!sawDigit) {
      _index = start;
      return null;
    }
    return double.tryParse(String.fromCharCodes(_chars.sublist(start, _index)));
  }
}
