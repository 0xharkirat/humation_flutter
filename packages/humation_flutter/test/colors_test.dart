import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humation_flutter/humation_flutter.dart';

void main() {
  group('humationHex', () {
    test('converts a Color to 6-char hex (alpha dropped)', () {
      expect(humationHex(const Color(0xFF4A3728)), '4A3728');
      expect(humationHex(const Color(0xFFFFFFFF)), 'FFFFFF');
    });

    test('passes a hex string through', () {
      expect(humationHex('#4A3728'), '#4A3728');
      expect(humationHex('2A9D8F'), '2A9D8F');
    });
  });

  group('slot constants', () {
    test('hold the expected slot ids', () {
      expect(HumationSlot.head, 'head');
      expect(HumationColorSlot.hair, 'hair');
      expect(HumationSlot.values, hasLength(5));
      expect(HumationColorSlot.values, hasLength(6));
    });
  });

  testWidgets('HumationAvatar accepts Color colour values', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HumationAvatar(
          seed: 'felix',
          colors: {HumationColorSlot.hair: Color(0xFF4A3728)},
          size: 96,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
