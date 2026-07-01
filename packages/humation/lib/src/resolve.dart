import 'engine.dart';
import 'manifest.dart';

/// Options for [resolveAvatarState] and `createAvatar`.
class CreateAvatarOptions {
  const CreateAvatarOptions({
    this.seed,
    this.selections,
    this.colors,
    this.background,
    this.crop,
  });

  /// Deterministically picks a part for every selection slot. Explicit
  /// [selections] override seeded picks.
  final String? seed;

  /// Per-slot overrides. Values accept canonical ids, global aliases, and
  /// slot-scoped names (`{'head': 'braids'}` resolves the alias `head-braids`).
  final Map<String, String>? selections;

  /// Per-colour-slot overrides. Hex with or without a leading `#`.
  final Map<String, String>? colors;

  /// Hex (with or without `#`) or the literal `transparent`.
  final String? background;

  /// Crop id used to frame the avatar.
  final String? crop;
}

/// A fully resolved avatar: a concrete part per slot and a concrete hex per
/// colour slot. This is the deterministic output of seed + overrides.
class AvatarState {
  const AvatarState({
    required this.template,
    required this.selections,
    required this.colors,
    required this.background,
    required this.crop,
  });

  final String template;

  /// selectionSlot id -> part id.
  final Map<String, String> selections;

  /// colour slot id -> hex (no `#`).
  final Map<String, String> colors;

  /// Hex (no `#`) or the literal `transparent`.
  final String background;

  final String crop;

  AvatarState copyWith({
    String? template,
    Map<String, String>? selections,
    Map<String, String>? colors,
    String? background,
    String? crop,
  }) => AvatarState(
    template: template ?? this.template,
    selections: selections ?? this.selections,
    colors: colors ?? this.colors,
    background: background ?? this.background,
    crop: crop ?? this.crop,
  );

  Map<String, dynamic> toJson() => {
    'template': template,
    'selections': selections,
    'colors': colors,
    'background': background,
    'crop': crop,
  };

  @override
  bool operator ==(Object other) =>
      other is AvatarState &&
      other.template == template &&
      other.background == background &&
      other.crop == crop &&
      _mapEquals(other.selections, selections) &&
      _mapEquals(other.colors, colors);

  @override
  int get hashCode => Object.hash(
    template,
    background,
    crop,
    Object.hashAllUnordered(
      selections.entries.map((e) => '${e.key}=${e.value}'),
    ),
    Object.hashAllUnordered(colors.entries.map((e) => '${e.key}=${e.value}')),
  );
}

/// Resolve [options] against [manifest] into a concrete [AvatarState].
///
/// Order matches the reference engine: manifest defaults, then seeded picks for
/// every slot (when a seed is present), then explicit selection overrides, then
/// colours (defaults then overrides).
AvatarState resolveAvatarState(
  HumationManifest manifest,
  CreateAvatarOptions options,
) {
  final selections = Map<String, String>.from(manifest.defaults.selections);

  final seed = options.seed;
  if (seed != null) {
    for (final slot in manifest.selectionSlots) {
      final slotParts = manifest.partsInSlot(slot.id);
      if (slotParts.isEmpty) continue;
      final hash = fnv1a('$seed:${slot.id}');
      selections[slot.id] = slotParts[hash % slotParts.length].id;
    }
  }

  options.selections?.forEach((slotId, value) {
    final partId = resolvePartId(value, manifest, slotId: slotId);
    final part = manifest.partById(partId);
    if (part == null) {
      throw ArgumentError.value(value, 'selections', 'Unknown part');
    }
    if (part.selectionSlot != slotId) {
      throw ArgumentError.value(
        value,
        'selections',
        'Part is not selectable in slot "$slotId"',
      );
    }
    selections[slotId] = partId;
  });

  final colors = Map<String, String>.from(manifest.defaults.colors);
  options.colors?.forEach((key, color) {
    colors[key] = normalizeHex(color);
  });

  final rawBackground = options.background ?? manifest.defaults.background;
  final background = rawBackground.toLowerCase() == 'transparent'
      ? 'transparent'
      : normalizeHex(rawBackground);

  return AvatarState(
    template: manifest.template.id,
    selections: selections,
    colors: colors,
    background: background,
    crop: options.crop ?? manifest.defaults.crop,
  );
}

/// Resolve a part reference (canonical id, slot-scoped name, or global alias) to
/// a canonical part id. Throws [ArgumentError] if it cannot be resolved.
String resolvePartId(
  String input,
  HumationManifest manifest, {
  String? slotId,
}) {
  if (manifest.partById(input) != null) return input;

  if (slotId != null) {
    final scopedAlias = '$slotId-$input';
    for (final entry in manifest.aliases) {
      if (entry.alias == scopedAlias) return entry.targetId;
    }
  }

  for (final entry in manifest.aliases) {
    if (entry.alias == input) return entry.targetId;
  }

  throw ArgumentError.value(input, 'input', 'Unknown part');
}

bool _mapEquals(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
