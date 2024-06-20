import { useState } from 'react';

export default function SignIn() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');

    const handleSubmit = async (event:any) => {
        event.preventDefault();

        const res = await fetch('https://x9f3g8bvi6.execute-api.us-east-1.amazonaws.com/serverless_lambda_stage/signin', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email, password })
        });

        const data = await res.json();

        if (res.ok) {
            localStorage.setItem('accessToken', data.AuthenticationResult.AccessToken);
            localStorage.setItem('idToken', data.AuthenticationResult.IdToken);
            localStorage.setItem('refreshToken', data.AuthenticationResult.RefreshToken);
            alert('Sign-In Successful!');
            console.log(data);
        } else {
            // Handle error
            alert('Sign-In Failed! ' + data.error);
        }
    };

    return (
        <form onSubmit={handleSubmit}>
        <h1>Sign In</h1>
        <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Email"
        />
        <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Password"
        />
        <button type="submit">Sign In</button>
        </form>
    );
}
