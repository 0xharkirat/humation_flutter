import Link from 'next/link';

const project = [
  { label: 'Documentation', href: '/docs' },
  { label: 'GitHub', href: 'https://github.com/0xharkirat/humation_flutter' },
  { label: 'humation_flutter', href: 'https://pub.dev/packages/humation_flutter' },
  { label: 'humation', href: 'https://pub.dev/packages/humation' },
];

const humation = [
  { label: 'humation.app', href: 'https://humation.app' },
  { label: 'humation-labs/humation', href: 'https://github.com/humation-labs/humation' },
  { label: 'humation-swift', href: 'https://github.com/humation-labs/humation-swift' },
];

export function Footer() {
  return (
    <footer className="mt-8 border-t border-fd-border">
      <div className="mx-auto max-w-4xl px-4 py-10">
        <div className="flex flex-col gap-8 sm:flex-row sm:justify-between">
          <div className="max-w-sm">
            <div className="font-semibold">Humation Flutter</div>
            <p className="mt-2 text-sm text-fd-muted-foreground">
              A community Flutter and Dart port of Humation, maintained by Hark
              Singh. Not affiliated with the Humation Labs team.
            </p>
          </div>
          <div className="flex gap-12 text-sm">
            <FooterColumn title="This project" links={project} />
            <FooterColumn title="Humation" links={humation} />
          </div>
        </div>
        <div className="mt-8 border-t border-fd-border pt-6 text-center text-sm text-fd-muted-foreground">
          Made with <span aria-label="love">♥</span> by{' '}
          <a
            href="https://github.com/0xharkirat"
            target="_blank"
            rel="noreferrer"
            className="font-medium text-fd-foreground hover:underline"
          >
            Hark Singh
          </a>
        </div>
      </div>
    </footer>
  );
}

function FooterColumn({
  title,
  links,
}: {
  title: string;
  links: { label: string; href: string }[];
}) {
  return (
    <div>
      <div className="mb-2 font-medium text-fd-foreground">{title}</div>
      <ul className="space-y-1.5 text-fd-muted-foreground">
        {links.map((link) => (
          <li key={link.href}>
            <FooterLink {...link} />
          </li>
        ))}
      </ul>
    </div>
  );
}

function FooterLink({ label, href }: { label: string; href: string }) {
  if (href.startsWith('http')) {
    return (
      <a
        href={href}
        target="_blank"
        rel="noreferrer"
        className="transition-colors hover:text-fd-foreground"
      >
        {label}
      </a>
    );
  }
  return (
    <Link href={href} className="transition-colors hover:text-fd-foreground">
      {label}
    </Link>
  );
}
