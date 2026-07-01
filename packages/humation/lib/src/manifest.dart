/// Data model for a Humation asset manifest.
///
/// This mirrors the JSON produced by `@humation/assets-humation-1` (and the
/// `humation-1.json` bundled by humation-swift). Unknown keys are ignored, so
/// newer manifests remain loadable. Coordinate and colour semantics match the
/// reference engine exactly so rendering is 1:1.
library;

/// A rectangle in the avatar's coordinate space.
class ViewBox {
  const ViewBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  factory ViewBox.fromJson(Map<String, dynamic> json) => ViewBox(
    x: _d(json['x']),
    y: _d(json['y']),
    width: _d(json['width']),
    height: _d(json['height']),
  );

  @override
  bool operator ==(Object other) =>
      other is ViewBox &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);
}

/// A 2D offset (a layer slot's placement in avatar space).
class LayerOffset {
  const LayerOffset(this.x, this.y);
  final double x;
  final double y;

  factory LayerOffset.fromJson(Map<String, dynamic> json) =>
      LayerOffset(_d(json['x']), _d(json['y']));
}

/// A width/height pair.
class LayerSize {
  const LayerSize(this.width, this.height);
  final double width;
  final double height;

  factory LayerSize.fromJson(Map<String, dynamic> json) =>
      LayerSize(_d(json['width']), _d(json['height']));
}

/// Template identity for the pack.
class Template {
  const Template({
    required this.id,
    required this.shortId,
    required this.name,
    required this.version,
    this.license,
  });

  final String id;
  final String shortId;
  final String name;
  final String version;
  final String? license;

  factory Template.fromJson(Map<String, dynamic> json) => Template(
    id: json['id'] as String,
    shortId: json['shortId'] as String? ?? json['id'] as String,
    name: json['name'] as String? ?? '',
    version: json['version'] as String? ?? '',
    license: json['license'] as String?,
  );
}

/// The pack defaults applied before seed and explicit overrides.
class Defaults {
  const Defaults({
    required this.selections,
    required this.colors,
    required this.background,
    required this.crop,
  });

  /// selectionSlot id -> part id.
  final Map<String, String> selections;

  /// colour slot id -> hex (no `#`).
  final Map<String, String> colors;

  /// Hex (no `#`) or the literal `transparent`.
  final String background;

  /// Crop id used to frame the avatar.
  final String crop;

  factory Defaults.fromJson(Map<String, dynamic> json) => Defaults(
    selections: _stringMap(json['selections']),
    colors: _stringMap(json['colors']),
    background: json['background'] as String? ?? 'transparent',
    crop: json['crop'] as String? ?? 'avatar',
  );
}

/// A recolourable colour slot (bound through `var(--hm-<id>)` in the SVG).
class ColorSlot {
  const ColorSlot({
    required this.id,
    required this.label,
    required this.defaultHex,
    required this.cssVariable,
    this.allowTransparent = false,
  });

  final String id;
  final String label;
  final String defaultHex;
  final String cssVariable;
  final bool allowTransparent;

  factory ColorSlot.fromJson(Map<String, dynamic> json) => ColorSlot(
    id: json['id'] as String,
    label: json['label'] as String? ?? json['id'] as String,
    defaultHex: json['default'] as String? ?? '000000',
    cssVariable: json['cssVariable'] as String? ?? '--hm-${json['id']}',
    allowTransparent: json['allowTransparent'] as bool? ?? false,
  );
}

/// One exclusive selection slot (head, body, ...).
class SelectionSlot {
  const SelectionSlot({
    required this.id,
    required this.label,
    required this.defaultPart,
    this.allowsEmpty = false,
  });

  final String id;
  final String label;
  final String defaultPart;
  final bool allowsEmpty;

  factory SelectionSlot.fromJson(Map<String, dynamic> json) => SelectionSlot(
    id: json['id'] as String,
    label: json['label'] as String? ?? json['id'] as String,
    defaultPart: json['defaultPart'] as String? ?? '',
    allowsEmpty: json['allowsEmpty'] as bool? ?? false,
  );
}

