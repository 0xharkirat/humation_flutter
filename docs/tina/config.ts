import { defineConfig } from "tinacms";
import { fumadocsTemplates } from 'tinacms-fumadocs-pkg/templates';

// Your hosting provider likely exposes this as an environment variable
const branch =
  process.env.GITHUB_BRANCH ||
  process.env.VERCEL_GIT_COMMIT_REF ||
  process.env.HEAD ||
  "main";

export default defineConfig({
  branch,

  // Get this from tina.io
  clientId: process.env.NEXT_PUBLIC_TINA_CLIENT_ID,
  // Get this from tina.io
  token: process.env.TINA_TOKEN,

  build: {
    outputFolder: "admin",
    publicFolder: "public",
  },
  // Uncomment to allow cross-origin requests from non-localhost origins
  // during local development (e.g. GitHub Codespaces, Gitpod, Docker).
  // Use 'private' to allow all private-network IPs (WSL2, Docker, etc.)
  // server: {
  //   allowedOrigins: ['https://your-codespace.github.dev'],
  // },
  media: {
    tina: {
      mediaRoot: 'uploads',
      publicFolder: "public",
    },
  },
  // See docs on content modeling for more info on how to setup new content models: https://tina.io/docs/r/content-modelling-collections/
  schema: {
    collections: [
      {
        name: 'docs',
        label: 'Docs',
        path: 'content/docs',
        format: 'mdx',
        ui: {
          // new docs -> lowercase kebab-case filename (and route) from the title
          filename: {
            slugify: (values) =>
              String(values?.title ?? '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '') || 'untitled',
          },
          router: ({ document }) => {
            const slug = document._sys.relativePath.replace(/\.mdx?$/, '');
            return slug === 'index' ? '/docs' : `/docs/${slug}`;
          },
        },
        fields: [
          { type: 'string', name: 'title', label: 'Title', isTitle: true, required: true },
          {
            type: 'rich-text', name: 'body', label: 'Body', isBody: true,
            templates: [...fumadocsTemplates],
            // Pin the Embed/insert control to the FRONT of the toolbar (tinacms
            // renders the toolbar in this order). 'embed' only shows when
            // `templates` exist (they do), so list it first to surface it.
            // `overrides.toolbar` is the current Tina API (`toolbarOverride` is
            // deprecated).
            overrides: {
              toolbar: ['embed', 'heading', 'link', 'image', 'quote', 'ul', 'ol', 'bold', 'italic', 'code', 'codeBlock', 'table', 'strikethrough', 'mermaid', 'raw', 'hr'],
            },
          },
        ],
      },
      {
        // Navigation editor: a second collection over the SAME content/docs path,
        // scoped to meta.json (format:'json' + match.include:'**/meta' -> globs
        // content/docs/**/meta.json). Coexists with the mdx `docs` collection
        // (different format + match, so they never claim the same file). Editing
        // is save-refresh: reorder `pages`, save, refresh to see the sidebar.
        name: 'meta',
        label: 'Navigation (meta.json)',
        path: 'content/docs',
        format: 'json',
        match: { include: '**/meta' },
        // Edit existing meta.json files; Tina's "Add file" can't satisfy the
        // **/meta glob (it would write undefined.json), so hide create/delete.
        ui: { allowedActions: { create: false, delete: false } },
        fields: [
          { type: 'string', name: 'title', label: 'Sidebar title' },
          { type: 'string', name: 'description', label: 'Description' },
          { type: 'string', name: 'icon', label: 'Icon' },
          { type: 'boolean', name: 'root', label: 'Root section (sidebar tab)' },
          { type: 'boolean', name: 'defaultOpen', label: 'Open by default' },
          { type: 'boolean', name: 'collapsible', label: 'Collapsible' },
          { type: 'string', name: 'pagesIndex', label: 'Index page slug' },
          {
            type: 'string',
            name: 'pages',
            list: true,
            description:
              'Sidebar order. Keep "..." (= all other pages) or new docs vanish from the sidebar. Tokens: "slug"=page/folder · "..."=everything else (keep last) · "---Label---"=separator · "[Text](url)"=link · "!slug"=hide',
          },
        ],
      },
    ],
  },
  search: {
    tina: {
      // Don't paste your search token here. Keep it in your .env file and read
      // it from there (get the token from tina.io). Unset is fine for local dev
      // and local builds; a cloud build with search enabled needs it set.
      indexerToken: process.env.NEXT_PUBLIC_TINA_SEARCH_TOKEN,
      stopwordLanguages: ['eng'],
    },
    indexBatchSize: 100,
    maxSearchIndexFieldLength: 100,
  },
});
