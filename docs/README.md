# Humation docs site

The documentation site: [Fumadocs](https://fumadocs.dev) (Next.js App Router)
with TinaCMS visual editing. The home page embeds the avatar playground, which is
a separate Flutter web app (see [`../playground`](../playground)) hosted on
Firebase.

## Develop

```bash
cd docs
pnpm install
pnpm dev          # http://localhost:3000
```

Content lives in `content/docs/*.mdx`. The sidebar order is
`content/docs/meta.json`.

## The playground embed

The home page iframes `NEXT_PUBLIC_PLAYGROUND_URL` (defaults to the Firebase URL
in `app/(home)/page.tsx`). Point it at wherever you host the playground:

```bash
# .env.local
NEXT_PUBLIC_PLAYGROUND_URL=https://your-playground.web.app
```

## Visual editing (TinaCMS)

`pnpm dev` runs the site under TinaCMS. Open
[http://localhost:3000/admin](http://localhost:3000/admin), pick a doc, and edit
it with a live preview of the real Fumadocs components. Your `.mdx` files stay
the source of truth. Production is plain Fumadocs, so no Tina server is needed to
serve the site.

Regenerate the Tina client after changing the schema in `tina/config.ts`:
restart `pnpm dev` (or run `pnpm build` once). Tina regenerates
`tina/__generated__/` automatically as part of its own CLI lifecycle; there is
no separate script for it.

## Build

```bash
pnpm build
```