/// A UI grouping of parts for pickers.
class UiGroup {
  const UiGroup({
    required this.id,
    required this.label,
    required this.order,
    required this.selectionSlots,
    this.partIds,
  });

  final String id;
  final String label;
  final int order;
  final List<String> selectionSlots;
  final List<String>? partIds;

  factory UiGroup.fromJson(Map<String, dynamic> json) => UiGroup(
    id: json['id'] as String,
    label: json['label'] as String? ?? json['id'] as String,
    order: (json['order'] as num?)?.toInt() ?? 0,
    selectionSlots: _stringList(json['selectionSlots']),
    partIds: json['partIds'] == null ? null : _stringList(json['partIds']),
  );
}

/// A drawing layer: its stacking [order] and placement [offset].
class LayerSlot {
  const LayerSlot({
    required this.id,
    required this.label,
    required this.order,
    required this.offset,
    required this.size,
    this.hidden = false,
  });

  final String id;
  final String label;
  final int order;
  final LayerOffset offset;
  final LayerSize size;
  final bool hidden;

  factory LayerSlot.fromJson(Map<String, dynamic> json) => LayerSlot(
    id: json['id'] as String,
    label: json['label'] as String? ?? json['id'] as String,
    order: (json['order'] as num?)?.toInt() ?? 0,
    offset: LayerOffset.fromJson(_obj(json['offset'])),
    size: LayerSize.fromJson(_obj(json['size'])),
    hidden: json['hidden'] as bool? ?? false,
  );
}

/// Provenance of a part in its source design file.
class PartSource {
  const PartSource({this.groupId, this.sourceGroupName, this.partId});
  final String? groupId;
  final String? sourceGroupName;
  final String? partId;

  factory PartSource.fromJson(Map<String, dynamic> json) => PartSource(
    groupId: json['groupId'] as String?,
    sourceGroupName: json['sourceGroupName'] as String?,
    partId: json['partId'] as String?,
  );
}

/// One SVG layer of a part.
class LayerFragment {
  const LayerFragment({
    required this.layerSlot,
    this.svg,
    this.svgPath,
    this.transform,
  });

  final String layerSlot;

  /// Inline SVG fragment (`<svg ...>...</svg>`). Present in embedded packs.
  final String? svg;

  /// Relative path to a standalone SVG file (non-embedded packs; unused here).
  final String? svgPath;

  /// Optional extra transform applied to this fragment on top of the layer
  /// offset.
  final String? transform;

  factory LayerFragment.fromJson(Map<String, dynamic> json) => LayerFragment(
    layerSlot: json['layerSlot'] as String,
    svg: json['svg'] as String?,
    svgPath: json['svgPath'] as String?,
    transform: json['transform'] as String?,
  );
}

/// A selectable part option (one variant for a selection slot).
class PartOption {
  const PartOption({
    required this.id,
    required this.selectionSlot,
    required this.uiGroups,
    required this.layers,
    this.source,
    this.name,
    this.aliases = const [],
    this.tags = const [],
    this.deprecated = false,
  });

  final String id;
  final String selectionSlot;
  final List<String> uiGroups;
  final List<LayerFragment> layers;
  final PartSource? source;

  /// Human-readable name, unique within the slot (e.g. `braids`, `hoodie`).
  final String? name;
  final List<String> aliases;
  final List<String> tags;
  final bool deprecated;

  factory PartOption.fromJson(Map<String, dynamic> json) => PartOption(
    id: json['id'] as String,
    selectionSlot: json['selectionSlot'] as String,
    uiGroups: _stringList(json['uiGroups']),
    layers: (json['layers'] as List<dynamic>? ?? const [])
        .map((e) => LayerFragment.fromJson(_obj(e)))
        .toList(growable: false),
    source: json['source'] == null
        ? null
        : PartSource.fromJson(_obj(json['source'])),
    name: json['name'] as String?,
    aliases: json['aliases'] == null ? const [] : _stringList(json['aliases']),
    tags: json['tags'] == null ? const [] : _stringList(json['tags']),
    deprecated: json['deprecated'] as bool? ?? false,
  );
}

