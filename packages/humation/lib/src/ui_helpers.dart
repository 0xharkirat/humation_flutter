import 'manifest.dart';

/// Parts selectable in [slotId], excluding deprecated ones, sorted by source
/// part id (stable, presentation-friendly order for pickers).
///
/// This is the order to show in a UI. It is deliberately different from
/// [HumationManifest.partsInSlot], which stays in raw array order for
/// deterministic seeded selection.
List<PartOption> getPartsForSlot(HumationManifest manifest, String slotId) {
  final parts = manifest.parts
      .where((p) => p.selectionSlot == slotId && !p.deprecated)
      .toList();
  parts.sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));
  return parts;
}

/// Parts belonging to UI group [groupId], excluding deprecated ones, sorted by
/// source part id.
List<PartOption> getPartsForUiGroup(HumationManifest manifest, String groupId) {
  final parts = manifest.parts
      .where((p) => p.uiGroups.contains(groupId) && !p.deprecated)
      .toList();
  parts.sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));
  return parts;
}

String _sortKey(PartOption part) => part.source?.partId ?? part.id;
