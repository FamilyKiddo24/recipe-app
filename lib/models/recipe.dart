class Recipe {
  final String id;
  final String title;
  final String? imageUrl;
  final List<String> ingredients;
  final List<String> instructions;
  final int readyInMinutes;

  Recipe({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.ingredients,
    required this.instructions,
    required this.readyInMinutes,
  });

  factory Recipe.fromMealDB(Map<String, dynamic> json) {
    // Extract ingredients and measurements
    List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      String? ingredient = json['strIngredient$i'];
      String? measure = json['strMeasure$i'];
      
      if (ingredient != null && 
          ingredient.trim().isNotEmpty && 
          measure != null && 
          measure.trim().isNotEmpty) {
        ingredients.add('$measure $ingredient');
      }
    }

    // Split instructions into steps
    List<String> instructions = (json['strInstructions'] as String)
        .split('.')
        .where((step) => step.trim().isNotEmpty)
        .map((step) => step.trim())
        .toList();

    return Recipe(
      id: json['idMeal'],
      title: json['strMeal'],
      imageUrl: json['strMealThumb'],
      ingredients: ingredients,
      instructions: instructions,
      readyInMinutes: 30,
    );
  }

  factory Recipe.fromTasty(Map<String, dynamic> json) {
    // Extract ingredients
    List<String> ingredients = [];
    if (json['sections'] != null) {
      for (var section in json['sections'] as List) {
        for (var component in section['components'] as List) {
          String ingredient = component['raw_text'] ?? '';
          if (ingredient.isNotEmpty) {
            ingredients.add(ingredient);
          }
        }
      }
    }

    // Extract instructions
    List<String> instructions = [];
    if (json['instructions'] != null) {
      instructions = (json['instructions'] as List)
          .map((instruction) => instruction['display_text'].toString())
          .where((text) => text.isNotEmpty)
          .toList();
    }

    // Calculate cooking time
    int prepTime = json['prep_time_minutes'] ?? 0;
    int cookTime = json['cook_time_minutes'] ?? 0;
    int totalTime = (prepTime + cookTime) > 0 ? (prepTime + cookTime) : 30;

    return Recipe(
      id: json['id'].toString(),
      title: json['name'],
      imageUrl: json['thumbnail_url'],
      ingredients: ingredients,
      instructions: instructions,
      readyInMinutes: totalTime,
    );
  }
} 