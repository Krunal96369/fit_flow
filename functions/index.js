// Import Firebase Functions v2
const { onCall, onRequest } = require("firebase-functions/v2/https");
const admin = require('firebase-admin');
const axios = require('axios');
const cors = require('cors')({ origin: true });

// Helper function to safely stringify JSON
function safeJsonStringify(obj) {
    try {
        return JSON.stringify(obj);
    } catch (e) {
        return `[Error serializing object: ${e.message}]`;
    }
}

// Initialize Firebase Admin
admin.initializeApp();

// Base URL for FatSecret API
const BASE_URL = 'https://platform.fatsecret.com/rest/server.api';

// Helper function to get FatSecret API credentials from Firestore
async function getCredentials() {
    try {
        console.log('Attempting to retrieve FatSecret API credentials');

        // First try to get credentials from Firestore
        const configDoc = await admin.firestore()
            .collection('app_config')
            .doc('fatsecret_credentials')
            .get();

        if (configDoc.exists) {
            const data = configDoc.data();

            // If Firestore has valid credentials, use them
            if (data.fatsecret_api_key && data.fatsecret_api_secret) {
                console.log('Using FatSecret credentials from Firestore');
                return {
                    apiKey: data.fatsecret_api_key,
                    apiSecret: data.fatsecret_api_secret
                };
            } else {
                console.log('Firestore document exists but credentials are incomplete');
            }
        } else {
            console.log('Firestore credentials document not found');
        }

        // If Firestore credentials are not available, fallback to Remote Config
        console.log('Firestore credentials not found or incomplete, trying Remote Config');
        const remoteConfig = admin.remoteConfig();
        const template = await remoteConfig.getTemplate();

        console.log('Remote Config template retrieved, checking for credentials');

        const apiKey = template.parameters.fatsecret_api_key?.defaultValue?.value;
        const apiSecret = template.parameters.fatsecret_api_secret?.defaultValue?.value;

        if (!apiKey || !apiSecret) {
            console.error('FatSecret credentials not found in Remote Config');
            console.log('Remote Config parameters available:', Object.keys(template.parameters).join(', '));
            throw new Error('FatSecret credentials not configured in Remote Config');
        }

        console.log('Using FatSecret credentials from Remote Config');
        return {
            apiKey: apiKey,
            apiSecret: apiSecret
        };
    } catch (error) {
        console.error('Error fetching FatSecret credentials:', error);

        // More detailed error for specific cases
        if (error.code === 'permission-denied') {
            throw new Error('Permission denied when accessing credentials. Check Firebase service account permissions.');
        }

        if (error.code === 'resource-exhausted') {
            throw new Error('Resource quota exceeded when accessing credentials. Check Firestore/RemoteConfig quotas.');
        }

        if (error.code === 'unavailable') {
            throw new Error('Service unavailable when accessing credentials. Firebase may be experiencing issues.');
        }

        throw new Error(`Failed to retrieve FatSecret API credentials: ${error.message}`);
    }
}

// Helper function to get access token for FatSecret API
async function getAccessToken() {
    try {
        console.log('Attempting to get access token for FatSecret API');

        // Get credentials from Firestore
        const credentials = await getCredentials();

        if (!credentials.apiKey || !credentials.apiSecret) {
            console.error('Invalid FatSecret API credentials. API key or secret is missing.');
            throw new Error('FatSecret API credentials not set or invalid');
        }

        // Hide full credentials in logs but show part for debugging
        const maskedKey = credentials.apiKey.substring(0, 4) + '...' +
            credentials.apiKey.substring(credentials.apiKey.length - 4);
        const maskedSecret = credentials.apiSecret.substring(0, 4) + '...' +
            credentials.apiSecret.substring(credentials.apiSecret.length - 4);
        console.log(`Using credentials - Key: ${maskedKey}, Secret: ${maskedSecret}`);

        // Use OAuth 2.0 client credentials flow
        console.log('Initiating OAuth 2.0 client credentials flow');
        const tokenResponse = await axios({
            method: 'post',
            url: 'https://oauth.fatsecret.com/connect/token',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            auth: {
                username: credentials.apiKey,
                password: credentials.apiSecret
            },
            data: 'grant_type=client_credentials'
        });

        console.log('Successfully received OAuth token');

        // Log token details without exposing the full token
        const token = tokenResponse.data.access_token;
        const maskedToken = token.substring(0, 10) + '...' + token.substring(token.length - 10);
        console.log(`Token received (masked): ${maskedToken}`);
        console.log(`Token expires in: ${tokenResponse.data.expires_in} seconds`);

        return token;
    } catch (error) {
        console.error('Error getting access token:', error);

        // Enhanced error logging
        if (error.response) {
            // The request was made and the server responded with a status code outside of 2xx
            console.error('OAuth Error Response:', {
                status: error.response.status,
                statusText: error.response.statusText,
                data: error.response.data,
                headers: error.response.headers
            });

            if (error.response.status === 401) {
                throw new Error('Authentication failed: Invalid client credentials. Check your FatSecret API key and secret.');
            }

            if (error.response.status === 400 && error.response.data?.error === 'invalid_scope') {
                throw new Error('Invalid scope requested. The scope "basic" should be used for FatSecret API.');
            }
        } else if (error.request) {
            console.error('No response received from OAuth server:', error.request);
            throw new Error('No response received from OAuth server. Check network connectivity.');
        }

        throw new Error(`Failed to authenticate with FatSecret API: ${error.message}`);
    }
}

