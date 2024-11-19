import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/services/recipe_service.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/screens/add_recipe_screen.dart';
import 'package:recipe_app/screens/recipe_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  List<Recipe> _apiRecipes = [];
  bool _isLoading = false;
  bool _showPersonalRecipes = false;

  @override
  void initState() {
    super.initState();
    _loadPopularRecipes();
  }

  Future<void> _loadPopularRecipes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final recipes = await RecipeService().getPopularRecipes();
      setState(() {
        _apiRecipes = recipes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchRecipes(String query) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final recipes = await RecipeService().searchRecipes(query);
      setState(() {
        _apiRecipes = recipes;
        _showPersonalRecipes = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildRecipeList() {
    if (_showPersonalRecipes) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = snapshot.data?.docs ?? [];

          if (recipes.isEmpty) {
            return const Center(
              child: Text('No personal recipes found. Try adding some!'),
            );
          }

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(recipe['title']),
                  subtitle: Text('Ready in ${recipe['readyInMinutes']} minutes'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailsScreen(recipe: recipe),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      );
    } else {
      if (_apiRecipes.isEmpty) {
        return const Center(
          child: Text('Search for recipes above'),
        );
      }

      return ListView.builder(
        itemCount: _apiRecipes.length,
        itemBuilder: (context, index) {
          final recipe = _apiRecipes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: recipe.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        recipe.imageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  : null,
              title: Text(recipe.title),
              subtitle: Text('Ready in ${recipe.readyInMinutes} minutes'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Convert Recipe object to Map for RecipeDetailsScreen
                final recipeMap = {
                  'title': recipe.title,
                  'readyInMinutes': recipe.readyInMinutes,
                  'ingredients': recipe.ingredients,
                  'instructions': recipe.instructions,
                };
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailsScreen(recipe: recipeMap),
                  ),
                );
              },
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPopularRecipes,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddRecipeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search recipes',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _searchRecipes(_searchController.text),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Search Results'),
                      icon: Icon(Icons.search),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('My Recipes'),
                      icon: Icon(Icons.book),
                    ),
                  ],
                  selected: {_showPersonalRecipes},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _showPersonalRecipes = newSelection.first;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildRecipeList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 