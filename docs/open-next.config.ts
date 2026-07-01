import { defineCloudflareConfig } from '@opennextjs/cloudflare';

// No R2 incremental cache: this site has no ISR (revalidate-based) routes.
// Pages are either static (prerendered) or fully dynamic with no-store fetch
// (the Tina-wired docs page), so the default cache is enough.
export default defineCloudflareConfig();
