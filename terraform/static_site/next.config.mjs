/** @type {import('next').NextConfig} */
const nextConfig = {
    output: 'export',
    async redirects() {
        return [
            {
                source: '/:path*',
                destination: '/',
                permanent: true,
            },
        ];
    },
    trailingSlash: true,
};

export default nextConfig;
