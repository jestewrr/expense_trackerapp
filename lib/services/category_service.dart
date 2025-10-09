import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/expense_service.dart';
import '../services/auth_service.dart';

class CategoryService {
  static const String _categoriesKeyPrefix = 'user_categories_';

  // Get user-specific storage key
  static Future<String> _getUserCategoriesKey() async {
    final currentUser = await AuthService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('No user logged in');
    }
    return '$_categoriesKeyPrefix${currentUser.id}';
  }

  // Get all user-created categories
  static Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userCategoriesKey = await _getUserCategoriesKey();
      final categoriesJson = prefs.getString(userCategoriesKey);
      
      if (categoriesJson == null) {
        // If no categories exist, return empty list for new users
        return [];
      }

      final List<dynamic> categoriesList = json.decode(categoriesJson);
      return categoriesList.map((categoryJson) {
        final category = Map<String, dynamic>.from(categoryJson);
        // Ensure icon is properly formatted for IconData reconstruction
        if (category['icon'] != null) {
          category['icon'] = category['icon'] as int;
        }
        return category;
      }).toList();
    } catch (e) {
      // Return empty list instead of default categories
      return [];
    }
  }


  // Add a new category
  static Future<Map<String, dynamic>> addCategory({
    required String label,
    required IconData icon,
  }) async {
    try {
      final categories = await getAllCategories();
      
      // Check if category already exists
      if (categories.any((cat) => cat['label'] == label)) {
        return {
          'success': false,
          'message': 'Category already exists',
        };
      }

      final newCategory = {
        'icon': icon.codePoint,
        'iconFamily': icon.fontFamily ?? 'MaterialIcons',
        'label': label,
        'amount': 0.0,
      };

      categories.add(newCategory);
      await _saveCategories(categories);

      return {
        'success': true,
        'message': 'Category added successfully',
        'category': newCategory,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add category: ${e.toString()}',
      };
    }
  }

  // Update category amounts based on expenses
  static Future<void> updateCategoryAmounts() async {
    try {
      final categories = await getAllCategories();
      final expensesByCategory = await ExpenseService.getExpensesGroupedByCategory();
      
      for (int i = 0; i < categories.length; i++) {
        final categoryName = categories[i]['label'];
        final categoryExpenses = expensesByCategory[categoryName] ?? [];
        final totalAmount = categoryExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
        categories[i]['amount'] = totalAmount;
      }
      
      // Sort categories by amount (highest first)
      categories.sort((a, b) {
        final amountA = a['amount'] as double;
        final amountB = b['amount'] as double;
        return amountB.compareTo(amountA);
      });
      
      await _saveCategories(categories);
    } catch (e) {
      // Silently handle error - categories will still work with default amounts
    }
  }

  // Get category names only (for dropdowns)
  static Future<List<String>> getCategoryNames() async {
    try {
      final categories = await getAllCategories();
      return categories.map((cat) => cat['label'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  // Get category icon by name
  static Future<IconData> getCategoryIcon(String categoryName) async {
    try {
      final categories = await getAllCategories();
      final category = categories.firstWhere(
        (cat) => cat['label'] == categoryName,
        orElse: () => {
          'icon': Icons.category.codePoint,
          'iconFamily': 'MaterialIcons',
        },
      );
      return IconData(
        category['icon'] as int,
        fontFamily: category['iconFamily'] as String? ?? 'MaterialIcons',
      );
    } catch (e) {
      return Icons.category;
    }
  }

  // Save categories to storage
  static Future<void> _saveCategories(List<Map<String, dynamic>> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final userCategoriesKey = await _getUserCategoriesKey();
    final categoriesJson = json.encode(categories);
    await prefs.setString(userCategoriesKey, categoriesJson);
  }
}
