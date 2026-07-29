/** @type {import('next').NextConfig} */
const nextConfig = {
  outputFileTracingIncludes: {
    "/api/*": ["./sql/**/*"],
    "/seed": ["./sql/**/*"],
  },
};

module.exports = nextConfig;
