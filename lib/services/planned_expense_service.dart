import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/planned_expense.dart';
import 'expense_service.dart';
import 'firebase_auth_service.dart';

class PlannedExpenseService {
  // Get current user ID from Firebase Auth
  static Future<String?> _getCurrentUserId() async {
    final firebaseAuth = FirebaseAuthService();
    return firebaseAuth.currentUserId;
  }

  // Get all planned expenses
  static Future<List<PlannedExpense>> getAllPlannedExpenses() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        print('No user logged in, returning empty planned expenses list');
        return [];
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('planned_expenses')
          .where('userId', isEqualTo: userId)
          .get();

      final expenses = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PlannedExpense.fromJson(data);
      }).toList();
      
      // Sort by start date descending
      expenses.sort((a, b) => b.startDate.compareTo(a.startDate));
      
      return expenses;
    } catch (e) {
      print('Error getting planned expenses: $e');
      return [];
    }
  }

  // Get planned expense by ID
  static Future<PlannedExpense?> getPlannedExpenseById(String id) async {
    try {
      final expenses = await getAllPlannedExpenses();
      return expenses.firstWhere(
        (expense) => expense.id == id,
        orElse: () => throw Exception('Planned expense not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Create new planned expense
  static Future<Map<String, dynamic>> createPlannedExpense({
    required String name,
    required String category,
    required double cost,
    required DateTime startDate,
    required DateTime endDate,
    required double totalBudget,
    String? notes,
    List<PlannedExpenseItem> items = const [],
    List<String> categories = const [],
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      final plannedExpenseData = {
        'name': name,
        'category': category,
        'cost': cost,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'totalBudget': totalBudget,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'categories': categories.isNotEmpty ? categories : [category],
        'notes': notes,
        'userId': userId, // This is the key field that was missing!
      };

      // Add to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('planned_expenses')
          .add(plannedExpenseData);

      // Create PlannedExpense object for return
      plannedExpenseData['id'] = docRef.id;
      final newExpense = PlannedExpense.fromJson(plannedExpenseData);

      return {
        'success': true,
        'message': 'Planned expense created successfully',
        'expense': newExpense,
      };
    } catch (e) {
      print('Error creating planned expense: $e');
      return {
        'success': false,
        'message': 'Failed to create planned expense: ${e.toString()}',
      };
    }
  }

  // Update planned expense
  static Future<Map<String, dynamic>> updatePlannedExpense({
    required String id,
    required String name,
    required String category,
    required double cost,
    required DateTime startDate,
    required DateTime endDate,
    required double totalBudget,
    String? notes,
    List<PlannedExpenseItem> items = const [],
    List<String> categories = const [],
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      final updateData = {
        'name': name,
        'category': category,
        'cost': cost,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'totalBudget': totalBudget,
        'updatedAt': DateTime.now().toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'categories': categories.isNotEmpty ? categories : [category],
        'notes': notes,
      };

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('planned_expenses')
          .doc(id)
          .update(updateData);

      // Get updated document
      final doc = await FirebaseFirestore.instance
          .collection('planned_expenses')
          .doc(id)
          .get();

      if (!doc.exists) {
        return {
          'success': false,
          'message': 'Planned expense not found',
        };
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      final updatedExpense = PlannedExpense.fromJson(data);

      return {
        'success': true,
        'message': 'Planned expense updated successfully',
        'expense': updatedExpense,
      };
    } catch (e) {
      print('Error updating planned expense: $e');
      return {
        'success': false,
        'message': 'Failed to update planned expense: ${e.toString()}',
      };
    }
  }

  // Toggle an item's purchased state, optionally record as real expense
  static Future<Map<String, dynamic>> toggleItemPurchased({
    required String plannedExpenseId,
    required String itemId,
    required bool isPurchased,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      // Get the planned expense
      final doc = await FirebaseFirestore.instance
          .collection('planned_expenses')
          .doc(plannedExpenseId)
          .get();

      if (!doc.exists) {
        return {'success': false, 'message': 'Planned expense not found'};
      }

      final data = doc.data()!;
      final items = (data['items'] as List).map((item) => PlannedExpenseItem.fromJson(item)).toList();
      
      // Update the specific item
      final updatedItems = items.map((it) {
        if (it.id == itemId) {
          return it.copyWith(isPurchased: isPurchased, purchasedAt: isPurchased ? DateTime.now() : null);
        }
        return it;
      }).toList();

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('planned_expenses')
          .doc(plannedExpenseId)
          .update({
        'items': updatedItems.map((item) => item.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // If purchased, also add to actual expenses for charts
      if (isPurchased) {
        final item = updatedItems.firstWhere((i) => i.id == itemId);
        await ExpenseService.createExpense(
          name: item.name,
          amount: item.cost,
          category: item.category.isNotEmpty ? item.category : data['category'],
          categoryIcon: Icons.checklist,
          date: DateTime.now(),
          description: 'Purchased from plan: ${data['name']}',
        );
      }

      return {'success': true, 'message': 'Item updated successfully'};
    } catch (e) {
      print('Error toggling item purchased: $e');
      return {'success': false, 'message': 'Failed to update item: ${e.toString()}'};
    }
  }

  // Add a new item to a planned expense
  static Future<Map<String, dynamic>> addItem({
    required String plannedExpenseId,
    required String name,
    required double cost,
    required String category,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      // Get the planned expense
      final doc = await FirebaseFirestore.instance
          .collection('planned_expenses')
          .doc(plannedExpenseId)
          .get();

      if (!doc.exists) {
        return {'success': false, 'message': 'Planned expense not found'};
      }

      final data = doc.data()!;
      final items = (data['items'] as List).map((item) => PlannedExpenseItem.fromJson(item)).toList();
      
      final newItem = PlannedExpenseItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        cost: cost,
        category: category,
      );

      // Add new item to the list
      items.add(newItem);

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('planned_expenses')
          .doc(plannedExpenseId)
          .update({
        'items': items.map((item) => item.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return {'success': true, 'message': 'Item added', 'item': newItem};
    } catch (e) {
      print('Error adding item: $e');
      return {'success': false, 'message': 'Failed to add item: ${e.toString()}'};
    }
  }

  // Delete planned expense
  static Future<Map<String, dynamic>> deletePlannedExpense(String id) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('planned_expenses')
          .doc(id)
          .delete();

      return {
        'success': true,
        'message': 'Planned expense deleted successfully',
      };
    } catch (e) {
      print('Error deleting planned expense: $e');
      return {
        'success': false,
        'message': 'Failed to delete planned expense: ${e.toString()}',
      };
    }
  }

  // Get planned expenses by date range
  static Future<List<PlannedExpense>> getPlannedExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final expenses = await getAllPlannedExpenses();
      return expenses.where((expense) {
        return expense.startDate.isBefore(endDate) && expense.endDate.isAfter(startDate);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get total budget for a date range
  static Future<double> getTotalBudgetForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final expenses = await getPlannedExpensesByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      
      if (expenses.isEmpty) return 0.0;
      return expenses.first.totalBudget; // Assuming all expenses in same range have same budget
    } catch (e) {
      return 0.0;
    }
  }

  // Get expenses grouped by category for a specific planned expense
  static Future<List<Map<String, dynamic>>> getExpensesGroupedByCategory(String plannedExpenseId) async {
    try {
      final expense = await getPlannedExpenseById(plannedExpenseId);
      if (expense == null) return [];

      // For now, return mock data. In a real app, you'd have separate expense items
      return [
        {
          'icon': Icons.lunch_dining,
          'category': 'Food',
          'total': expense.cost * 0.4, // 40% of total cost
          'items': [
            {'name': 'Desserts', 'cost': expense.cost * 0.1},
            {'name': 'Bread', 'cost': expense.cost * 0.05},
            {'name': 'Rice', 'cost': expense.cost * 0.15},
            {'name': 'Canned Goods', 'cost': expense.cost * 0.1},
          ],
        },
        {
          'icon': Icons.shopping_bag,
          'category': 'Shopping',
          'total': expense.cost * 0.3, // 30% of total cost
          'items': [
            {'name': 'Clothes', 'cost': expense.cost * 0.2},
            {'name': 'Skin Care', 'cost': expense.cost * 0.1},
          ],
        },
        {
          'icon': Icons.directions_car,
          'category': 'Transport',
          'total': expense.cost * 0.2, // 20% of total cost
          'items': [
            {'name': 'Gas', 'cost': expense.cost * 0.15},
            {'name': 'Parking', 'cost': expense.cost * 0.05},
          ],
        },
        {
          'icon': Icons.home,
          'category': 'Utilities',
          'total': expense.cost * 0.1, // 10% of total cost
          'items': [
            {'name': 'Electricity', 'cost': expense.cost * 0.06},
            {'name': 'Water', 'cost': expense.cost * 0.04},
          ],
        },
      ];
    } catch (e) {
      return [];
    }
  }

}




