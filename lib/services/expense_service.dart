import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class ExpenseService {
  static const String _expensesKey = 'expenses';

  // Get all expenses
  static Future<List<Expense>> getAllExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expensesJson = prefs.getString(_expensesKey);
      
      if (expensesJson == null) {
        return [];
      }

      final List<dynamic> expensesList = json.decode(expensesJson);
      return expensesList.map((expenseJson) => Expense.fromJson(expenseJson)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get expenses by category
  static Future<List<Expense>> getExpensesByCategory(String category) async {
    try {
      final allExpenses = await getAllExpenses();
      return allExpenses.where((expense) => expense.category == category).toList();
    } catch (e) {
      return [];
    }
  }

  // Get expense by ID
  static Future<Expense?> getExpenseById(String id) async {
    try {
      final expenses = await getAllExpenses();
      return expenses.firstWhere(
        (expense) => expense.id == id,
        orElse: () => throw Exception('Expense not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Create new expense
  static Future<Map<String, dynamic>> createExpense({
    required String name,
    required double amount,
    required String category,
    required IconData categoryIcon,
    required DateTime date,
    String? description,
  }) async {
    try {
      final expenses = await getAllExpenses();
      
      final newExpense = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        amount: amount,
        category: category,
        categoryIcon: categoryIcon,
        date: date,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expenses.add(newExpense);
      await _saveExpenses(expenses);

      return {
        'success': true,
        'message': 'Expense created successfully',
        'expense': newExpense,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create expense: ${e.toString()}',
      };
    }
  }

  // Update expense
  static Future<Map<String, dynamic>> updateExpense({
    required String id,
    required String name,
    required double amount,
    required String category,
    required IconData categoryIcon,
    required DateTime date,
    String? description,
  }) async {
    try {
      final expenses = await getAllExpenses();
      final index = expenses.indexWhere((expense) => expense.id == id);
      
      if (index == -1) {
        return {
          'success': false,
          'message': 'Expense not found',
        };
      }

      final updatedExpense = expenses[index].copyWith(
        name: name,
        amount: amount,
        category: category,
        categoryIcon: categoryIcon,
        date: date,
        description: description,
        updatedAt: DateTime.now(),
      );

      expenses[index] = updatedExpense;
      await _saveExpenses(expenses);

      return {
        'success': true,
        'message': 'Expense updated successfully',
        'expense': updatedExpense,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update expense: ${e.toString()}',
      };
    }
  }

  // Delete expense
  static Future<Map<String, dynamic>> deleteExpense(String id) async {
    try {
      final expenses = await getAllExpenses();
      final index = expenses.indexWhere((expense) => expense.id == id);
      
      if (index == -1) {
        return {
          'success': false,
          'message': 'Expense not found',
        };
      }

      expenses.removeAt(index);
      await _saveExpenses(expenses);

      return {
        'success': true,
        'message': 'Expense deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete expense: ${e.toString()}',
      };
    }
  }

  // Get total amount for a category
  static Future<double> getTotalAmountForCategory(String category) async {
    try {
      final List<Expense> expenses = await getExpensesByCategory(category);
      return expenses.fold<double>(0.0, (double sum, Expense expense) => sum + expense.amount);
    } catch (e) {
      return 0.0;
    }
  }

  // Get total amount for all expenses
  static Future<double> getTotalAmount() async {
    try {
      final List<Expense> expenses = await getAllExpenses();
      return expenses.fold<double>(0.0, (double sum, Expense expense) => sum + expense.amount);
    } catch (e) {
      return 0.0;
    }
  }

  // Get expenses by date range
  static Future<List<Expense>> getExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final expenses = await getAllExpenses();
      return expenses.where((expense) {
        return expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
               expense.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get today's expenses
  static Future<List<Expense>> getTodaysExpenses() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      return await getExpensesByDateRange(
        startDate: startOfDay,
        endDate: endOfDay,
      );
    } catch (e) {
      return [];
    }
  }

  // Get expenses grouped by category
  static Future<Map<String, List<Expense>>> getExpensesGroupedByCategory() async {
    try {
      final expenses = await getAllExpenses();
      final Map<String, List<Expense>> grouped = {};
      
      for (final expense in expenses) {
        if (grouped[expense.category] == null) {
          grouped[expense.category] = [];
        }
        grouped[expense.category]!.add(expense);
      }
      
      return grouped;
    } catch (e) {
      return {};
    }
  }

  // Save expenses to storage
  static Future<void> _saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = json.encode(expenses.map((expense) => expense.toJson()).toList());
    await prefs.setString(_expensesKey, expensesJson);
  }
}
