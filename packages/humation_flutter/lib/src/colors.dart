import 'dart:ui' show Color;

/// A 6-char hex string (no `#`) for a colour value that is either an existing
/// hex `String` (with or without `#`) or a Flutter [Color].
///
/// Lets the widgets accept `colors: {HumationColorSlot.hair: Colors.brown}` as
/// well as `colors: {HumationColorSlot.hair: '#4A3728'}`.
String humationHex(Object value) {
  if (value is Color) {
    return (value.toARGB32() & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
  }
  return value.toString();
}

/// Normalise a `slot -> (hex String | Color)` map to `slot -> hex String` for
/// the engine.
Map<String, String>? humationHexColors(Map<String, Object>? colors) =>
    colors?.map((key, value) => MapEntry(key, humationHex(value)));
