/** @type {import('next').NextConfig} */
const nextConfig = {
    output: 'export',
    trailingSlash: true, // Ensure trailing slashes for all paths
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
