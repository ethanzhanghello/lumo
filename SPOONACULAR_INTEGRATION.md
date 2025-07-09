# Spoonacular API Integration Guide

## Overview
This guide explains how to integrate the Spoonacular Food API into your Lumo app for enhanced recipe functionality.

## Setup Instructions

### 1. Get a Spoonacular API Key
1. Visit [Spoonacular Food API](https://spoonacular.com/food-api)
2. Sign up for a free account
3. Get your API key from the dashboard
4. Free tier includes 150 requests per day

### 2. Configure API Key
1. Create a file named `spoonacular.key` in your project root
2. Add your API key to the file (no quotes, just the key)
3. The file is already added to `.gitignore` for security

Example `spoonacular.key`:
```
abc123def456ghi789jkl012mno345pqr678stu901vwx234yz
```

### 3. Add Files to Xcode Project
1. Open your Xcode project
2. Right-click on the Lumo folder in the project navigator
3. Select "Add Files to 'Lumo'"
4. Add these files:
   - `SpoonacularService.swift`
   - `SpoonacularRecipeView.swift`

### 4. Build and Test
1. Clean build folder (Cmd+Shift+K)
2. Build the project (Cmd+B)
3. Test the integration

## Features Implemented

### Core API Integration
- **Recipe Search**: Search recipes by query, diet, cuisine, and time
- **Recipe Details**: Get full recipe information with ingredients and instructions
- **Random Recipes**: Get random recipe suggestions
- **Similar Recipes**: Find recipes similar to a given recipe
- **Recipe by Ingredients**: Find recipes using available ingredients
- **Nutrition Analysis**: Analyze nutritional content of ingredients

### UI Components
- **SpoonacularRecipeView**: Main view for browsing Spoonacular recipes
- **Recipe Cards**: Beautiful cards displaying recipe information
- **Filter System**: Filter by diet, cuisine, and cooking time
- **Recipe Details**: Full recipe view with ingredients and instructions
- **Integration with Meal Planning**: Use Spoonacular recipes in meal planning

### Integration Points
- **RecipeDatabase**: Extended with Spoonacular search methods
- **MealPlanningView**: Integrated Spoonacular recipe picker
- **APIKeyManager**: Centralized API key management

## API Endpoints Used

### Search Endpoints
- `GET /recipes/complexSearch` - Advanced recipe search
- `GET /recipes/random` - Random recipe suggestions
- `GET /recipes/{id}/information` - Full recipe details
- `GET /recipes/{id}/similar` - Similar recipes

### Analysis Endpoints
- `POST /recipes/analyze` - Nutrition analysis
- `GET /recipes/findByIngredients` - Recipes by ingredients

## Usage Examples

### Search Recipes
```swift
let recipes = await SpoonacularService.shared.searchRecipes(
    query: "pasta",
    diet: "vegetarian",
    cuisine: "italian",
    maxReadyTime: 30
)
```

### Get Random Recipes
```swift
let recipes = await SpoonacularService.shared.getRandomRecipes(
    tags: ["breakfast", "healthy"],
    number: 10
)
```

### Find Recipes by Ingredients
```swift
let recipes = await SpoonacularService.shared.findRecipesByIngredients(
    ingredients: ["chicken", "rice", "vegetables"]
)
```

### Analyze Nutrition
```swift
let nutrition = await SpoonacularService.shared.analyzeNutrition(
    ingredients: ["2 cups rice", "1 lb chicken breast", "2 cups broccoli"]
)
```

## Error Handling
The service includes comprehensive error handling:
- API key validation
- Network error handling
- Response validation
- User-friendly error messages

## Rate Limiting
- Free tier: 150 requests per day
- Monitor usage in Spoonacular dashboard
- Implement caching for frequently accessed data

## Security Considerations
- API keys are stored locally and not committed to version control
- Use environment variables in production
- Implement proper error handling to avoid exposing sensitive information

## Troubleshooting

### Common Issues
1. **"API key not configured"**: Ensure `spoonacular.key` file exists and contains valid key
2. **"HTTP 401"**: Invalid API key - check your key in Spoonacular dashboard
3. **"HTTP 429"**: Rate limit exceeded - wait or upgrade plan
4. **Build errors**: Ensure all files are added to Xcode project

### Debug Tips
- Check console logs for API key loading messages
- Verify API key format (no quotes, no extra spaces)
- Test API key directly in Spoonacular dashboard
- Monitor network requests in Xcode debugger

## Future Enhancements
- Recipe caching for offline access
- Advanced filtering options
- Recipe recommendations based on user preferences
- Integration with shopping list generation
- Recipe scaling and meal planning optimization

## Support
- [Spoonacular API Documentation](https://spoonacular.com/food-api/docs)
- [Spoonacular API Console](https://spoonacular.com/food-api/console)
- [Spoonacular Support](https://spoonacular.com/support) 