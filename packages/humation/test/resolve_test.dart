import 'package:humation/humation.dart';
import 'package:test/test.dart';

/// A tiny synthetic pack: two slots, a couple of parts each, one alias.
HumationManifest _manifest() => HumationManifest.fromJson({
  'schemaVersion': '1.0',
  'template': {'id': 't', 'shortId': 't', 'name': 'T', 'version': '1'},
  'defaults': {
    'selections': {'head': 'p1', 'body': 'b1'},
    'colors': {'hair': '000000', 'skin': 'FFFFFF'},
    'background': 'transparent',
    'crop': 'avatar',
  },
  'colors': [
    {
      'id': 'hair',
      'label': 'Hair',
      'default': '000000',
      'cssVariable': '--hm-hair',
    },
    {
      'id': 'skin',
      'label': 'Skin',
      'default': 'FFFFFF',
      'cssVariable': '--hm-skin',
    },
  ],
  'crops': {
    'avatar': {'x': 0, 'y': 0, 'width': 80, 'height': 80},
  },
  'selectionSlots': [
    {'id': 'head', 'label': 'Head', 'defaultPart': 'p1'},
    {'id': 'body', 'label': 'Body', 'defaultPart': 'b1'},
  ],
  'uiGroups': [],
  'layerSlots': [
    {
      'id': 'body',
      'label': 'Body',
      'order': 1,
      'offset': {'x': 0, 'y': 40},
      'size': {'width': 80, 'height': 80},
    },
    {
      'id': 'head',
      'label': 'Head',
      'order': 2,
      'offset': {'x': 0, 'y': 0},
      'size': {'width': 80, 'height': 80},
    },
  ],
  'parts': [
    {
      'id': 'p1',
      'selectionSlot': 'head',
      'uiGroups': [],
      'layers': [
        {
          'layerSlot': 'head',
          'svg': '<svg><circle cx="1" cy="1" r="1"/></svg>',
        },
      ],
    },
    {
      'id': 'p2',
      'selectionSlot': 'head',
      'uiGroups': [],
      'layers': [
        {'layerSlot': 'head', 'svg': '<svg><rect width="2" height="2"/></svg>'},
      ],
    },
    {
      'id': 'b1',
      'selectionSlot': 'body',
      'uiGroups': [],
      'layers': [
        {'layerSlot': 'body', 'svg': '<svg><rect width="2" height="2"/></svg>'},
      ],
    },
  ],
  'aliases': [
    {'alias': 'head-cool', 'targetId': 'p2', 'status': 'active'},
  ],
});

void main() {
  final manifest = _manifest();

  test('seed selection is deterministic', () {
    final a = createAvatar(manifest, const CreateAvatarOptions(seed: 'x'));
    final b = createAvatar(manifest, const CreateAvatarOptions(seed: 'x'));
    expect(a.state, b.state);
  });

  test('defaults apply without a seed', () {
    final avatar = createAvatar(manifest);
    expect(avatar.state.selections['head'], 'p1');
    expect(avatar.state.selections['body'], 'b1');
  });

  test('explicit selection overrides seed', () {
    final avatar = createAvatar(
      manifest,
      const CreateAvatarOptions(seed: 'x', selections: {'head': 'p2'}),
    );
    expect(avatar.state.selections['head'], 'p2');
  });

  group('resolvePartId', () {
    test('canonical id', () {
      expect(resolvePartId('p1', manifest), 'p1');
    });
    test('slot-scoped name via alias', () {
      expect(resolvePartId('cool', manifest, slotId: 'head'), 'p2');
    });
    test('global alias', () {
      expect(resolvePartId('head-cool', manifest), 'p2');
    });
    test('unknown throws', () {
      expect(() => resolvePartId('nope', manifest), throwsArgumentError);
    });
  });

  test('rejects a part used in the wrong slot', () {
    expect(
      () => createAvatar(
        manifest,
        const CreateAvatarOptions(selections: {'body': 'p1'}),
      ),
      throwsArgumentError,
    );
  });

  group('toSvg', () {
    test('includes the crop viewBox and colour variables', () {
      final svg = createAvatar(
        manifest,
        const CreateAvatarOptions(colors: {'hair': '#123456'}),
      ).toSvg();
      expect(svg, contains('viewBox="0 0 80 80"'));
      expect(svg, contains('--hm-hair:#123456'));
    });

    test('paints a background rect when not transparent', () {
      final svg = createAvatar(
        manifest,
        const CreateAvatarOptions(background: 'FFFFFF'),
      ).toSvg();
      expect(svg, contains('<rect'));
      expect(svg, contains('fill="#FFFFFF"'));
    });
  });

  test('toRenderData orders fragments back-to-front', () {
    final data = createAvatar(manifest).toRenderData();
    expect(data.fragments.first.layerSlot, 'body'); // order 1
    expect(data.fragments.last.layerSlot, 'head'); // order 2
  });

  test('AvatarState.copyWith overrides only the given field', () {
    final state = createAvatar(manifest).state;
    final zoomed = state.copyWith(crop: 'zoom');
    expect(zoomed.crop, 'zoom');
    expect(zoomed.selections, state.selections);
    expect(zoomed.colors, state.colors);
    expect(zoomed.background, state.background);
  });
}
