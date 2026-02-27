/** @type {import('next').NextConfig} */
const nextConfig = {
  // Required for the multi-stage Docker build — outputs a standalone server.js
  output: "standalone",

  // Disable ESLint during production builds (lint in CI separately)
  eslint: {
    ignoreDuringBuilds: true,
  },
};

module.exports = nextConfig;
