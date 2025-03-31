const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const cors = require('cors')({ origin: true });

admin.initializeApp();
const db = admin.firestore();

const FATSECRET_TOKEN_DOC = 'fatsecret_token';
const FATSECRET_COLLECTION = 'app_config';
const OAUTH_URL = 'https://oauth.fatsecret.com/oauth2/token';
const BASE_URL = 'https://platform.fatsecret.com/rest/server.api';

/**
 * Helper function to get FatSecret API credentials from Firestore
 * These are stored in Firestore rather than directly in the code for security
 */
async function getCredentials() {
    try {
        const configDoc = await db.collection('app_config').doc('fatsecret_credentials').get();

        if (!configDoc.exists) {
            console.error('FatSecret credentials not found in Firestore');
            return null;
        }

        const data = configDoc.data();
        return {
            apiKey: data.api_key,
            apiSecret: data.api_secret
        };
    } catch (error) {
        console.error('Error fetching FatSecret credentials:', error);
        return null;
    }
}

/**
 * Get or refresh OAuth access token for FatSecret API
 */
async function getAccessToken() {
    try {
        // Check if we have a valid token
        const tokenDoc = await db.collection(FATSECRET_COLLECTION).doc(FATSECRET_TOKEN_DOC).get();
        const tokenData = tokenDoc.exists ? tokenDoc.data() : null;

        if (tokenData && tokenData.expiresAt && tokenData.expiresAt.toDate() > new Date()) {
            console.log('Using existing valid token');
            return tokenData.accessToken;
        }

        // We need to get a new token
        console.log('Getting new FatSecret token');
        const credentials = await getCredentials();

        if (!credentials) {
            throw new Error('Failed to get FatSecret credentials');
        }

        // Request new token
        const tokenResponse = await axios.post(
            OAUTH_URL,
            'grant_type=client_credentials&scope=basic',
            {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                auth: {
                    username: credentials.apiKey,
                    password: credentials.apiSecret
                }
            }
        );

        if (tokenResponse.status === 200) {
            const data = tokenResponse.data;
            const accessToken = data.access_token;

            // Calculate expiry (subtract 5 minutes for safety margin)
            const expiresIn = data.expires_in;
            const expiresAt = admin.firestore.Timestamp.fromDate(
                new Date(Date.now() + (expiresIn - 300) * 1000)
            );

            // Store the token
            await db.collection(FATSECRET_COLLECTION).doc(FATSECRET_TOKEN_DOC).set({
                accessToken,
                expiresAt,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            return accessToken;
        } else {
            throw new Error(`Failed to get access token: ${tokenResponse.status}`);
        }
    } catch (error) {
        console.error('Error in getAccessToken:', error);
        throw error;
    }
}

/**
 * Callable function to search foods in FatSecret API
 */
exports.searchFoods = functions.https.onCall(async (data, context) => {
    console.log(`Search request received: ${JSON.stringify(data)}`);
    // Ensure user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'You must be signed in to use this feature');
    }

    try {
        const { query, maxResults = 50 } = data;

        if (!query || query.trim() === '') {
            return { foods: [] };
        }

        console.log(`Searching foods with query: "${query}", max results: ${maxResults}`);

        // Get access token
        const token = await getAccessToken();

        // Call FatSecret API
        const response = await axios.get(BASE_URL, {
            params: {
                method: 'foods.search',
                format: 'json',
                search_expression: query,
                max_results: maxResults
            },
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        console.log('FatSecret API response received');
        console.log(`API response: ${JSON.stringify(response.data)}`);

        // Check if foods were found
        if (!response.data.foods || !response.data.foods.food) {
            console.log('No foods found in API response');
            return { foods: { food: [] } };
        }

        console.log(`Found ${Array.isArray(response.data.foods.food) ?
            response.data.foods.food.length : 1} food items`);

        return response.data;
    } catch (error) {
        console.error('Error details:', error);
        throw new functions.https.HttpsError('internal', 'Failed to search foods');
    }
});

/**
 * Callable function to get food details by ID
 */
exports.getFoodById = functions.https.onCall(async (data, context) => {
    // Ensure user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'You must be signed in to use this feature');
    }

    try {
        const { foodId } = data;

        if (!foodId) {
            throw new functions.https.HttpsError('invalid-argument', 'Food ID is required');
        }

        // Get access token
        const token = await getAccessToken();

        // Call FatSecret API
        const response = await axios.get(BASE_URL, {
            params: {
                method: 'food.get.v2',
                format: 'json',
                food_id: foodId
            },
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        return response.data;
    } catch (error) {
        console.error('Error getting food details:', error);
        throw new functions.https.HttpsError('internal', 'Failed to get food details');
    }
});

/**
 * Generic proxy for all FatSecret API methods (more flexible)
 */
exports.fatSecretProxy = functions.https.onCall(async (data, context) => {
    // Ensure user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'You must be signed in to use this feature');
    }

    try {
        const { method, params = {} } = data;

        if (!method) {
            throw new functions.https.HttpsError('invalid-argument', 'FatSecret method is required');
        }

        // Get access token
        const token = await getAccessToken();

        // Call FatSecret API
        const response = await axios.get(BASE_URL, {
            params: {
                method,
                format: 'json',
                ...params
            },
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        return response.data;
    } catch (error) {
        console.error('Error in FatSecret proxy:', error);
        throw new functions.https.HttpsError('internal', 'Failed to call FatSecret API');
    }
});

exports.searchFoodsHttp = functions.https.onRequest(async (req, res) => {
    // Add CORS middleware
    cors(req, res, async () => {
        try {
            // Check if this is a POST request with data
            if (req.method !== 'POST') {
                return res.status(400).json({ error: 'Please send a POST request' });
            }

            const { query, maxResults = 50 } = req.body;

            if (!query || query.trim() === '') {
                return res.json({ foods: { food: [] } });
            }

            console.log(`Searching for foods matching: ${query}`);

            const token = await getAccessToken();

            // Call FatSecret API
            const response = await axios.get(BASE_URL, {
                params: {
                    method: 'foods.search',
                    format: 'json',
                    search_expression: query,
                    max_results: maxResults
                },
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            console.log(`API Response received: ${JSON.stringify(response.data).substring(0, 100)}...`);
            return res.json(response.data);
        } catch (error) {
            console.error('Error searching foods:', error);
            return res.status(500).json({ error: 'Failed to search foods' });
        }
    });
});
