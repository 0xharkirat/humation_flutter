import 'manifest.dart';

/// A problem found by [validateManifest].
class ValidationIssue {
  const ValidationIssue({
    required this.partId,
    required this.message,
    this.partName,
  });

  final String partId;
  final String? partName;
  final String message;

  @override
  String toString() =>
      '[$partId${partName == null ? '' : ' $partName'}] $message';
}

/// Validate every part against what the native renderer implements.
///
/// This catches two ways an authored pack can render wrong: unresolved
/// structural references (unknown selection or layer slots) and SVG path
/// commands the renderer does not implement (arcs `A`/`a`, quadratics
/// `Q`/`q`/`T`/`t`). An empty result means these checks passed; this is not a
/// full SVG parse, so unsupported elements or transform syntax outside path
/// data are not detected.
List<ValidationIssue> validateManifest(HumationManifest manifest) {
  final issues = <ValidationIssue>[];
  final slotIds = manifest.selectionSlots.map((s) => s.id).toSet();

  for (final part in manifest.parts) {
    void add(String message) => issues.add(
      ValidationIssue(partId: part.id, partName: part.name, message: message),
    );

    if (!slotIds.contains(part.selectionSlot)) {
      add('unknown selectionSlot "${part.selectionSlot}"');
    }

    for (final layer in part.layers) {
      if (manifest.layerSlotById(layer.layerSlot) == null) {
        add('unknown layerSlot "${layer.layerSlot}"');
      }
      final svg = layer.svg;
      if (svg == null) continue;
      for (final d in _pathData(svg)) {
        if (d.contains(RegExp('[AaQqTt]'))) {
          add(
            'layer "${layer.layerSlot}" uses an unsupported path command '
            '(arcs A/a or quadratics Q/q/T/t are not rendered)',
          );
          break;
        }
      }
    }
  }
  return issues;
}

/// Extract the value of every `d="..."` or `d='...'` attribute in an SVG
/// fragment. Matches both quote styles since authored (non-embedded) SVG
/// commonly uses single quotes.
///
/// The leading `(?<![\w-])` boundary stops this from matching inside another
/// attribute that merely ends in "d" (`id="..."`, or any future `*-d="..."`)
/// as if it were a path's `d` attribute. `[\s\S]` (rather than `.`) spans
/// line breaks, so a hand-formatted multiline `d` value is still captured
/// whole instead of silently matching zero times.
List<String> _pathData(String svg) {
  final result = <String>[];
  final pattern = RegExp(r'''(?<![\w-])d=(["'])((?:(?!\1)[\s\S])*)\1''');
  for (final match in pattern.allMatches(svg)) {
    result.add(match.group(2) ?? '');
  }
  return result;
}
