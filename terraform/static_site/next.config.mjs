/** @type {import('next').NextConfig} */
const nextConfig = {
    output: 'export',
    trailingSlash: true,
    env: {
        API_GATEWAY_ENDPOINT: process.env.API_GATEWAY_ENDPOINT,
    },
    exportPathMap: async function (
        defaultPathMap,
        { dev, dir, outDir, distDir, buildId }
    ) {
        return {
            '/': { page: '/' },
            '/signin': { page: '/signin' },
            '/signup': { page: '/signup' },
            // Add other routes as necessary
        };
    },
};

export default nextConfig;
