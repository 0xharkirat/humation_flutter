import 'engine.dart';
import 'manifest.dart';
import 'render_data.dart';
import 'resolve.dart';

/// Create a deterministic avatar from [manifest] and [options].
///
/// The returned [HumationAvatar] can produce an SVG string ([HumationAvatar.toSvg]),
/// a JSON snapshot of its state, or structured [AvatarRenderData] for a native
/// renderer.
HumationAvatar createAvatar(
  HumationManifest manifest, [
  CreateAvatarOptions options = const CreateAvatarOptions(),
]) {
  return HumationAvatar._(manifest, resolveAvatarState(manifest, options));
}

/// A resolved avatar. Cheap to hold; rendering happens on demand.
class HumationAvatar {
  HumationAvatar._(this._manifest, this.state);

  /// Wrap an already-resolved [state] for rendering, skipping resolution.
  ///
  /// Useful for editors that hold and mutate an [AvatarState] draft.
  factory HumationAvatar.fromState(
    HumationManifest manifest,
    AvatarState state,
  ) => HumationAvatar._(manifest, state);

  final HumationManifest _manifest;

  /// The resolved selections and colours.
  final AvatarState state;

  /// A self-contained SVG string. Recolourable regions keep their
  /// `var(--hm-*)` references and the root element sets the colour variables,
  /// so this renders correctly in any SVG viewer that supports CSS variables.
  String toSvg() {
    final viewBox = _resolveViewBox();
    final fragments = _collectFragments();
    final css = _formatCssVariables(state.colors);
    final background = state.background;
    final bgRect = background == 'transparent'
        ? ''
        : '<rect x="${_num(viewBox.x)}" y="${_num(viewBox.y)}" '
              'width="${_num(viewBox.width)}" height="${_num(viewBox.height)}" '
              'fill="#${_escape(background)}" />';
    final content = fragments.map(_renderFragment).join();

    return '<svg xmlns="http://www.w3.org/2000/svg" '
        'width="${_num(viewBox.width)}" height="${_num(viewBox.height)}" '
        'viewBox="${_num(viewBox.x)} ${_num(viewBox.y)} '
        '${_num(viewBox.width)} ${_num(viewBox.height)}" '
        'style="${_escape(css)}">$bgRect$content</svg>';
  }

  /// The SVG as a `data:` URI, ready for an `<img>` src.
  String toDataUri() =>
      'data:image/svg+xml;charset=utf-8,${Uri.encodeComponent(toSvg())}';

  /// A JSON snapshot of the resolved state (selections, colours, background).
  Map<String, dynamic> toJson() => state.toJson();

  /// Structured render data for a native renderer.
  AvatarRenderData toRenderData() {
    final fragments = _collectFragments();
    return AvatarRenderData(
      viewBox: _resolveViewBox(),
      background: state.background,
      colors: state.colors,
      fragments: [
        for (final f in fragments)
          if (f.fragment.svg != null)
            RenderFragment(
              partId: f.part.id,
              selectionSlot: f.part.selectionSlot,
              layerSlot: f.fragment.layerSlot,
              svg: f.fragment.svg!,
              offsetX: f.offset.x,
              offsetY: f.offset.y,
              transform: f.fragment.transform,
            ),
      ],
    );
  }

  ViewBox _resolveViewBox() {
    final viewBox =
        _manifest.crops[state.crop] ?? _manifest.crops[_manifest.defaults.crop];
    if (viewBox == null) {
      throw StateError('Unknown crop: ${state.crop}');
    }
    return viewBox;
  }

  List<_ResolvedFragment> _collectFragments() {
    final result = <_ResolvedFragment>[];
    for (final partId in state.selections.values) {
      final part = _manifest.partById(partId);
      if (part == null) {
        throw StateError('Unknown selected part: $partId');
      }
      for (final fragment in part.layers) {
        final layerSlot = _manifest.layerSlotById(fragment.layerSlot);
        if (layerSlot == null) {
          throw StateError('Unknown layer slot: ${fragment.layerSlot}');
        }
        result.add(
          _ResolvedFragment(
            part: part,
            fragment: fragment,
            order: layerSlot.order,
            offset: layerSlot.offset,
          ),
        );
      }
    }
    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  String _renderFragment(_ResolvedFragment f) {
    final content = _stripSvgWrapper(f.fragment.svg ?? '');
    final base = 'translate(${_num(f.offset.x)}, ${_num(f.offset.y)})';
    final transform = f.fragment.transform == null
        ? base
        : '$base ${f.fragment.transform}';
    return '<g data-hm-layer-slot="${_escape(f.fragment.layerSlot)}" '
        'data-hm-part-id="${_escape(f.part.id)}" '
        'data-hm-selection-slot="${_escape(f.part.selectionSlot)}" '
        'transform="${_escape(transform)}">$content</g>';
  }
}

class _ResolvedFragment {
  _ResolvedFragment({
    required this.part,
    required this.fragment,
    required this.order,
    required this.offset,
  });

  final PartOption part;
  final LayerFragment fragment;
  final int order;
  final LayerOffset offset;
}

String _formatCssVariables(Map<String, String> colors) {
  final entries = colors.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries
      .map((e) => '--hm-${e.key}:#${normalizeHex(e.value)}')
      .join(';');
}

String _stripSvgWrapper(String svg) => svg
    .replaceFirst(RegExp(r'<svg[^>]*>'), '')
    .replaceFirst(RegExp(r'</svg>\s*$'), '');

String _num(double value) {
  if (value.isFinite && value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  var s = value.toStringAsFixed(4);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  s = s.replaceFirst(RegExp(r'\.$'), '');
  return s;
}

String _escape(String value) =>
    value.replaceAll('&', '&amp;').replaceAll('"', '&quot;');
