import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humation_flutter/humation_flutter.dart';

void main() {
  testWidgets('HumationPartPreview builds for a part', (tester) async {
    final head = getPartsForSlot(humation1Manifest, 'head').first;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: HumationPartPreview(part: head, size: 64)),
      ),
    );
    expect(find.byType(HumationPartPreview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HumationPartPreview zoom does not throw', (tester) async {
    final glasses = getPartsForSlot(humation1Manifest, 'glasses').first;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: HumationPartPreview(part: glasses, size: 64, zoom: 2.15),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
