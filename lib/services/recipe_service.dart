import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:recipe_app/models/recipe.dart';

class RecipeService {
  static const String mealDbBaseUrl = 'https://www.themealdb.com/api/json/v1/1';
  static const String tastyBaseUrl = 'https://tasty.p.rapidapi.com/recipes';
  static const String tastyApiKey = '7487190320mshbb4919af9aabfdcp18a451jsna491220a45eb';

  Future<List<Recipe>> searchRecipes(String query) async {
    List<Recipe> allRecipes = [];
    
    // Search TheMealDB
    final mealDbResponse = await http.get(
      Uri.parse('$mealDbBaseUrl/search.php?s=$query'),
    );

    if (mealDbResponse.statusCode == 200) {
      final data = json.decode(mealDbResponse.body);
      final meals = data['meals'] as List<dynamic>?;
      
      if (meals != null) {
        allRecipes.addAll(meals.map((json) => Recipe.fromMealDB(json)));
      }
    }

    // Search Tasty
    final tastyResponse = await http.get(
      Uri.parse('$tastyBaseUrl/list?from=0&size=5&q=$query'),
      headers: {
        'X-RapidAPI-Key': tastyApiKey,
        'X-RapidAPI-Host': 'tasty.p.rapidapi.com'
      },
    );

    if (tastyResponse.statusCode == 200) {
      final data = json.decode(tastyResponse.body);
      final results = data['results'] as List<dynamic>?;
      
      if (results != null) {
        for (var result in results) {
          final detailsResponse = await http.get(
            Uri.parse('$tastyBaseUrl/get-more-info?id=${result['id']}'),
            headers: {
              'X-RapidAPI-Key': tastyApiKey,
              'X-RapidAPI-Host': 'tasty.p.rapidapi.com'
            },
          );
          
          if (detailsResponse.statusCode == 200) {
            final detailsData = json.decode(detailsResponse.body);
            allRecipes.add(Recipe.fromTasty(detailsData));
          }
        }
      }
    }

    allRecipes.shuffle();
    return allRecipes;
  }

  Future<List<Recipe>> getPopularRecipes() async {
    List<Recipe> allRecipes = [];
    final random = Random();
    
    // Get recipes from TheMealDB
    final mealDbCategories = ['Chicken', 'Beef', 'Seafood', 'Pasta', 'Breakfast', 
                             'Vegetarian', 'Dessert', 'Pork'];
    final selectedCategories = List<String>.from(mealDbCategories)..shuffle();

    for (String category in selectedCategories.take(4)) {
      final response = await http.get(
        Uri.parse('$mealDbBaseUrl/filter.php?c=$category'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List<dynamic>?;
        
        if (meals != null && meals.isNotEmpty) {
          final shuffledMeals = List<dynamic>.from(meals)..shuffle(random);
          
          for (var meal in shuffledMeals.take(2)) {
            final detailsResponse = await http.get(
              Uri.parse('$mealDbBaseUrl/lookup.php?i=${meal['idMeal']}'),
            );
            
            if (detailsResponse.statusCode == 200) {
              final detailsData = json.decode(detailsResponse.body);
              final mealDetails = detailsData['meals'][0];
              allRecipes.add(Recipe.fromMealDB(mealDetails));
            }
          }
        }
      }
    }

    // Get recipes from Tasty
    final tastyTags = ['dinner', 'lunch', 'breakfast', 'dessert', 'snacks', 
                       'healthy', 'quick', 'vegetarian'];
    final selectedTags = List<String>.from(tastyTags)..shuffle();

    for (String tag in selectedTags.take(4)) {
      final response = await http.get(
        Uri.parse('$tastyBaseUrl/list?from=0&size=2&tags=$tag'),
        headers: {
          'X-RapidAPI-Key': tastyApiKey,
          'X-RapidAPI-Host': 'tasty.p.rapidapi.com'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>?;
        
        if (results != null) {
          for (var result in results) {
            final detailsResponse = await http.get(
              Uri.parse('$tastyBaseUrl/get-more-info?id=${result['id']}'),
              headers: {
                'X-RapidAPI-Key': tastyApiKey,
                'X-RapidAPI-Host': 'tasty.p.rapidapi.com'
              },
            );
            
            if (detailsResponse.statusCode == 200) {
              final detailsData = json.decode(detailsResponse.body);
              allRecipes.add(Recipe.fromTasty(detailsData));
            }
          }
        }
      }
    }

    allRecipes.shuffle(random);
    return allRecipes;
  }
} 