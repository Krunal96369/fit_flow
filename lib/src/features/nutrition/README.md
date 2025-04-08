# Nutrition Tracking Feature

## Overview

This feature allows users to track their daily nutrition intake, including calories, macronutrients, and water consumption. It provides a dashboard with real-time updates and progress visualization.

## Directory Structure

- **application/**: Controllers and business logic

  - `nutrition_controller.dart`: Core nutrition tracking operations
  - `food_controller.dart`: Food search and management

- **domain/**: Business models and repository interfaces

  - `nutrition_entry.dart`: Food entry model
  - `nutrition_goals.dart`: User nutritional targets
  - `nutrition_summary.dart`: Daily aggregate data
  - `macro_distribution.dart`: Macronutrient distribution
  - `nutrition_repository.dart`: Data access interface
  - `food_item.dart`: Food database item model
  - `food_repository.dart`: Food data access interface

- **presentation/**: UI components

  - `nutrition_dashboard_screen.dart`: Main dashboard
  - `add_nutrition_entry_screen.dart`: Food entry form
  - `food_search_screen.dart`: Food search interface
  - `nutrition_screen.dart`: Overview screen
  - `widgets/`: Reusable UI components

- **nutrition_router.dart**: Feature routing configuration

## Key Features

- Track food intake with detailed nutritional information
- Monitor daily progress toward nutritional goals
- Track water consumption
- Search food database
- View historical data with date navigation
- Offline support with local caching

## Data Flow

1. User adds entries via the entry form or food search
2. Entries are saved to Firestore and local cache
3. Daily summaries are calculated and cached
4. Dashboard subscribes to real-time streams for updates
5. UI displays progress toward goals

## Design Patterns

- **Clean Architecture**: Separation of domain, application, and presentation layers
- **Repository Pattern**: Data access abstraction
- **Provider Pattern**: Dependency injection with Riverpod
- **MVVM-inspired**: Controllers separate business logic from UI

## Integration Points

- **Authentication**: Uses the auth feature for user identification
- **Firestore**: Stores nutrition data in user subcollections
- **Hive**: Local caching for offline functionality

## For Detailed Documentation

See `/docs/nutrition_feature.md` for comprehensive documentation.
