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
/// An empty result means the pack is renderable. This catches the two ways an
/// authored pack can render wrong: unresolved structural references (unknown
/// selection or layer slots) and SVG path commands the renderer does not
/// implement (arcs `A`/`a`, quadratics `Q`/`q`/`T`/`t`).
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

/// Extract the value of every `d="..."` attribute in an SVG fragment.
List<String> _pathData(String svg) {
  final result = <String>[];
  final pattern = RegExp('d="([^"]*)"');
  for (final match in pattern.allMatches(svg)) {
    result.add(match.group(1) ?? '');
  }
  return result;
}
