import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humation_flutter/humation_flutter.dart';

Future<Uint8List> _rawPixels(AvatarRenderData data, int pixels) async {
  final image = await renderAvatarToImage(data, pixels: pixels);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return bytes!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

void main() {
  final manifest = humation1Manifest;

  testWidgets('HumationAvatar builds from a seed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: HumationAvatar(seed: 'felix', size: 96)),
      ),
    );
    expect(find.byType(HumationAvatar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HumationAvatar.fromState builds', (tester) async {
    final state = Humation.resolve('felix');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: HumationAvatar.fromState(state, size: 96)),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('render is deterministic and seed-sensitive', (tester) async {
    await tester.runAsync(() async {
      final felix = createAvatar(
        manifest,
        const CreateAvatarOptions(seed: 'felix', background: 'FFFFFF'),
      ).toRenderData();
      final other = createAvatar(
        manifest,
        const CreateAvatarOptions(seed: 'not-felix', background: 'FFFFFF'),
      ).toRenderData();

      final a = await _rawPixels(felix, 64);
      final b = await _rawPixels(felix, 64);
      final c = await _rawPixels(other, 64);

      expect(a, equals(b), reason: 'same seed must render identical pixels');
      expect(a, isNot(equals(c)), reason: 'different seeds should differ');
      // Not a blank canvas.
      expect(a.any((byte) => byte != a.first), isTrue);
    });
  });

  testWidgets('PNG export works', (tester) async {
    await tester.runAsync(() async {
      final data = Humation.resolve('felix');
      final png = await renderAvatarToPng(
        createAvatar(
          manifest,
          CreateAvatarOptions(
            selections: data.selections,
            colors: data.colors,
            background: 'FFFFFF',
          ),
        ).toRenderData(),
        pixels: 64,
      );
      expect(png, isNotNull);
      expect(png!.length, greaterThan(0));
    });
  });
}