/**
 * Helper function to parse food item from API response
 * Matches the parsing logic in the Flutter app's CloudFunctionsService
 */
function parseFoodItem(data) {
    try {
        // Extract food ID
        const id = data.food_id?.toString() || '';

        // Extract food name
        const name = data.food_name?.toString() || 'Unknown Food';

        // Extract brand name if available
        const brand = data.brand_name?.toString() || '';

        // Extract food type or category
        const category = data.food_type?.toString() || 'Uncategorized';

        // Extract image URLs if available
        let imageUrl = null;
        if (data.food_images) {
            // Try to get standard image first
            if (data.food_images.standard) {
                imageUrl = data.food_images.standard;
            }
            // Fall back to thumbnail
            else if (data.food_images.thumbnail) {
                imageUrl = data.food_images.thumbnail;
            }
        }
        // Try to get single food_image if the detailed structure isn't available
        else if (data.food_image) {
            imageUrl = data.food_image;
        }

        // Initialize nutrition values
        let servingSize = '100 g';  // Default value
        let calories = 0;
        let protein = 0;
        let fat = 0;
        let carbs = 0;
        let description = '';

        // Try to parse nutrition info from food_description if available
        if (data.food_description) {
            description = data.food_description;

            // Parse "Per X" serving size - handle various formats like "Per 100g", "Per 1 cup", "Per 16 pieces"
            const servingSizeMatch = description.match(/Per\s+([\d.]+\s*[a-zA-Z]+|[\d.]+\s*\w+\s+\w+)/i);
            if (servingSizeMatch) {
                servingSize = servingSizeMatch[1];
            }

            // Parse nutrition values from description with improved regex patterns
            // Handle values like "65kcal", "0.27g", "17.00g", etc.
            const caloriesMatch = description.match(/Calories:\s*([\d.]+)\s*(?:kcal)?/i);
            const fatMatch = description.match(/Fat:\s*([\d.]+)\s*(?:g)?/i);
            const carbsMatch = description.match(/Carbs:\s*([\d.]+)\s*(?:g)?/i);
            const proteinMatch = description.match(/Protein:\s*([\d.]+)\s*(?:g)?/i);

            if (caloriesMatch) calories = parseFloat(caloriesMatch[1]) || 0;
            if (fatMatch) fat = parseFloat(fatMatch[1]) || 0;
            if (carbsMatch) carbs = parseFloat(carbsMatch[1]) || 0;
            if (proteinMatch) protein = parseFloat(proteinMatch[1]) || 0;
        }

        // If servings data is available, it takes precedence over description parsing
        if (data.servings && data.servings.serving) {
            const serving = Array.isArray(data.servings.serving)
                ? data.servings.serving[0]  // Take first serving if array
                : data.servings.serving;    // Use single serving object

            // Parse serving size
            if (serving.metric_serving_amount && serving.metric_serving_unit) {
                servingSize = `${serving.metric_serving_amount} ${serving.metric_serving_unit}`;
            } else if (serving.serving_description) {
                // First try to extract from description with improved pattern to handle "1 cup", "16 pieces", etc.
                const desc = serving.serving_description;
                const match = desc.match(/^([\d.]+)\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)*)/);
                if (match) {
                    servingSize = `${match[1]} ${match[2]}`;
                }
            } else if (serving.number_of_units && serving.measurement_description) {
                // Some APIs provide number_of_units and measurement_description separately
                servingSize = `${serving.number_of_units} ${serving.measurement_description}`;
            }

            // Parse nutrients - these override any values from description
            if (serving.calories !== undefined) calories = parseFloat(serving.calories) || 0;
            if (serving.protein !== undefined) protein = parseFloat(serving.protein) || 0;
            if (serving.fat !== undefined) fat = parseFloat(serving.fat) || 0;
            if (serving.carbohydrate !== undefined) carbs = parseFloat(serving.carbohydrate) || 0;
        }

        // If food URL is available, include it
        const url = data.food_url || '';

        return {
            id,
            userId: '',  // This will be set by the client
            name,
            description,
            brand,
            servingSize,
            calories,
            protein,
            fat,
            carbs,
            category,
            isCustom: false,
            source: 'FatSecret API',
            url,
            imageUrl
        };
    } catch (error) {
        console.error('Error parsing food item:', error, 'data:', JSON.stringify(data));
        return {
            id: data.food_id?.toString() || '',
            userId: '',
            name: data.food_name?.toString() || 'Error parsing food',
            description: data.food_description?.toString() || '',
            brand: data.brand_name?.toString() || '',
            servingSize: '100 g',
            calories: 0,
            protein: 0,
            fat: 0,
            carbs: 0,
            category: data.food_type?.toString() || 'Uncategorized',
            isCustom: false,
            source: 'FatSecret API',
            imageUrl: null
        };
    }
}

