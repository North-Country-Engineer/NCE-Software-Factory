import { NextApiRequest, NextApiResponse } from 'next';
import { CognitoUserPool, CognitoUserAttribute } from 'amazon-cognito-identity-js';

const poolData = {
    UserPoolId: process.env.NEXT_PUBLIC_USER_POOL_ID!,
    ClientId: process.env.NEXT_PUBLIC_USER_POOL_CLIENT_ID!,
};

const userPool = new CognitoUserPool(poolData);

export default function handler(req: NextApiRequest, res: NextApiResponse) {
    if (req.method === 'POST') {
        const { email, password } = req.body;

        const attributeList = [
            new CognitoUserAttribute({ Name: 'email', Value: email })
        ];

        userPool.signUp(email, password, attributeList, [], (err, result) => {
            if (err) {
                res.status(400).json({ error: err.message });
                return;
            }
            res.status(200).json(result);
        });
    } else {
        res.status(405).json({ error: 'Method not allowed' });
    }
}
