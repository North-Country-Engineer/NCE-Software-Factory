import AWS from 'aws-sdk';

const Cognito = new AWS.CognitoIdentityServiceProvider();

export const handler = async (event) => {
    const body = JSON.parse(event.body);

    if (event.resource === '/signup' && event.httpMethod === 'POST') {
        const params = {
            ClientId: process.env.COGNITO_CLIENT_ID,
            Username: body.email,
            Password: body.password,
            UserAttributes: [
                {
                    Name: 'email',
                    Value: body.email,
                },
            ],
        };

        try {
            const result = await Cognito.signUp(params).promise();

            return {
                statusCode: 200,
                body: JSON.stringify(result),
            };
        } catch (error) {
            return {
                statusCode: 400,
                body: JSON.stringify({ error: error.message }),
        };
        }
    }

    if (event.resource === '/signin' && event.httpMethod === 'POST') {
        const params = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: process.env.COGNITO_CLIENT_ID,
            AuthParameters: {
                USERNAME: body.email,
                PASSWORD: body.password,
            },
        };

        try {
            const result = await Cognito.initiateAuth(params).promise();
            return {
                statusCode: 200,
                body: JSON.stringify(result),
            };
        } catch (error) {
            return {
                statusCode: 400,
                body: JSON.stringify({ error: error.message }),
            };
        }
    }

    if (event.resource === '/verify' && event.httpMethod === 'POST') {
        const token = body.token;

        try {
            const payload = await verifier.verify(token);
            return {
                statusCode: 200,
                body: JSON.stringify(payload),
            };
        } catch (error) {
            return {
                statusCode: 401,
                body: JSON.stringify({ error: 'Token is invalid' }),
            };
        }
    }

    return {
        statusCode: 404,
        body: JSON.stringify({ error: 'Not Found' }),
    };
};
