# FatSecret API Integration Setup

This document explains how to set up the FatSecret API credentials for your FitFlow application.

## Obtaining FatSecret API Credentials

1. Go to [FatSecret Platform](https://platform.fatsecret.com/api/)
2. Create a developer account if you don't have one
3. Register a new application
4. Once registered, you'll receive:
   - API Key (Consumer Key)
   - API Secret (Consumer Secret)

## Adding Credentials to Firebase Remote Config

The FitFlow app uses Firebase Remote Config to securely store API credentials. Follow these steps to add your credentials:

1. Log in to the [Firebase Console](https://console.firebase.google.com/)
2. Select your FitFlow project
3. Navigate to "Remote Config" in the left sidebar menu (under "Engagement")
4. Add the following parameters:

   | Parameter Name         | Parameter Type | Default Value   |
   | ---------------------- | -------------- | --------------- |
   | `fatsecret_api_key`    | String         | Your API Key    |
   | `fatsecret_api_secret` | String         | Your API Secret |

5. Save and publish your changes

## Testing the Integration

After adding the credentials to Firebase Remote Config:

1. Launch the FitFlow app
2. Navigate to the Nutrition section
3. Try searching for food items
4. If the search returns results, the API integration is working correctly

## Troubleshooting

If you encounter issues with the API integration:

1. Make sure the parameter names in Firebase Remote Config exactly match `fatsecret_api_key` and `fatsecret_api_secret`
2. Verify that the API credentials are correct and active
3. Check the app logs for any error messages related to the FatSecret API
4. Ensure the app has a working internet connection

## Security Considerations

- The API credentials are retrieved from Firebase Remote Config and not hardcoded in the app
- The credentials are cached locally for offline use, but are not stored in plain text
- API requests use OAuth 2.0 with temporary access tokens for enhanced security
