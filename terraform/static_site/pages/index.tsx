import Link from 'next/link';

export default function Home() {
    return (
        <div>
        <h1>Welcome to the Home Page</h1>
        <nav>
            <ul>
            <li><Link href="/signup">Sign Up</Link></li>
            <li><Link href="/signin">Sign In</Link></li>
            </ul>
        </nav>
        </div>
    );
}