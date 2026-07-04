import type { Metadata } from 'next';
import { RootProvider } from 'fumadocs-ui/provider/next';
import './global.css';
import { Inter } from 'next/font/google';
import { Footer } from '@/components/footer';

const inter = Inter({
  subsets: ['latin'],
});

// metadataBase anchors relative and file-convention URLs (like
// opengraph-image.png) into absolute ones for link unfurling. Update this if
// the site moves to a custom domain.
export const metadata: Metadata = {
  metadataBase: new URL('https://humation-flutter.vercel.app'),
  title: {
    default: 'Humation Flutter',
    template: '%s | Humation Flutter',
  },
  description:
    'Deterministic, hand-drawn kawaii avatars for Flutter. Give it a seed and it draws the same avatar every time, natively. No images to store, no network, no AI.',
  openGraph: {
    type: 'website',
    siteName: 'Humation Flutter',
  },
  twitter: {
    card: 'summary_large_image',
  },
};

export default function Layout({ children }: LayoutProps<'/'>) {
  return (
    <html lang="en" className={inter.className} suppressHydrationWarning>
      <body className="flex min-h-screen flex-col">
        <RootProvider>
          <div className="flex flex-1 flex-col">{children}</div>
          <Footer />
        </RootProvider>
      </body>
    </html>
  );
}
