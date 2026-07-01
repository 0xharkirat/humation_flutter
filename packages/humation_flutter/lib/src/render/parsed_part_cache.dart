import '../parsing/geometry.dart';
import '../parsing/svg_parser.dart';

/// Parses each part-layer SVG once into transform-baked, colour-bound geometry,
/// then reuses it across every recolour and size (geometry is independent of
/// both). Keyed by `partId#layerSlot`.
class ParsedPartCache {
  ParsedPartCache._();

  /// Process-wide shared cache (the pack has 86 parts, so it stays small).
  static final ParsedPartCache instance = ParsedPartCache._();

  final Map<String, ParsedPart> _cache = {};

  ParsedPart get(String key, String svg) =>
      _cache.putIfAbsent(key, () => SvgParser.parse(svg));

  /// Clear the cache (mainly for tests).
  void clear() => _cache.clear();
}
