/** @type {import('next').NextConfig} */
const nextConfig = {
  serverExternalPackages: ["pg"],
  webpack: (config) => {
    config.module.rules.push({
      test: /\.sql$/,
      type: "asset/source",
    });
    return config;
  },
  async redirects() {
    return [
      { source: "/p1", destination: "/?src=p1", permanent: false },
      { source: "/p2", destination: "/?src=p2", permanent: false },
      { source: "/p3", destination: "/?src=p3", permanent: false },
      { source: "/prove", destination: "/", permanent: false },
    ];
  },
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [{ key: "Cache-Control", value: "public, max-age=0, must-revalidate" }],
      },
    ];
  },
};

module.exports = nextConfig;
