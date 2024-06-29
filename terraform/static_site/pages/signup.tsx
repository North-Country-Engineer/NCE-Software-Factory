import { useEffect, useState } from 'react';

export default function SignUp() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');

    useEffect(()=> {
        console.log(process.env.NEXT_PUBLIC_API_GATEWAY_ENDPOINT)
    },[])

    const handleSubmit = async (event:any) => {
        event.preventDefault();


        const res = await fetch(`${process.env.NEXT_PUBLIC_API_GATEWAY_ENDPOINT}/signup`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email, password })
        });

        if (res.ok) {
            alert('Sign-Up Successful!');
        } else {
            const data = await res.json();
            alert(`Sign-Up Failed! ${data.error}`);
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
