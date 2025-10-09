import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/planned_expense.dart';
import 'expense_service.dart';
import 'auth_service.dart';

class PlannedExpenseService {
  static const String _plannedExpensesKeyPrefix = 'planned_expenses_';

  // Get user-specific storage key
  static Future<String> _getUserPlannedExpensesKey() async {
    final currentUser = await AuthService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('No user logged in');
    }
    return '$_plannedExpensesKeyPrefix${currentUser.id}';
  }

  // Get all planned expenses
  static Future<List<PlannedExpense>> getAllPlannedExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPlannedExpensesKey = await _getUserPlannedExpensesKey();
      final expensesJson = prefs.getString(userPlannedExpensesKey);
      
      if (expensesJson == null) {
        return [];
      }

      final List<dynamic> expensesList = json.decode(expensesJson);
      final expenses = expensesList.map((expenseJson) => PlannedExpense.fromJson(expenseJson)).toList();
      return expenses;
    } catch (e) {
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
      final expenses = await getAllPlannedExpenses();
      
      final newExpense = PlannedExpense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        category: category,
        cost: cost,
        startDate: startDate,
        endDate: endDate,
        totalBudget: totalBudget,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: items,
        categories: categories.isNotEmpty ? categories : [category],
        notes: notes,
      );

      expenses.add(newExpense);
      await _savePlannedExpenses(expenses);

      return {
        'success': true,
        'message': 'Planned expense created successfully',
        'expense': newExpense,
      };
    } catch (e) {
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
      final expenses = await getAllPlannedExpenses();
      final index = expenses.indexWhere((expense) => expense.id == id);
      
      if (index == -1) {
        return {
          'success': false,
          'message': 'Planned expense not found',
        };
      }

      final updatedExpense = expenses[index].copyWith(
        name: name,
        category: category,
        cost: cost,
        startDate: startDate,
        endDate: endDate,
        totalBudget: totalBudget,
        updatedAt: DateTime.now(),
        items: items,
        categories: categories.isNotEmpty ? categories : expenses[index].categories,
        notes: notes,
      );

      expenses[index] = updatedExpense;
      await _savePlannedExpenses(expenses);

      return {
        'success': true,
        'message': 'Planned expense updated successfully',
        'expense': updatedExpense,
      };
    } catch (e) {
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
      final expenses = await getAllPlannedExpenses();
      final index = expenses.indexWhere((expense) => expense.id == plannedExpenseId);
      if (index == -1) {
        return {'success': false, 'message': 'Planned expense not found'};
      }

      final pe = expenses[index];
      final items = pe.items.map((it) {
        if (it.id == itemId) {
          return it.copyWith(isPurchased: isPurchased, purchasedAt: isPurchased ? DateTime.now() : null);
        }
        return it;
      }).toList();

      final updated = pe.copyWith(items: items, updatedAt: DateTime.now());
      expenses[index] = updated;
      await _savePlannedExpenses(expenses);

      // If purchased, also add to actual expenses for charts
      if (isPurchased) {
        final item = items.firstWhere((i) => i.id == itemId);
        await ExpenseService.createExpense(
          name: item.name,
          amount: item.cost,
          category: item.category.isNotEmpty ? item.category : pe.category,
          categoryIcon: Icons.checklist,
          date: DateTime.now(),
          description: 'Purchased from plan: ${pe.name}',
        );
      }

      return {'success': true, 'message': 'Item updated successfully'};
    } catch (e) {
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
      final expenses = await getAllPlannedExpenses();
      final index = expenses.indexWhere((expense) => expense.id == plannedExpenseId);
      if (index == -1) {
        return {'success': false, 'message': 'Planned expense not found'};
      }

      final pe = expenses[index];
      final newItem = PlannedExpenseItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        cost: cost,
        category: category,
      );
      final updated = pe.copyWith(items: [...pe.items, newItem], updatedAt: DateTime.now());
      expenses[index] = updated;
      await _savePlannedExpenses(expenses);
      return {'success': true, 'message': 'Item added', 'item': newItem};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add item: ${e.toString()}'};
    }
  }

  // Delete planned expense
  static Future<Map<String, dynamic>> deletePlannedExpense(String id) async {
    try {
      final expenses = await getAllPlannedExpenses();
      final index = expenses.indexWhere((expense) => expense.id == id);
      
      if (index == -1) {
        return {
          'success': false,
          'message': 'Planned expense not found',
        };
      }

      expenses.removeAt(index);
      await _savePlannedExpenses(expenses);

      return {
        'success': true,
        'message': 'Planned expense deleted successfully',
      };
    } catch (e) {
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

  // Save planned expenses to storage
  static Future<void> _savePlannedExpenses(List<PlannedExpense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final userPlannedExpensesKey = await _getUserPlannedExpensesKey();
    final expensesJson = json.encode(expenses.map((expense) => expense.toJson()).toList());
    await prefs.setString(userPlannedExpensesKey, expensesJson);
  }
}




