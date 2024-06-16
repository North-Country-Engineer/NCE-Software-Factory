import { NextApiRequest, NextApiResponse } from 'next';
import { CognitoUserPool, CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';

const poolData = {
    UserPoolId: process.env.NEXT_PUBLIC_USER_POOL_ID!,
    ClientId: process.env.NEXT_PUBLIC_USER_POOL_CLIENT_ID!,
};

const userPool = new CognitoUserPool(poolData);

export default function handler(req: NextApiRequest, res: NextApiResponse) {
    if (req.method === 'POST') {
        const { email, password } = req.body;

        const authenticationDetails = new AuthenticationDetails({
            Username: email,
            Password: password,
        });

        const userData = {
            Username: email,
            Pool: userPool,
        };

        const cognitoUser = new CognitoUser(userData);

        cognitoUser.authenticateUser(authenticationDetails, {
            onSuccess: (result) => {
                res.status(200).json(result);
            },
            onFailure: (err) => {
                res.status(400).json({ error: err.message });
            },
        });
    } else {
        res.status(405).json({ error: 'Method not allowed' });
    }
}
