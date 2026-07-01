import { createMDX } from 'fumadocs-mdx/next';

const withMDX = createMDX();

/** @type {import('next').NextConfig} */
const config = {
  transpilePackages: ['tinacms-fumadocs-pkg'],
  reactStrictMode: true,
};

export default withMDX(config);
