# Nutrition Feature UI Guide

## Nutrition Dashboard Screen

![Nutrition Dashboard](https://placeholder-for-dashboard-screenshot.png)

### Key Components

1. **Date Navigator**

   - Left/right arrows for day navigation
   - Current date display (shows "Today" for current date)
   - Tap to open date picker

2. **Daily Summary Card**

   - Displays total meals logged
   - Progress bars for calories, protein, carbs, and fat
   - Shows current amount vs. daily goal
   - Color-coded progress indicators (orange, green, red)

3. **Water Tracker**

   - Water intake progress bar
   - Current amount / daily goal display
   - Quick-add buttons (200ml, 330ml, 500ml)

4. **Meals List**

   - Chronological list of meals logged for selected day
   - Shows food name, nutrition info, and time consumed
   - Swipe left to delete entries
   - Empty state with guidance when no meals logged

5. **Add Entry Button (FAB)**
   - Floating action button to add new nutrition entries

## Add Nutrition Entry Screen

![Add Nutrition Entry](https://placeholder-for-add-entry-screenshot.png)

### Key Components

1. **Search Bar**

   - Button to navigate to food search screen

2. **Food Info Fields**

   - Food name input
   - Meal type dropdown (Breakfast, Lunch, Dinner, etc.)
   - Time picker

3. **Nutrition Info Fields**

   - Calories
   - Protein
   - Carbs
   - Fat
   - Serving size description
   - Number of servings

4. **Favorite Toggle**

   - Option to save food as favorite

5. **Save Button**
   - Validates and saves the entry
   - Returns to dashboard with updated data

## Food Search Screen

![Food Search](https://placeholder-for-food-search-screenshot.png)

### Key Components

1. **Search Bar**

   - Text input for food search
   - Barcode scanning button (when available)

2. **Search Results**

   - Scrollable list of matching food items
   - Shows name and basic nutrition info

3. **Recent & Favorites Tabs**

   - Access to recently used and favorite foods
   - Displayed when no active search

4. **Create Custom Food Button**
   - Option to create a custom food entry

## Usage Tips

- **Daily Navigation**: Use the date selector to review past days or plan future meals
- **Quick Water Logging**: Use the water tracker buttons for commonly used amounts
- **Efficient Entry**: Use the search function to quickly find foods in the database
- **Custom Foods**: Create and save custom foods for items you eat regularly
- **Meal Management**: Swipe to easily remove incorrect entries

## Responsive Design

The nutrition UI is designed to be responsive across different device sizes:

- **Mobile**: Optimized single-column layout
- **Tablet**: Enhanced with multi-column layouts where appropriate
- **Adaptive**: UI elements automatically adjust to screen width

## Accessibility Features

- Color-coded progress bars include text indicators
- Interactive elements have appropriate minimum touch targets
- Supports system font scaling
