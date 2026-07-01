# Humation playground

A Flutter web avatar builder, in the style of
[humation.app/avatar](https://humation.app/avatar): a live preview, a seed field,
per-slot part pickers, colour swatches, randomize, and PNG download. It uses
`humation_flutter` and is embedded on the docs home page.

## Run locally

```bash
flutter run -d chrome
```

## Deploy to Firebase Hosting

Pick your Firebase project once (updates `.firebaserc`):

```bash
firebase use --add
```

Then build and deploy:

```bash
flutter build web --release
firebase deploy --only hosting
```

Point the docs home page at the resulting URL by setting
`NEXT_PUBLIC_PLAYGROUND_URL` in the docs site (see `../docs/README.md`).