// Helper function to recursively convert an object's keys to strings
// This is crucial for proper typing in Dart/Flutter
function deepStringifyKeys(obj) {
    if (obj === null || typeof obj !== 'object') {
        return obj;
    }

    // Handle arrays
    if (Array.isArray(obj)) {
        return obj.map(item => deepStringifyKeys(item));
    }

    // Handle objects - create a new object with string keys
    const newObj = {};
    Object.keys(obj).forEach(key => {
        // Process the value recursively
        newObj[String(key)] = deepStringifyKeys(obj[key]);
    });

    return newObj;
}

/**
 * Helper function to normalize various FatSecret API response formats
 * into a consistent structure expected by the client
 */
function normalizeSearchResponse(responseData, originalQuery) {
    console.log('Normalizing search response');

    // Extract foods data or default to empty array
    let foodsList = [];
    if (responseData && responseData.foods && responseData.foods.food) {
        const foodsData = responseData.foods.food;
        foodsList = Array.isArray(foodsData) ? foodsData : [foodsData];
        console.log(`Found ${foodsList.length} food items in API response`);
    } else {
        console.log('No foods found in API response');
    }

    // Convert food items to properly structured objects with string keys
    // This ensures compatibility with the Flutter code's type expectations
    const processedFoods = foodsList.map(food => {
        // First parse the food item (for logging purposes)
        const parsedItem = parseFoodItem(food);
        console.log(`Parsed food: ${parsedItem.name}, calories: ${parsedItem.calories}`);

        // Now deeply convert all keys to strings recursively
        return deepStringifyKeys(food);
    });

    console.log(`Processed ${processedFoods.length} food items`);

    // Extract metadata with proper type conversion (FatSecret sometimes returns numbers as strings)
    let maxResults = 0;
    let totalResults = 0;
    let pageNumber = 1;
    let searchExpression = originalQuery;

    if (responseData.foods) {
        if (responseData.foods.max_results !== undefined) {
            maxResults = parseInt(responseData.foods.max_results) || processedFoods.length;
        }

        if (responseData.foods.total_results !== undefined) {
            totalResults = parseInt(responseData.foods.total_results) || processedFoods.length;
        }

        if (responseData.foods.page_number !== undefined) {
            pageNumber = parseInt(responseData.foods.page_number) || 1;
        }

        if (responseData.foods.search_expression) {
            searchExpression = responseData.foods.search_expression;
        }
    }

    // If metadata is missing or conversion failed, use sensible defaults
    if (maxResults <= 0) maxResults = processedFoods.length;
    if (totalResults <= 0) totalResults = processedFoods.length > 0 ? processedFoods.length : 0;

    // Return with explicitly typed properties to ensure Flutter compatibility
    // Create a new object with explicit string keys for the root object
    return deepStringifyKeys({
        foods: {
            food: processedFoods,
            max_results: maxResults,
            total_results: totalResults,
            page_number: pageNumber,
            search_expression: searchExpression
        }
    });
}

/**
 * Callable function to get food by ID from FatSecret API
 */
