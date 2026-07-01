import 'dart:ui';

import 'package:xml/xml.dart';

import 'geometry.dart';
import 'path_parser.dart';

/// Parse one inline part SVG (`<svg>...</svg>`) into transform-baked,
/// colour-bound geometry.
///
/// The SVG's own width/height/viewBox are ignored: raw coordinates stay in the
/// part's local space and are positioned by the layer offset at compose time,
/// matching the reference engine. The cascade is inherited -> presentation
/// attributes -> `<style>` class rules (author stylesheet wins), and `opacity`
/// is per-element (not inherited). Only the features that occur in the asset set
/// are implemented.
class SvgParser {
  SvgParser._();

  final Map<String, _PaintAttrs> _css = {};
  final List<Shape> _shapes = [];
  final Map<String, ClipPath> _clips = {};

  /// Parse [svg]. Returns empty geometry on malformed input (never throws).
  static ParsedPart parse(String svg) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(svg);
    } on XmlException {
      return ParsedPart.empty;
    }

    final parser = SvgParser._();
    for (final style in doc.findAllElements('style')) {
      parser._parseCss(style.innerText);
    }
    parser._walk(
      doc.rootElement,
      _Ctx(Affine.identity, PaintStyle(), const []),
    );
    return ParsedPart(parser._shapes, parser._clips);
  }

  void _walk(XmlElement el, _Ctx ctx) {
    final name = el.localName.toLowerCase();

    switch (name) {
      case 'style':
        return; // handled in pass 1
      case 'clippath':
        final id = el.getAttribute('id');
        final rule = el.getAttribute('clip-rule') == 'evenodd'
            ? PathFillType.evenOdd
            : PathFillType.nonZero;
        final clip = Path()..fillType = rule;
        _buildClip(el, _push(ctx, el), clip);
        if (id != null) _clips[id] = ClipPath(clip);
        return;
      case 'svg':
      case 'defs':
      case 'g':
        final childCtx = _push(ctx, el);
        for (final child in el.childElements) {
          _walk(child, childCtx);
        }
        return;
    }

    final local = _primitivePath(name, el);
    if (local == null) {
      for (final child in el.childElements) {
        _walk(child, ctx);
      }
      return;
    }

    var ctm = ctx.ctm;
    final t = el.getAttribute('transform');
    if (t != null) ctm = ctm.multiply(parseTransform(t));
    final baked = local.transform(ctm.toMatrix4());

    final paint = _resolvedPaint(ctx.paint, el);
    // Stroke width scales with the coordinate system (baked into geometry, so
    // it is not otherwise applied). Assets use uniform scale only.
    final s = ctm.scaleFactor;
    if (s > 0 && s != 1) paint.strokeWidth *= s;

    _shapes.add(Shape(path: baked, paint: paint, clipIds: ctx.clipIds));
  }

  void _buildClip(XmlElement el, _Ctx ctx, Path into) {
    for (final child in el.childElements) {
      final name = child.localName.toLowerCase();
      if (name == 'g' || name == 'svg' || name == 'defs') {
        _buildClip(child, _push(ctx, child), into);
        continue;
      }
      final local = _primitivePath(name, child);
      if (local == null) continue;
      var ctm = ctx.ctm;
      final t = child.getAttribute('transform');
      if (t != null) ctm = ctm.multiply(parseTransform(t));
      into.addPath(local.transform(ctm.toMatrix4()), Offset.zero);
    }
  }

  _Ctx _push(_Ctx ctx, XmlElement el) {
    var ctm = ctx.ctm;
    final t = el.getAttribute('transform');
    if (t != null) ctm = ctm.multiply(parseTransform(t));

    final paint = ctx.paint.copy();
    _applyPresentation(el, paint);
    _applyClasses(el.getAttribute('class'), paint);

    var clipIds = ctx.clipIds;
    final clip = el.getAttribute('clip-path');
    if (clip != null) {
      final id = _clipRefId(clip);
      if (id != null) clipIds = [...clipIds, id];
    }
    return _Ctx(ctm, paint, clipIds);
  }

  PaintStyle _resolvedPaint(PaintStyle inherited, XmlElement el) {
    final style = inherited.copy();
    style.opacity = 1; // opacity is per-element, not inherited
    _applyPresentation(el, style);
    _applyClasses(el.getAttribute('class'), style);
    return style;
  }

  Path? _primitivePath(String name, XmlElement el) {
    double f(String key) => double.tryParse(el.getAttribute(key) ?? '') ?? 0;
    switch (name) {
      case 'path':
        final d = el.getAttribute('d');
        return d == null ? null : parsePath(d);
      case 'circle':
      case 'ellipse':
      case 'rect':
      case 'line':
        return parsePrimitive(name, f);
      case 'polygon':
        return parsePolygon(el.getAttribute('points') ?? '', closed: true);
      case 'polyline':
        return parsePolygon(el.getAttribute('points') ?? '', closed: false);
      default:
        return null;
    }
  }

  void _applyPresentation(XmlElement el, PaintStyle style) {
    final fill = el.getAttribute('fill');
    if (fill != null) style.fill = parseSvgColor(fill);
    final stroke = el.getAttribute('stroke');
    if (stroke != null) style.stroke = parseSvgColor(stroke);
    final sw = _cssLength(el.getAttribute('stroke-width'));
    if (sw != null) style.strokeWidth = sw;
    final ml = _double(el.getAttribute('stroke-miterlimit'));
    if (ml != null) style.miterLimit = ml;
    final cap = el.getAttribute('stroke-linecap');
    if (cap != null) style.cap = _lineCap(cap);
    final join = el.getAttribute('stroke-linejoin');
    if (join != null) style.join = _lineJoin(join);
    final op = _double(el.getAttribute('opacity'));
    if (op != null) style.opacity = op;
    final fr = el.getAttribute('fill-rule');
    if (fr != null) {
      style.fillType = fr == 'evenodd'
          ? PathFillType.evenOdd
          : PathFillType.nonZero;
    }
  }

  void _applyClasses(String? classAttr, PaintStyle style) {
    if (classAttr == null) return;
    for (final cls in classAttr.split(RegExp(r'\s+'))) {
      if (cls.isEmpty) continue;
      _css[cls]?.applyTo(style);
    }
  }

  // -- CSS ----------------------------------------------------------------

  void _parseCss(String css) {
    final text = css.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    final blocks = RegExp(r'([^{}]*)\{([^{}]*)\}');
    for (final m in blocks.allMatches(text)) {
      final selectors = m.group(1)!;
      final attrs = _parseDeclarations(m.group(2)!);
      for (final selector in selectors.split(',')) {
        final trimmed = selector.trim();
        if (!trimmed.startsWith('.')) continue;
        final cls = trimmed.substring(1);
        final existing = _css[cls] ?? _PaintAttrs();
        existing.overlay(attrs);
        _css[cls] = existing;
      }
    }
  }

  _PaintAttrs _parseDeclarations(String body) {
    final attrs = _PaintAttrs();
    for (final decl in body.split(';')) {
      final idx = decl.indexOf(':');
      if (idx < 0) continue;
      final prop = decl.substring(0, idx).trim().toLowerCase();
      final value = decl.substring(idx + 1).trim();
      switch (prop) {
        case 'fill':
          attrs.fill = parseSvgColor(value);
        case 'stroke':
          attrs.stroke = parseSvgColor(value);
        case 'stroke-width':
          attrs.strokeWidth = _cssLength(value);
        case 'stroke-miterlimit':
          attrs.miterLimit = _double(value);
        case 'stroke-linecap':
          attrs.cap = _lineCap(value);
        case 'stroke-linejoin':
          attrs.join = _lineJoin(value);
        case 'opacity':
          attrs.opacity = _double(value);
      }
    }
    return attrs;
  }

  String? _clipRefId(String value) {
    final hash = value.indexOf('#');
    final close = value.lastIndexOf(')');
    if (hash < 0 || close < 0 || close < hash) return null;
    return value.substring(hash + 1, close);
  }

  StrokeCap _lineCap(String v) => switch (v) {
    'round' => StrokeCap.round,
    'square' => StrokeCap.square,
    _ => StrokeCap.butt,
  };

  StrokeJoin _lineJoin(String v) => switch (v) {
    'round' => StrokeJoin.round,
    'bevel' => StrokeJoin.bevel,
    _ => StrokeJoin.miter,
  };
}

