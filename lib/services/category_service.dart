import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/expense_service.dart';
import '../services/firebase_auth_service.dart';

class CategoryService {
  // Get current user ID from Firebase Auth
  static Future<String?> _getCurrentUserId() async {
    final firebaseAuth = FirebaseAuthService();
    final userId = firebaseAuth.currentUserId;
    print('Firebase Auth Service - Current User ID: $userId'); // Debug log
    print('Firebase Auth Service - Is Signed In: ${firebaseAuth.isSignedIn}'); // Debug log
    return userId;
  }

  // Get all categories (default + user-created)
  static Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        print('No user logged in, returning empty categories list');
        return [];
      }

      List<Map<String, dynamic>> categories = [];

      // Get default categories (isDefault = true, userId = null)
      try {
        final defaultCategoriesQuery = await FirebaseFirestore.instance
            .collection('categories')
            .where('isDefault', isEqualTo: true)
            .get();

        // Add default categories
        for (var doc in defaultCategoriesQuery.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          categories.add(data);
        }
      } catch (e) {
        print('Error getting default categories: $e');
      }

      // Get user-created categories
      try {
        final userCategoriesQuery = await FirebaseFirestore.instance
            .collection('categories')
            .where('userId', isEqualTo: userId)
            .get();

        // Add user categories
        for (var doc in userCategoriesQuery.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          categories.add(data);
        }
      } catch (e) {
        print('Error getting user categories: $e');
      }

      return categories;
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }


  // Add a new category
  static Future<Map<String, dynamic>> addCategory({
    required String label,
    required IconData icon,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      print('Current user ID: $userId'); // Debug log
      
      if (userId == null) {
        print('No user ID found'); // Debug log
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      // Check if category already exists
      final existingCategories = await getAllCategories();
      if (existingCategories.any((cat) => cat['label'] == label)) {
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
        'userId': userId,
        'isDefault': false,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      };

      print('Creating category with data: $newCategory'); // Debug log

      // Add to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('categories')
          .add(newCategory);

      newCategory['id'] = docRef.id;
      print('Category created successfully with ID: ${docRef.id}'); // Debug log

      return {
        'success': true,
        'message': 'Category added successfully',
        'category': newCategory,
      };
    } catch (e) {
      print('Error adding category: $e'); // Debug log
      return {
        'success': false,
        'message': 'Failed to add category: ${e.toString()}',
      };
    }
  }

  // Update category amounts based on expenses
  static Future<void> updateCategoryAmounts() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      final categories = await getAllCategories();
      final expensesByCategory = await ExpenseService.getExpensesGroupedByCategory();
      
      for (var category in categories) {
        final categoryName = category['label'];
        final categoryExpenses = expensesByCategory[categoryName] ?? [];
        final totalAmount = categoryExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
        
        // Update the category amount in Firestore
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(category['id'])
            .update({'amount': totalAmount});
      }
    } catch (e) {
      print('Error updating category amounts: $e');
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
      final iconCodePoint = category['icon'] as int;
      return IconData(
        iconCodePoint,
        fontFamily: category['iconFamily'] as String? ?? 'MaterialIcons',
      );
    } catch (e) {
      return Icons.category;
    }
  }

  // Edit a category
  static Future<Map<String, dynamic>> editCategory({
    required String categoryId,
    required String label,
    required IconData icon,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      // Check if the category exists and belongs to the user
      final categoryDoc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .get();

      if (!categoryDoc.exists) {
        return {
          'success': false,
          'message': 'Category not found',
        };
      }

      final categoryData = categoryDoc.data()!;
      
      // Check if it's a default category (can't edit)
      if (categoryData['isDefault'] == true) {
        return {
          'success': false,
          'message': 'Cannot edit default categories',
        };
      }

      // Check if category belongs to current user
      if (categoryData['userId'] != userId) {
        return {
          'success': false,
          'message': 'You can only edit your own categories',
        };
      }

      // Check if new label already exists (excluding current category)
      final existingCategories = await getAllCategories();
      if (existingCategories.any((cat) => cat['label'] == label && cat['id'] != categoryId)) {
        return {
          'success': false,
          'message': 'Category name already exists',
        };
      }

      // Update the category
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .update({
        'label': label,
        'icon': icon.codePoint,
        'iconFamily': icon.fontFamily ?? 'MaterialIcons',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Category updated successfully',
      };
    } catch (e) {
      print('Error editing category: $e');
      return {
        'success': false,
        'message': 'Failed to edit category: ${e.toString()}',
      };
    }
  }

  // Delete a category
  static Future<Map<String, dynamic>> deleteCategory(String categoryId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      // Check if the category exists and belongs to the user
      final categoryDoc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .get();

      if (!categoryDoc.exists) {
        return {
          'success': false,
          'message': 'Category not found',
        };
      }

      final categoryData = categoryDoc.data()!;
      
      // Check if it's a default category (can't delete)
      if (categoryData['isDefault'] == true) {
        return {
          'success': false,
          'message': 'Cannot delete default categories',
        };
      }

      // Check if category belongs to current user
      if (categoryData['userId'] != userId) {
        return {
          'success': false,
          'message': 'You can only delete your own categories',
        };
      }

      // Check if category has associated expenses
      final categoryName = categoryData['label'];
      final expensesByCategory = await ExpenseService.getExpensesGroupedByCategory();
      final categoryExpenses = expensesByCategory[categoryName] ?? [];
      
      if (categoryExpenses.isNotEmpty) {
        return {
          'success': false,
          'message': 'Cannot delete category with existing expenses. Please delete or reassign expenses first.',
        };
      }

      // Delete the category
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .delete();

      return {
        'success': true,
        'message': 'Category deleted successfully',
      };
    } catch (e) {
      print('Error deleting category: $e');
      return {
        'success': false,
        'message': 'Failed to delete category: ${e.toString()}',
      };
    }
  }

}
