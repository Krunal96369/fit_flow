# Nutrition Tracking Feature Documentation

## Overview

The nutrition tracking feature allows users to log their food intake, track macronutrient consumption, monitor water intake, and view summaries of their nutritional data. This feature helps users maintain awareness of their dietary habits and make informed nutritional choices.

## Feature Components

### 1. Domain Models

- **NutritionEntry**: Represents a single food entry in the user's log
- **NutritionGoals**: Stores user-defined nutritional targets
- **DailyNutritionSummary**: Aggregates nutritional data for a specific day
- **MacroDistribution**: Represents the distribution of macronutrients (protein, carbs, fat)
- **FoodItem**: Represents a food item that can be searched for and added to the log

### 2. User Interface Components

- **Nutrition Dashboard**: Main screen showing daily summary and logged meals
- **Add Nutrition Entry**: Screen for manually adding food entries
- **Food Search**: Interface for searching food database and selecting items
- **Nutrition Goals**: Settings screen for configuring nutritional targets

### 3. Application Logic

- **NutritionController**: Manages nutrition-related operations
- **FoodController**: Handles food search and management functionality

### 4. Data Layer

- **NutritionRepository**: Interface for data access operations
- **FoodRepository**: Interface for food-related data operations

## Data Structure (Firestore)

```
users/                                      <-- Root collection
  {userId}/                                 <-- Document ID = User's Authentication ID
    |
    |-- lastActive: timestamp               <-- Field: Timestamp of last activity
    |-- hasNutritionData: boolean           <-- Field: Flag indicating if user has nutrition data
    |
    |-- nutrition_entries/                  <-- Subcollection for individual food logs
    |   |
    |   +-- {entryId}/                      <-- Document ID = Unique ID for the entry
    |       |-- id: string                  <-- Field: Same as Document ID
    |       |-- userId: string              <-- Field: User's ID
    |       |-- name: string                <-- Field: Name of the food item
    |       |-- consumedAt: timestamp       <-- Field: Exact time of consumption
    |       |-- calories: number            <-- Field: Calories
    |       |-- protein: number             <-- Field: Protein (g)
    |       |-- carbs: number               <-- Field: Carbs (g)
    |       |-- fat: number                 <-- Field: Fat (g)
    |       |-- servingSize: string         <-- Field: Description of one serving
    |       |-- servings: number            <-- Field: Number of servings consumed
    |       |-- notes: string?              <-- Field: Optional user notes
    |       |-- mealType: string            <-- Field: e.g., "Breakfast", "Lunch"
    |       |-- tags: array<string>         <-- Field: List of tags
    |       +-- dateKey: string             <-- Field: "YYYY-MM-DD" format for queries
    |
    |-- nutrition_summaries/                <-- Subcollection for daily summaries
    |   |
    |   +-- {userId-YYYY-MM-DD}/            <-- Document ID = Composite ID
    |       |-- date: timestamp             <-- Field: Start of the day summary
    |       |-- totalCalories: number       <-- Field: Sum of calories for the day
    |       |-- totalProtein: number        <-- Field: Sum of protein
    |       |-- totalCarbs: number          <-- Field: Sum of carbs
    |       |-- totalFat: number            <-- Field: Sum of fat
    |       |-- calorieGoal: number         <-- Field: User's goal
    |       |-- proteinGoal: number         <-- Field: User's goal
    |       |-- carbsGoal: number           <-- Field: User's goal
    |       |-- fatGoal: number             <-- Field: User's goal
    |       |-- waterIntake: number         <-- Field: Total water (ml)
    |       |-- waterGoal: number           <-- Field: User's water goal
    |       +-- entryCount: number          <-- Field: Number of entries logged
    |
    +-- nutrition_goals/                    <-- Subcollection for user's goals
        |
        +-- {userId}/                       <-- Document ID = User's Authentication ID
            |-- userId: string              <-- Field: User's ID
            |-- calorieGoal: number
            |-- proteinGoal: number
            |-- carbsGoal: number
            |-- fatGoal: number
            |-- waterGoal: number
            |-- lastUpdated: timestamp      <-- Field: When goals were last modified
            +-- macroDistribution: map      <-- Field: Nested map for macro percentages
                |-- proteinPercentage: number
                |-- carbsPercentage: number
                +-- fatPercentage: number
```

