import 'package:humation/humation.dart';
import 'package:humation_assets_humation_1/humation_assets_humation_1.dart';
import 'package:test/test.dart';

void main() {
  final manifest = humation1Manifest;

  test('decodes the embedded pack', () {
    expect(manifest.template.shortId, isNotEmpty);
    expect(manifest.parts.length, 86);
  });

  test('part counts per slot', () {
    expect(manifest.partsInSlot('head').length, 24);
    expect(manifest.partsInSlot('body').length, 8);
    expect(manifest.partsInSlot('bottom').length, 8);
    expect(manifest.partsInSlot('item').length, 43);
    expect(manifest.partsInSlot('glasses').length, 3);
  });

  test('bundled pack is renderable (no unsupported SVG)', () {
    expect(validateManifest(manifest), isEmpty);
  });

  group('deterministic selection matches the reference engine', () {
    // Generated from the reference TypeScript selection over the same manifest.
    const references = <String, Map<String, String>>{
      'felix': {
        'bottom': 'hm1-p-000039',
        'body': 'hm1-p-000026',
        'head': 'hm1-p-000008',
        'item': 'hm1-p-000076',
        'glasses': 'hm1-p-000057',
      },
      'user-123': {
        'bottom': 'hm1-p-000037',
        'body': 'hm1-p-000028',
        'head': 'hm1-p-000018',
        'item': 'hm1-p-000070',
        'glasses': 'hm1-p-000057',
      },
      'user-456': {
        'bottom': 'hm1-p-000034',
        'body': 'hm1-p-000031',
        'head': 'hm1-p-000013',
        'item': 'hm1-p-000076',
        'glasses': 'hm1-p-000058',
      },
      'humation': {
        'bottom': 'hm1-p-000036',
        'body': 'hm1-p-000029',
        'head': 'hm1-p-000011',
        'item': 'hm1-p-000072',
        'glasses': 'hm1-p-000056',
      },
      '用户': {
        'bottom': 'hm1-p-000038',
        'body': 'hm1-p-000027',
        'head': 'hm1-p-000001',
        'item': 'hm1-p-000071',
        'glasses': 'hm1-p-000058',
      },
      'hark': {
        'bottom': 'hm1-p-000039',
        'body': 'hm1-p-000026',
        'head': 'hm1-p-000008',
        'item': 'hm1-p-000079',
        'glasses': 'hm1-p-000058',
      },
    };

    references.forEach((seed, expected) {
      test('seed "$seed"', () {
        final state = resolveAvatarState(
          manifest,
          CreateAvatarOptions(seed: seed),
        );
        expect(state.selections, expected);
      });
    });
  });
}