exports.getFoodById = onCall({
    maxInstances: 10
}, async (request) => {
    console.log(`Get food request received: ${JSON.stringify(request.data)}`);

    // Ensure user is authenticated
    if (!request.auth) {
        throw new Error('Unauthenticated');
    }

    try {
        const { foodId } = request.data;

        if (!foodId) {
            throw new Error('Food ID is required');
        }

        console.log(`Getting food with ID: ${foodId}`);

        // Get access token
        const token = await getAccessToken();
        if (!token) {
            console.error('Failed to obtain OAuth token');
            throw new Error('Failed to authenticate with FatSecret API');
        }

        console.log('OAuth token obtained successfully, calling FatSecret API');

        // Call FatSecret API
        const response = await axios.get(BASE_URL, {
            params: {
                method: 'food.get.v4',
                format: 'json',
                food_id: foodId
            },
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        console.log('FatSecret API response received');
        console.log(`Full API response: ${JSON.stringify(response.data)}`);

        // Check if food was found
        if (!response.data.food) {
            console.log('No food found in API response');
            return null;
        }

        // Parse the food item using parseFoodItem for logging purposes
        const parsedFood = parseFoodItem(response.data.food);
        console.log(`Successfully parsed food item: ${parsedFood.name}`);

        // Deep convert all keys to strings recursively for Flutter compatibility
        return deepStringifyKeys(response.data.food);

    } catch (error) {
        console.error('Error details:', error);
        if (error.response) {
            console.error('API Error Response:', {
                status: error.response.status,
                statusText: error.response.statusText,
                data: error.response.data,
                headers: error.response.headers
            });
        }
        throw new Error(`Failed to get food by ID: ${error.message}`);
    }
});

/**
 * Callable function to search foods by barcode
 */
exports.searchFoodsByBarcode = onCall({
    maxInstances: 10
}, async (request) => {
    console.log(`Barcode search request received: ${JSON.stringify(request.data)}`);

    // Ensure user is authenticated
    if (!request.auth) {
        throw new Error('Unauthenticated');
    }

    try {
        const { barcode } = request.data;

        if (!barcode || barcode.trim() === '') {
            console.log('No barcode provided, returning empty response');
            return {
                foods: {
                    food: [],
                    max_results: 0,
                    total_results: 0,
                    page_number: 1,
                    search_expression: ''
                }
            };
        }

        console.log(`Searching for foods with barcode: ${barcode}`);

        // Get access token
        const token = await getAccessToken();
        if (!token) {
            console.error('Failed to obtain OAuth token');
            throw new Error('Failed to authenticate with FatSecret API');
        }

        console.log('OAuth token obtained successfully, calling FatSecret API');

        // Call FatSecret API using food.find_id_for_barcode endpoint
        const response = await axios.get(BASE_URL, {
            params: {
                method: 'food.find_id_for_barcode',
                format: 'json',
                barcode: barcode
            },
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        console.log('FatSecret API barcode response received');
        console.log(`Full API response: ${JSON.stringify(response.data)}`);

        // Check if we got a valid food_id from the barcode search
        if (response.data.food_id) {
            // Extract the food ID correctly based on the response format
            // The API returns either { food_id: "123" } or { food_id: { value: "123" }}
            const foodId = typeof response.data.food_id === 'object' ?
                response.data.food_id.value :
                response.data.food_id;

            console.log(`Found food ID ${foodId} for barcode ${barcode}, now fetching full details`);

            // Now fetch the complete food details using the ID
            const foodResponse = await axios.get(BASE_URL, {
                params: {
                    method: 'food.get.v4',
                    format: 'json',
                    food_id: foodId
                },
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            console.log(`Food details retrieved for ID ${foodId}`);
            console.log(`Food data: ${JSON.stringify(foodResponse.data)}`);

            // Create a search-like response structure with the single food item
            const foodData = foodResponse.data.food;

            // Add barcode to the food data
            if (foodData) {
                foodData.barcode = barcode;
            }

            // Return the food data directly instead of wrapping it in a search response
            console.log(`Returning food details directly for ID ${foodId}`);
            return deepStringifyKeys({
                food: foodData  // This is what the client is expecting for detailed food data
            });
        }

        // If the specific barcode endpoint failed or didn't return a food_id,
        // fallback to a regular search with the barcode as search term
        console.log('No direct match found for barcode, falling back to regular search');
        const searchResponse = await axios.get(BASE_URL, {
            params: {
                method: 'foods.search.v3',
                format: 'json',
                search_expression: barcode,
                max_results: 5 // Get a few results for a barcode search
            },
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        console.log('Fallback search response received');

        // Process the search response
        const normalizedResponse = normalizeSearchResponse(searchResponse.data, barcode);

        // Add barcode to all food items
        if (normalizedResponse.foods && normalizedResponse.foods.food) {
            let foodList = normalizedResponse.foods.food;
            if (!Array.isArray(foodList)) {
                foodList = [foodList];
            }

            foodList.forEach(food => {
                if (food) {
                    food.barcode = barcode;
                }
            });
        }

        return normalizedResponse;

    } catch (error) {
        console.error('Error details:', error);
        if (error.response) {
            console.error('API Error Response:', {
                status: error.response.status,
                statusText: error.response.statusText,
                data: error.response.data,
                headers: error.response.headers
            });
        }

        // Create a more informative error message
        let errorMessage = 'Failed to search foods by barcode';

        if (error.response && error.response.data && error.response.data.error) {
            errorMessage += `: ${error.response.data.error.message || error.response.data.error}`;
        } else if (error.message) {
            errorMessage += `: ${error.message}`;
        }

        throw new Error(errorMessage);
    }
});

/**
 * Callable function to search foods using FatSecret API v3
 * This implementation includes support for allergens, images, and dietary preferences
 */
exports.searchFoodsV3 = onCall({
    maxInstances: 10
}, async (request) => {
    console.log(`Search v3 request received: ${JSON.stringify(request.data)}`);

    // Ensure user is authenticated
    if (!request.auth) {
        throw new Error('Unauthenticated');
    }

    try {
        const {
            query,
            maxResults = 20,
            pageNumber = 0,
            includeFoodImages = false,
            includeFoodAttributes = false,
            includeSubCategories = false,
            flagDefaultServing = true,
            region = null,
            language = null
        } = request.data;

        if (!query || query.trim() === '') {
            console.log('No query provided, returning empty response');
            return deepStringifyKeys({
                foods: {
                    food: [],
                    max_results: 0,
                    total_results: 0,
                    page_number: 0,
                    search_expression: ''
                }
            });
        }

        // Ensure query is not too short (less than 3 chars) - use a reliable search term if so
        const processedQuery = query.trim();
        const effectiveQuery = processedQuery.length < 3 ? 'apple' : processedQuery;

        console.log(`Searching foods with v3 API: "${effectiveQuery}", max results: ${maxResults}, page: ${pageNumber}`);
        console.log(`Additional options: includeImages=${includeFoodImages}, includeAttributes=${includeFoodAttributes}`);

        // Get access token
        const token = await getAccessToken();
        if (!token) {
            console.error('Failed to obtain OAuth token');
            throw new Error('Failed to authenticate with FatSecret API');
        }

        console.log('OAuth token obtained successfully, calling FatSecret API v3');

        // Build parameters for the API call
        const params = {
            method: 'foods.search.v3',
            format: 'json',
            search_expression: effectiveQuery,
            max_results: Math.min(maxResults, 50), // Cap at 50 as per API docs
            page_number: pageNumber,
            flag_default_serving: flagDefaultServing
        };

        // Add optional parameters if specified
        if (includeFoodImages) {
            params.include_food_images = true;
        }

        if (includeFoodAttributes) {
            params.include_food_attributes = true;
        }

        if (includeSubCategories) {
            params.include_sub_categories = true;
        }

        // Add region and language if provided
        if (region) {
            params.region = region;
            if (language) {
                params.language = language;
            }
        }

        // Log the full API request parameters
        console.log(`API Request Parameters: ${JSON.stringify(params)}`);

        // Call FatSecret API
        const response = await axios.get(BASE_URL, {
            params,
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        console.log('FatSecret API v3 response received');
        console.log(`Response status: ${response.status}`);

        // Log the raw response for debugging (using safe stringify)
        console.log(`Raw API response: ${safeJsonStringify(response.data)}`);

        // Sometimes the API returns an empty object or null
        if (!response.data ||
            (Object.keys(response.data).length === 0) ||
            !response.data.foods ||
            !response.data.foods.food) {
            console.log('Received empty response from API, trying again with v1 endpoint');

            // Try again with v1 endpoint (foods.search instead of foods.search.v3)
            const fallbackResponse = await axios.get(BASE_URL, {
                params: {
                    method: 'foods.search',
                    format: 'json',
                    search_expression: effectiveQuery,
                    max_results: Math.min(maxResults, 50)
                },
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            console.log('Fallback API response received');
            console.log(`Fallback response status: ${fallbackResponse.status}`);
            console.log(`Fallback raw API response: ${safeJsonStringify(fallbackResponse.data)}`);

            // Use fallback response if available
            if (fallbackResponse.data &&
                fallbackResponse.data.foods &&
                fallbackResponse.data.foods.food) {
                console.log('Using fallback response data');
                const normalizedResponse = normalizeSearchResponse(fallbackResponse.data, effectiveQuery);

                // Add metadata to indicate this is from fallback
                normalizedResponse.request_metadata = {
                    api_version: 'v1',
                    fallback: true,
                    original_query: query
                };

                return normalizedResponse;
            }

            // If still empty, return empty normalized response
            return deepStringifyKeys({
                foods: {
                    food: [],
                    max_results: 0,
                    total_results: 0,
                    page_number: 0,
                    search_expression: effectiveQuery
                },
                request_metadata: {
                    api_version: 'none',
                    fallback: true,
                    error: 'No results found from any API endpoint',
                    original_query: query
                }
            });
        }

        // Process response with extended information
        const normalizedResponse = normalizeSearchResponse(response.data, effectiveQuery);

        // Add any additional metadata about the request to the response
        normalizedResponse.request_metadata = {
            api_version: 'v3',
            included_images: includeFoodImages,
            included_attributes: includeFoodAttributes,
            included_sub_categories: includeSubCategories,
            region: region,
            language: language,
            original_query: query
        };

        return normalizedResponse;
    } catch (error) {
        console.error('Error details:', error);
        if (error.response) {
            console.error('API Error Response:', {
                status: error.response.status,
                statusText: error.response.statusText,
                data: safeJsonStringify(error.response.data),
                headers: error.response.headers
            });
        }

        // Create a more informative error message
        let errorMessage = 'Failed to search foods with v3 API';

        if (error.response && error.response.data && error.response.data.error) {
            errorMessage += `: ${error.response.data.error.message || error.response.data.error}`;
        } else if (error.message) {
            errorMessage += `: ${error.message}`;
        }

        // Return an empty response with error info rather than throwing an error
        return deepStringifyKeys({
            foods: {
                food: [],
                max_results: 0,
                total_results: 0,
                page_number: 0,
                search_expression: request.data?.query || ''
            },
            request_metadata: {
                api_version: 'error',
                error: errorMessage
            }
        });
    }
});

/**
 * HTTP endpoint for searching foods with v3 API
 * This provides a RESTful interface for the same functionality as searchFoodsV3
 */
exports.searchFoodsV3Http = onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    // Handle preflight OPTIONS request
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }

    // Accept both GET and POST requests
    if (req.method !== 'GET' && req.method !== 'POST') {
        console.log(`Received unsupported ${req.method} request to searchFoodsV3Http`);
        res.status(400).json(deepStringifyKeys({
            error: 'Please send a GET or POST request',
            foods: {
                food: [],
                max_results: 0,
                total_results: 0,
                page_number: 0,
                search_expression: ''
            }
        }));
        return;
    }

    try {
        // Get parameters from either query string (GET) or request body (POST)
        const params = req.method === 'GET' ? req.query : req.body;

        const query = params.query || '';
        const maxResults = parseInt(params.maxResults || '20', 10);
        const pageNumber = parseInt(params.pageNumber || '0', 10);
        const includeFoodImages = params.includeFoodImages === 'true' || params.includeFoodImages === true;
        const includeFoodAttributes = params.includeFoodAttributes === 'true' || params.includeFoodAttributes === true;
        const includeSubCategories = params.includeSubCategories === 'true' || params.includeSubCategories === true;
        const flagDefaultServing = params.flagDefaultServing !== 'false' && params.flagDefaultServing !== false;
        const region = params.region || null;
        const language = params.language || null;

        if (!query || query.trim() === '') {
            console.log('No query provided to searchFoodsV3Http, returning empty response');
            res.status(200).json(deepStringifyKeys({
                foods: {
                    food: [],
                    max_results: 0,
                    total_results: 0,
                    page_number: 0,
                    search_expression: ''
                }
            }));
            return;
        }

        // Ensure query is not too short (less than 3 chars) - use a reliable search term if so
        const processedQuery = query.trim();
        const effectiveQuery = processedQuery.length < 3 ? 'apple' : processedQuery;

        console.log(`HTTP v3 endpoint received search request: ${effectiveQuery}`);

        // Get access token
        const token = await getAccessToken();
        if (!token) {
            console.error('Failed to obtain OAuth token');
            res.status(500).json(deepStringifyKeys({
                error: 'Failed to authenticate with FatSecret API',
                foods: {
                    food: [],
                    max_results: 0,
                    total_results: 0,
                    page_number: 0,
                    search_expression: effectiveQuery
                }
            }));
            return;
        }

        // Try a simple test search first to verify the API is working
        try {
            console.log('Trying simple HTTP test search');
            const testResponse = await axios.get(BASE_URL, {
                params: {
                    method: 'foods.search',
                    format: 'json',
                    search_expression: 'apple',
                    max_results: 5
                },
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            console.log(`HTTP test search response status: ${testResponse.status}`);
            console.log(`HTTP test search has results: ${!!(testResponse.data?.foods?.food)}`);
        } catch (testError) {
            console.log(`HTTP test search failed: ${testError.message}`);
        }

        // Build parameters for the API call
        const apiParams = {
            method: 'foods.search.v3',
            format: 'json',
            search_expression: effectiveQuery,
            max_results: Math.min(maxResults, 50), // Cap at 50 as per API docs
            page_number: pageNumber,
            flag_default_serving: flagDefaultServing
        };

        // Add optional parameters if specified
        if (includeFoodImages) {
            apiParams.include_food_images = true;
        }

        if (includeFoodAttributes) {
            apiParams.include_food_attributes = true;
        }

        if (includeSubCategories) {
            apiParams.include_sub_categories = true;
        }

        // Add region and language if provided
        if (region) {
            apiParams.region = region;
            if (language) {
                apiParams.language = language;
            }
        }

        // Log the request parameters
        console.log(`HTTP API Request Parameters: ${JSON.stringify(apiParams)}`);

        // Call FatSecret API
        const response = await axios.get(BASE_URL, {
            params: apiParams,
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        // Log API response status
        console.log(`FatSecret API v3 response status: ${response.status}`);
        console.log(`HTTP raw API response: ${safeJsonStringify(response.data)}`);

        // Check if the response contains valid data
        if (!response.data ||
            (Object.keys(response.data).length === 0) ||
            !response.data.foods ||
            !response.data.foods.food) {
            console.log('HTTP endpoint received empty response, trying fallback v1 endpoint');

            // Try the v1 endpoint as fallback
            const fallbackResponse = await axios.get(BASE_URL, {
                params: {
                    method: 'foods.search',
                    format: 'json',
                    search_expression: effectiveQuery,
                    max_results: Math.min(maxResults, 50)
                },
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            console.log('HTTP fallback response received');
            console.log(`HTTP fallback status: ${fallbackResponse.status}`);

            // Use fallback response if available
            if (fallbackResponse.data &&
                fallbackResponse.data.foods &&
                fallbackResponse.data.foods.food) {
                console.log('Using HTTP fallback response data');
                const normalizedResponse = normalizeSearchResponse(fallbackResponse.data, effectiveQuery);

                // Add metadata
                normalizedResponse.request_metadata = {
                    api_version: 'v1',
                    fallback: true,
                    original_query: query
                };

                res.status(200).json(normalizedResponse);
                return;
            }

            // If still no data, return empty response
            res.status(200).json(deepStringifyKeys({
                foods: {
                    food: [],
                    max_results: 0,
                    total_results: 0,
                    page_number: 0,
                    search_expression: effectiveQuery
                },
                request_metadata: {
                    api_version: 'none',
                    fallback: true,
                    error: 'No results found from any API endpoint',
                    original_query: query
                }
            }));
            return;
        }

        // Process response with normalizeSearchResponse function
        const normalizedResponse = normalizeSearchResponse(response.data, effectiveQuery);

        // Add request metadata
        normalizedResponse.request_metadata = {
            api_version: 'v3',
            included_images: includeFoodImages,
            included_attributes: includeFoodAttributes,
            included_sub_categories: includeSubCategories,
            region: region,
            language: language,
            original_query: query
        };

        console.log(`Normalized ${normalizedResponse.foods.food.length} food items with v3 API`);

        // Send response back to client
        res.status(200).json(normalizedResponse);
    } catch (error) {
        console.error('Error in searchFoodsV3Http:', error);

        let statusCode = 200; // Return 200 even on error, with error info in the body
        let errorMessage = 'Internal server error';

        if (error.response) {
            // Handle API response errors
            console.error('HTTP API error response:', error.response.status, safeJsonStringify(error.response.data));
            statusCode = 200; // Still return 200 to client
            errorMessage = `API error: ${error.response.status}`;
            if (error.response.data?.error?.message) {
                errorMessage += ` - ${error.response.data.error.message}`;
            }
        } else if (error.message) {
            errorMessage = error.message;
        }

        res.status(statusCode).json(deepStringifyKeys({
            foods: {
                food: [],
                max_results: 0,
                total_results: 0,
                page_number: 0,
                search_expression: req.method === 'GET' ? req.query?.query || '' : req.body?.query || ''
            },
            request_metadata: {
                api_version: 'error',
                error: errorMessage
            }
        }));
    }
});

/**
 * Admin-only function to set up FatSecret API credentials
 * This is a one-time setup function that should be called by an admin
 */
exports.setupFatSecretCredentials = onCall({
    maxInstances: 1
}, async (request) => {
    // Ensure user is authenticated
    if (!request.auth) {
        throw new Error('Unauthenticated');
    }

    try {
        // Get user's admin status
        const userDoc = await admin.firestore()
            .collection('users')
            .doc(request.auth.uid)
            .get();

        if (!userDoc.exists || !userDoc.data().isAdmin) {
            throw new Error('Unauthorized. Admin access required.');
        }

        const { apiKey, apiSecret } = request.data;

        if (!apiKey || !apiSecret) {
            throw new Error('API key and API secret are required');
        }

        console.log('Attempting to verify credentials before saving');

        // Test the credentials with a simple API call
        try {
            // Create basic auth credentials
            const auth = Buffer.from(`${apiKey}:${apiSecret}`).toString('base64');

            // Get an OAuth token to verify credentials
            const tokenResponse = await axios({
                method: 'post',
                url: 'https://oauth.fatsecret.com/connect/token',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'Authorization': `Basic ${auth}`
                },
                data: 'grant_type=client_credentials&scope=basic'
            });

            if (!tokenResponse.data.access_token) {
                throw new Error('Failed to obtain access token with provided credentials');
            }

            // Try a simple search to verify API access
            const token = tokenResponse.data.access_token;
            const testResponse = await axios.get(BASE_URL, {
                params: {
                    method: 'foods.search',
                    format: 'json',
                    search_expression: 'apple',
                    max_results: 1
                },
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            // Log the response for debugging
            console.log(`Test API call response: ${JSON.stringify(testResponse.data)}`);

            // Verify that we can access the foods
            if (!testResponse.data.foods) {
                throw new Error('API credentials work but the response format is unexpected');
            }

            console.log('Credentials verified successfully');
        } catch (error) {
            console.error('Credential verification failed:', error);
            if (error.response) {
                console.error('API Error Response:', {
                    status: error.response.status,
                    statusText: error.response.statusText,
                    data: error.response.data
                });

                if (error.response.status === 401) {
                    throw new Error('Invalid API credentials. Authentication failed.');
                }
            }

            throw new Error(`API credentials verification failed: ${error.message}`);
        }

        // Store credentials in Firestore
        await admin.firestore()
            .collection('app_config')
            .doc('fatsecret_credentials')
            .set({
                fatsecret_api_key: apiKey,
                fatsecret_api_secret: apiSecret,
                updated_at: admin.firestore.FieldValue.serverTimestamp(),
                updated_by: request.auth.uid
            });

        return {
            success: true,
            message: 'FatSecret credentials set and verified successfully',
            testPassed: true
        };
    } catch (error) {
        console.error('Error setting FatSecret credentials:', error);
        throw new Error(`Failed to set credentials: ${error.message}`);
    }
});

/**
 * Admin-only function to set up FatSecret API credentials in Remote Config
 */
exports.setupRemoteConfigApiKeys = onCall({
    maxInstances: 1
}, async (request) => {
    // Ensure user is authenticated
    if (!request.auth) {
        throw new Error('Unauthenticated');
    }

    try {
        // Get user's admin status
        const userDoc = await admin.firestore()
            .collection('users')
            .doc(request.auth.uid)
            .get();

        if (!userDoc.exists || !userDoc.data().isAdmin) {
            throw new Error('Unauthorized. Admin access required.');
        }

        const { apiKey, apiSecret } = request.data;

        if (!apiKey || !apiSecret) {
            throw new Error('API key and API secret are required');
        }

        // Get the current Remote Config template
        const remoteConfig = admin.remoteConfig();
        const template = await remoteConfig.getTemplate();

        // Update the parameters
        template.parameters['fatsecret_api_key'] = {
            defaultValue: {
                value: apiKey
            },
            description: 'FatSecret API Key',
            valueType: 'STRING'
        };

        template.parameters['fatsecret_api_secret'] = {
            defaultValue: {
                value: apiSecret
            },
            description: 'FatSecret API Secret',
            valueType: 'STRING'
        };

        // Publish the template
        await remoteConfig.publishTemplate(template);

        return { success: true, message: 'FatSecret credentials set in Remote Config successfully' };
    } catch (error) {
        console.error('Error updating Remote Config:', error);
        throw new Error(`Failed to set Remote Config parameters: ${error.message}`);
    }
});
