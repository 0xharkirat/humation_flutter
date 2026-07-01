import 'package:humation/humation.dart';
import 'package:test/test.dart';

void main() {
  group('fnv1a', () {
    // Byte-identical to the reference engine and humation-swift. These vectors
    // are the determinism contract shared across web, native, and Flutter.
    test('known vectors (UTF-16 code units)', () {
      expect(fnv1a(''), 2166136261);
      expect(fnv1a('a'), 3826002220);
      expect(fnv1a('test'), 2949673445);
      expect(fnv1a('humation'), 2721276410);
      expect(fnv1a('用户'), 3303804768); // CJK exercises the UTF-16 path
      expect(fnv1a('hm1'), 1204328429);
    });

    test('is stable', () {
      expect(fnv1a('user-123'), fnv1a('user-123'));
    });
  });

  group('normalizeHex', () {
    test('uppercases and strips #', () {
      expect(normalizeHex('#aabbcc'), 'AABBCC');
      expect(normalizeHex('aabbcc'), 'AABBCC');
    });

    test('passes transparent through', () {
      expect(normalizeHex('transparent'), 'transparent');
      expect(normalizeHex('TRANSPARENT'), 'transparent');
    });
  });
}
