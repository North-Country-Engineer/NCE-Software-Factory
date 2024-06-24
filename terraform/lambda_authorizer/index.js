import jwt from 'jsonwebtoken';
import jwkToPem from 'jwk-to-pem';
import axios from 'axios';

export const handler = async (event) => {
    const token = event.authorizationToken;
    const userPoolId = process.env.COGNITO_USER_POOL_ID;
    const region = process.env.AWS_REGION;

    const jwksUrl = `https://cognito-idp.${region}.amazonaws.com/${userPoolId}/.well-known/jwks.json`;
    const response = await axios.get(jwksUrl);
    const jwks = response.data.keys;

    const decoded = jwt.decode(token, { complete: true });
    if (!decoded) {
        return generatePolicy('user', 'Deny', event.methodArn);
    }

    const kid = decoded.header.kid;
    const key = jwks.find(k => k.kid === kid);
    if (!key) {
        return generatePolicy('user', 'Deny', event.methodArn);
    }

    const pem = jwkToPem(key);
    try {
        jwt.verify(token, pem, { algorithms: ['RS256'] });
        return generatePolicy('user', 'Allow', event.methodArn);
    } catch (err) {
        return generatePolicy('user', 'Deny', event.methodArn);
    }
};

const generatePolicy = (principalId, effect, resource) => {
    const authResponse = { principalId };

    if (effect && resource) {
        const policyDocument = {
            Version: '2012-10-17',
            Statement: [{
                Action: 'execute-api:Invoke',
                Effect: effect,
                Resource: resource,
            }],
        };
        authResponse.policyDocument = policyDocument;
    }

    return authResponse;
};