/// A name that resolves to a part id.
class AliasEntry {
  const AliasEntry({
    required this.alias,
    required this.targetId,
    this.status = 'active',
    this.replacementAlias,
  });

  final String alias;
  final String targetId;
  final String status;
  final String? replacementAlias;

  factory AliasEntry.fromJson(Map<String, dynamic> json) => AliasEntry(
    alias: json['alias'] as String,
    targetId: json['targetId'] as String,
    status: json['status'] as String? ?? 'active',
    replacementAlias: json['replacementAlias'] as String?,
  );
}

/// A complete Humation asset pack.
class HumationManifest {
  HumationManifest({
    required this.schemaVersion,
    required this.template,
    required this.defaults,
    required this.colors,
    required this.crops,
    required this.selectionSlots,
    required this.uiGroups,
    required this.layerSlots,
    required this.parts,
    required this.aliases,
  }) : _partsById = {for (final p in parts) p.id: p},
       _layerSlotsById = {for (final l in layerSlots) l.id: l};

  final String schemaVersion;
  final Template template;
  final Defaults defaults;
  final List<ColorSlot> colors;
  final Map<String, ViewBox> crops;
  final List<SelectionSlot> selectionSlots;
  final List<UiGroup> uiGroups;
  final List<LayerSlot> layerSlots;
  final List<PartOption> parts;
  final List<AliasEntry> aliases;

  final Map<String, PartOption> _partsById;
  final Map<String, LayerSlot> _layerSlotsById;

  factory HumationManifest.fromJson(Map<String, dynamic> json) {
    final crops = <String, ViewBox>{};
    final rawCrops = json['crops'];
    if (rawCrops is Map) {
      rawCrops.forEach((key, value) {
        crops[key as String] = ViewBox.fromJson(_obj(value));
      });
    }
    return HumationManifest(
      schemaVersion: json['schemaVersion']?.toString() ?? '1.0',
      template: Template.fromJson(_obj(json['template'])),
      defaults: Defaults.fromJson(_obj(json['defaults'])),
      colors: _list(json['colors'], ColorSlot.fromJson),
      crops: crops,
      selectionSlots: _list(json['selectionSlots'], SelectionSlot.fromJson),
      uiGroups: _list(json['uiGroups'], UiGroup.fromJson),
      layerSlots: _list(json['layerSlots'], LayerSlot.fromJson),
      parts: _list(json['parts'], PartOption.fromJson),
      aliases: _list(json['aliases'], AliasEntry.fromJson),
    );
  }

  /// Look up a part by canonical id.
  PartOption? partById(String id) => _partsById[id];

  /// Look up a layer slot by id.
  LayerSlot? layerSlotById(String id) => _layerSlotsById[id];

  /// Parts belonging to [slotId] in raw manifest array order.
  ///
  /// This must stay unsorted: seeded selection indexes into this list with
  /// `hash % length`, and the manifest's array order (not id order) is part of
  /// the determinism contract shared with the web engine.
  List<PartOption> partsInSlot(String slotId) =>
      parts.where((p) => p.selectionSlot == slotId).toList(growable: false);

  /// The crop used to frame avatars (falls back to `avatar` then a default).
  ViewBox get avatarCrop =>
      crops[defaults.crop] ??
      crops['avatar'] ??
      const ViewBox(x: 0, y: 0, width: 80, height: 80);
}

// -- JSON helpers -------------------------------------------------------------

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

Map<String, dynamic> _obj(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : const <String, dynamic>{};

List<String> _stringList(Object? v) => v is List
    ? v.map((e) => e.toString()).toList(growable: false)
    : const <String>[];

Map<String, String> _stringMap(Object? v) => v is Map
    ? v.map((key, value) => MapEntry(key.toString(), value.toString()))
    : <String, String>{};

List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) fromJson) =>
    v is List ? v.map((e) => fromJson(_obj(e))).toList(growable: false) : <T>[];
