/// String constants for the slots of the bundled `humation-1` pack.
///
/// The API still takes plain strings, so custom packs with other slot ids work
/// too. These just give you autocomplete and guard against typos:
///
/// ```dart
/// HumationAvatar(
///   selections: {HumationSlot.head: 'wavy-medium', HumationSlot.body: 'hoodie'},
/// );
/// ```
library;

/// The five selection slots of the `humation-1` pack.
abstract final class HumationSlot {
  static const String head = 'head';
  static const String body = 'body';
  static const String bottom = 'bottom';
  static const String item = 'item';
  static const String glasses = 'glasses';

  /// All selection slots, in the pack's order.
  static const List<String> values = [head, body, bottom, item, glasses];
}

/// The six colour slots of the `humation-1` pack.
abstract final class HumationColorSlot {
  static const String background = 'background';
  static const String stroke = 'stroke';
  static const String hair = 'hair';
  static const String skin = 'skin';
  static const String clothes = 'clothes';
  static const String bottom = 'bottom';

  /// All colour slots.
  static const List<String> values = [
    background,
    stroke,
    hair,
    skin,
    clothes,
    bottom,
  ];
}
