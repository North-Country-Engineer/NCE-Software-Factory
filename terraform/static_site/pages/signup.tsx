import { useState } from 'react';

export default function SignUp() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');

    const handleSubmit = async (event:any) => {
        event.preventDefault();

        const res = await fetch('/api/signup', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email, password })
        });

        if (res.ok) {
        // Handle successful sign-up
        alert('Sign-Up Successful!');
        } else {
        // Handle error
        alert('Sign-Up Failed!');
        }
    };

    return (
        <form onSubmit={handleSubmit}>
        <h1>Sign Up</h1>
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
        <button type="submit">Sign Up</button>
        </form>
    );
}