## User Flows

### Adding a Nutrition Entry

1. **Direct Entry**: User navigates to the dashboard and taps the "+" button to open the Add Nutrition Entry screen. They manually enter food details including name, serving size, calories, and macronutrients.

2. **Food Search**: User navigates to the Food Search screen by tapping "Search Food Database" on the Add Entry screen. They can search for foods and select an item, which will pre-fill the entry form.

### Viewing Nutrition Data

1. The Nutrition Dashboard displays:

   - Date selector for viewing different days
   - Daily summary showing progress toward nutritional goals
   - Water intake tracker with quick-add buttons
   - List of meals logged for the selected day

2. Users can swipe between days or use the date selector to view historical data.

### Managing Entries

1. Users can delete entries by swiping left on any entry in the list.
2. Each entry shows basic nutritional information and the time it was consumed.

### Tracking Water Intake

1. The water tracker shows current water intake compared to the daily goal.
2. Quick-add buttons (200ml, 330ml, 500ml) allow for easy logging of water consumption.

## Offline Support

The feature includes offline functionality:

- Entries are cached locally using Hive
- Changes made offline are synchronized when connectivity is restored
- Daily summaries are recalculated after synchronization

## Data Synchronization

- Real-time updates are implemented using Firestore streams
- The dashboard subscribes to:
  - `dailyNutritionSummaryStreamProvider` for nutrition summary updates
  - `dailyNutritionEntriesStreamProvider` for entry list updates

## Technical Implementation Details

### Key Date Handling

- Dates are normalized to midnight for comparison (using `DateTime(year, month, day)`)
- A `dateKey` field in the format "YYYY-MM-DD" is used for efficient querying
- Leading zeros are added to single-digit months and days to ensure consistent formatting

### Error Handling

- Repository methods catch and handle errors gracefully
- Default values are provided in case of data retrieval failures
- Error states are displayed to the user when necessary

### Dependencies

- **Firestore**: Primary data storage
- **Hive**: Local caching for offline functionality
- **Riverpod**: State management and dependency injection
- **GoRouter**: Navigation

## Usage Examples

### Tracking a Meal

1. Open the Nutrition Dashboard
2. Tap the "+" button
3. Enter food details or search for a food item
4. Set the meal type and serving size
5. Save the entry
6. The dashboard updates with the new nutritional totals

### Setting Nutrition Goals

1. Navigate to Nutrition Goals from the dashboard
2. Set daily targets for calories, protein, carbs, fat, and water
3. Save the goals
4. The dashboard will display progress bars based on these goals

### Logging Water Intake

1. On the dashboard, locate the water tracker
2. Tap one of the quick-add buttons (200ml, 330ml, 500ml)
3. The water progress bar updates in real-time

## Maintenance and Extension

### Adding New Functionality

To extend the feature:

1. Add new domain models to `lib/src/features/nutrition/domain/`
2. Implement repository methods in the appropriate repository
3. Add controller methods in `nutrition_controller.dart`
4. Create or update UI components as needed

### Performance Considerations

- Use `dateKey` for efficient querying rather than timestamp ranges
- Use streams for real-time updates rather than repeated polling
- Cache frequently accessed data locally

## Troubleshooting

### Common Issues

1. **Missing Data**: Ensure the user is authenticated and check logs for repository errors
2. **Incorrect Totals**: Verify that entries have the correct `dateKey` format
3. **Offline Sync Issues**: Check connectivity status and debug `syncOfflineData()` method

### Debugging Tools

- Repository methods include detailed debug logging
- Stream providers emit descriptive error messages
- UI components display user-friendly error states
