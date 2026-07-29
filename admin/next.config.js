/** @type {import('next').NextConfig} */
const nextConfig = {
  webpack: (config) => {
    config.module.rules.push({
      test: /\.sql$/,
      type: "asset/source",
    });
    return config;
  },
};

module.exports = nextConfig;
