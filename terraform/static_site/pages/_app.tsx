import { AppProps } from 'next/app';
import '../styles/globals.css';
import { useEffect, useState } from 'react';
import SignIn from './signin';

function Upstate_Tech({ Component, pageProps }: AppProps) {
    const [isAuthenticated, setIsAuthenticated] = useState(false);

    useEffect(() => {
        const accessToken = localStorage.getItem('accessToken');
        if (accessToken) {
            setIsAuthenticated(true);
        } else {
            setIsAuthenticated(false);
        }
    }, []);

    if (!isAuthenticated) {
        return <SignIn />;
    }


    return <Component {...pageProps} />;
}

export default Upstate_Tech;
