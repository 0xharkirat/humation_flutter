import type { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = {
  description:
    'Deterministic, hand-drawn kawaii avatars for Flutter. Give it a seed and it draws the same avatar every time, natively. No images to store, no network, no AI.',
};

// The playground is a separate Flutter web app, hosted on Firebase. Override
// with NEXT_PUBLIC_PLAYGROUND_URL if you host it elsewhere.
const PLAYGROUND_URL =
  process.env.NEXT_PUBLIC_PLAYGROUND_URL ?? 'https://humation-flutter.web.app';

const features = [
  {
    title: 'Deterministic',
    body: 'A seed maps to a fixed avatar. Store one short string, never an image.',
  },
  {
    title: 'Native',
    body: 'Drawn on the Flutter canvas. No web view, no network, works offline.',
  },
  {
    title: 'Customizable',
    body: 'Pick parts and recolour with a line of code, or let the seed decide.',
  },
];

export default function HomePage() {
  return (
    <main className="flex flex-1 flex-col">
      <section className="mx-auto flex w-full max-w-4xl flex-col items-center px-4 pb-8 pt-16 text-center">
        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
          Humation Flutter
        </h1>
        <p className="mt-4 max-w-2xl text-lg text-fd-muted-foreground">
          Deterministic, hand-drawn kawaii avatars for Flutter. Give it a seed
          and it draws the same avatar every time, natively. No images to store,
          no network, no AI.
        </p>
        <div className="mt-8 flex flex-wrap justify-center gap-3">
          <Link
            href="/docs/quick-start"
            className="rounded-lg bg-fd-primary px-5 py-2.5 font-medium text-fd-primary-foreground transition-opacity hover:opacity-90"
          >
            Get started
          </Link>
          <a
            href="https://github.com/0xharkirat/humation_flutter"
            className="rounded-lg border border-fd-border px-5 py-2.5 font-medium transition-colors hover:bg-fd-accent"
          >
            GitHub
          </a>
        </div>
        <div className="mt-10 w-full max-w-3xl rounded-2xl border border-fd-border bg-white p-4">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/img/avatars-grid.png"
            alt="Avatars from different seeds"
            className="w-full"
          />
        </div>
      </section>

      <section className="mx-auto w-full max-w-4xl px-4 pb-16 pt-4">
        <div className="mb-4 text-center">
          <h2 className="text-2xl font-semibold">Try the playground</h2>
          <div className="mt-1 flex flex-wrap items-baseline justify-center gap-x-3 gap-y-1">
            <p className="text-fd-muted-foreground">
              Build an avatar and download it. Same engine as the package,
              running on Flutter web.
            </p>
            <a
              href={PLAYGROUND_URL}
              target="_blank"
              rel="noreferrer"
              className="text-sm text-fd-muted-foreground underline hover:text-fd-foreground"
            >
              Open in a new tab
            </a>
          </div>
        </div>
        <div className="overflow-hidden rounded-xl border border-fd-border bg-fd-card shadow-sm">
          <iframe
            src={PLAYGROUND_URL}
            title="Humation avatar playground"
            className="h-[680px] w-full"
            loading="lazy"
          />
        </div>
      </section>

      <section className="mx-auto grid w-full max-w-4xl gap-4 px-4 pb-16 sm:grid-cols-3">
        {features.map((feature) => (
          <div
            key={feature.title}
            className="rounded-xl border border-fd-border p-5"
          >
            <h3 className="font-semibold">{feature.title}</h3>
            <p className="mt-1 text-sm text-fd-muted-foreground">
              {feature.body}
            </p>
          </div>
        ))}
      </section>
    </main>
  );
}
