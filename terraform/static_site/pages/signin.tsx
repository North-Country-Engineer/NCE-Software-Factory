import { useState } from 'react';

export default function SignIn() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');

    const handleSubmit = async (event:any) => {
        event.preventDefault();

        const res = await fetch('/api/signin', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email, password })
        });

        if (res.ok) {
        // Handle successful sign-in
        alert('Sign-In Successful!');
        } else {
        // Handle error
        alert('Sign-In Failed!');
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
