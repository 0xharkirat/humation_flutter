/// Core hashing and colour helpers shared by resolution and rendering.
///
/// These match the reference TypeScript engine (humation-labs/humation) and the
/// Swift port (humation-labs/humation-swift) exactly, so a given seed selects
/// the same parts on web, native, and Flutter.
library;

/// FNV-1a 32-bit hash over UTF-16 code units.
///
/// Byte-identical to the reference engine: JavaScript `charCodeAt` yields
/// UTF-16 code units, `Math.imul` does a 32-bit wrapping multiply, and `>>> 0`
/// keeps the result unsigned. Dart's [String.codeUnits] is also UTF-16, so the
/// two agree for every seed, including non-ASCII.
///
/// Do not "optimise" this to iterate [String.runes] or UTF-8 bytes: that would
/// change the hash for any seed outside the BMP or with multi-byte characters
/// and break determinism against the web and Swift renderers.
int fnv1a(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = _mul32(hash, 0x01000193);
  }
  return hash & 0xffffffff;
}

/// 32-bit unsigned multiply, safe on the web.
///
/// On native Dart `int` is 64-bit and `a * b & 0xffffffff` would suffice, but on
/// the web `int` is a JavaScript double (53-bit mantissa) and the intermediate
/// product would lose precision. This mirrors the `Math.imul` polyfill by
/// splitting each operand into 16-bit halves.
int _mul32(int a, int b) {
  final aLo = a & 0xffff;
  final aHi = (a >> 16) & 0xffff;
  final bLo = b & 0xffff;
  final bHi = (b >> 16) & 0xffff;
  final low = aLo * bLo;
  final cross = (aLo * bHi + aHi * bLo) & 0xffff;
  return (low + (cross << 16)) & 0xffffffff;
}

/// Uppercase, `#`-stripped hex. The literal `transparent` is passed through
/// unchanged (case-insensitively), matching the reference engine.
String normalizeHex(String value) {
  if (value.toLowerCase() == 'transparent') return 'transparent';
  var hex = value;
  if (hex.startsWith('#')) hex = hex.substring(1);
  return hex.toUpperCase();
}
