import 'package:flutter_test/flutter_test.dart';
import 'package:humation_flutter/src/parsing/geometry.dart';
import 'package:humation_flutter/src/parsing/path_parser.dart';
import 'package:humation_flutter/src/parsing/svg_parser.dart';

void main() {
  group('Rgba.fromHex', () {
    test('6-digit', () {
      final c = Rgba.fromHex('#FF8000')!;
      expect(c.r, closeTo(1, 0.001));
      expect(c.g, closeTo(128 / 255, 0.001));
      expect(c.b, closeTo(0, 0.001));
    });
    test('3-digit expands', () {
      final c = Rgba.fromHex('f00')!;
      expect(c.r, 1);
      expect(c.g, 0);
      expect(c.b, 0);
    });
    test('invalid returns null', () {
      expect(Rgba.fromHex('nope'), isNull);
    });
  });

  group('parseSvgColor', () {
    test('none', () {
      expect(parseSvgColor('none'), isA<NoneColor>());
    });
    test('hex is fixed', () {
      expect(parseSvgColor('#000000'), isA<FixedColor>());
    });
    test('var binds a slot with fallback', () {
      final color = parseSvgColor('var(--hm-hair, #123456)');
      expect(color, isA<SlotColor>());
      expect((color as SlotColor).slot, 'hair');
    });
    test('named ivory', () {
      expect(parseSvgColor('ivory'), isA<FixedColor>());
    });
  });

  group('parseTransform', () {
    test('scale', () {
      final t = parseTransform('scale(2)');
      expect(t.a, 2);
      expect(t.d, 2);
    });
    test('translate', () {
      final t = parseTransform('translate(3, 4)');
      expect(t.tx, 3);
      expect(t.ty, 4);
    });
    test('translate then scale applies scale first', () {
      // A point at local (1,1): scaled to (0.5,0.5), then translated by (2,3).
      final t = parseTransform('translate(2, 3) scale(0.5)');
      expect(t.a, 0.5);
      expect(t.tx, 2);
      expect(t.ty, 3);
    });
  });

  group('parsePath', () {
    test('produces geometry for a simple path', () {
      final path = parsePath('M0 0 L10 0 L10 10 Z');
      final bounds = path.getBounds();
      expect(bounds.width, 10);
      expect(bounds.height, 10);
    });
    test('empty for garbage', () {
      final path = parsePath('nonsense');
      expect(path.getBounds().isEmpty, isTrue);
    });
  });

  group('SvgParser', () {
    test('parses a fill and a stroke shape', () {
      final part = SvgParser.parse(
        '<svg><circle cx="5" cy="5" r="5" fill="#ff0000" '
        'stroke="var(--hm-stroke, #000000)" stroke-width="2"/></svg>',
      );
      expect(part.shapes, hasLength(1));
      expect(part.shapes.first.paint.stroke, isA<SlotColor>());
    });

    test('malformed SVG yields empty geometry, never throws', () {
      expect(SvgParser.parse('<svg><path d='), isNotNull);
      expect(SvgParser.parse('<svg><path d=').shapes, isEmpty);
    });

    test('applies a <style> class rule', () {
      final part = SvgParser.parse(
        '<svg><style>.a{fill:#00ff00}</style>'
        '<rect class="a" width="4" height="4"/></svg>',
      );
      expect(part.shapes.first.paint.fill, isA<FixedColor>());
    });

    test('reads a px stroke-width from a class rule', () {
      // The real assets set stroke-width like "1.47px" inside <style> blocks.
      final part = SvgParser.parse(
        '<svg><style>.st3{fill:none;stroke:#000;stroke-width:1.47px}</style>'
        '<path class="st3" d="M0 0 L10 0"/></svg>',
      );
      expect(part.shapes.single.paint.strokeWidth, closeTo(1.47, 1e-9));
    });
  });
}