double? _double(String? v) => v == null ? null : double.tryParse(v);

/// Parse a CSS length, tolerating a trailing `px` unit. The asset set uses
/// `stroke-width` values like `1.47px` inside `<style>` rules; a bare
/// `double.tryParse` would drop them and leave the default width of 1.
double? _cssLength(String? v) {
  if (v == null) return null;
  var s = v.trim();
  if (s.endsWith('px')) s = s.substring(0, s.length - 2).trim();
  return double.tryParse(s);
}

class _Ctx {
  const _Ctx(this.ctm, this.paint, this.clipIds);
  final Affine ctm;
  final PaintStyle paint;
  final List<String> clipIds;
}

/// Partial paint overrides from a CSS class rule.
class _PaintAttrs {
  SvgColor? fill;
  SvgColor? stroke;
  double? strokeWidth;
  double? miterLimit;
  StrokeCap? cap;
  StrokeJoin? join;
  double? opacity;

  void applyTo(PaintStyle s) {
    if (fill != null) s.fill = fill!;
    if (stroke != null) s.stroke = stroke!;
    if (strokeWidth != null) s.strokeWidth = strokeWidth!;
    if (miterLimit != null) s.miterLimit = miterLimit!;
    if (cap != null) s.cap = cap!;
    if (join != null) s.join = join!;
    if (opacity != null) s.opacity = opacity!;
  }

  void overlay(_PaintAttrs o) {
    if (o.fill != null) fill = o.fill;
    if (o.stroke != null) stroke = o.stroke;
    if (o.strokeWidth != null) strokeWidth = o.strokeWidth;
    if (o.miterLimit != null) miterLimit = o.miterLimit;
    if (o.cap != null) cap = o.cap;
    if (o.join != null) join = o.join;
    if (o.opacity != null) opacity = o.opacity;
  }
}
