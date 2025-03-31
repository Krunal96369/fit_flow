# FitFlow

FitFlow is a comprehensive fitness tracking application that helps users track workouts, nutrition, and overall fitness progress.

## Features

- **Workout Tracking**: Create and track custom workouts
- **Nutrition Logging**: Log meals and track macronutrient intake
- **Progress Monitoring**: Monitor progress with visual charts and statistics

## Setup

### Requirements

- Flutter SDK (latest stable version)
- Firebase project
- FatSecret API credentials (for nutrition data)

### Installation

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase using FlutterFire CLI or manual setup
4. Set up the FatSecret API integration (see below)
5. Run the app with `flutter run`

### FatSecret API Integration

The app uses FatSecret API for nutrition data. To set up the integration:

1. Obtain API credentials from [FatSecret Platform](https://platform.fatsecret.com/api/)
2. Add the credentials to Firebase Remote Config:
   - Log in to Firebase Console
   - Navigate to Remote Config
   - Add parameters:
     - `fatsecret_api_key` - Your API key
     - `fatsecret_api_secret` - Your API secret
   - Publish changes

For detailed instructions, see [FATSECRET_API_SETUP.md](FATSECRET_API_SETUP.md).

## Architecture

FitFlow follows a clean architecture approach with:

- **Domain Layer**: Business logic and entities
- **Application Layer**: Use cases and controllers
- **Data Layer**: Repositories and data sources
- **Presentation Layer**: UI components and screens

State management is implemented using Riverpod, and data persistence is handled through Firebase with local caching using Hive for offline support.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
