import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../services/firebase_auth_service.dart';

class ExpenseService {
  // Get current user ID from Firebase Auth
  static Future<String?> _getCurrentUserId() async {
    final firebaseAuth = FirebaseAuthService();
    return firebaseAuth.currentUserId;
  }

  // Get all expenses
  static Future<List<Expense>> getAllExpenses() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        print('No user logged in, returning empty expenses list');
        return [];
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      final expenses = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Expense.fromJson(data);
      }).toList();
      
      // Sort by date descending
      expenses.sort((a, b) => b.date.compareTo(a.date));
      
      return expenses;
    } catch (e) {
      print('Error getting expenses: $e');
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
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      final expenseData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'amount': amount,
        'category': category,
        'categoryIcon': categoryIcon.codePoint,
        'date': date.toIso8601String(),
        'description': description,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'userId': userId, // This is the key field that was missing!
      };

      // Add to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('expenses')
          .add(expenseData);

      // Create Expense object for return
      final newExpense = Expense.fromJson(expenseData);

      return {
        'success': true,
        'message': 'Expense created successfully',
        'expense': newExpense,
      };
    } catch (e) {
      print('Error creating expense: $e');
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
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      // Find the document by ID and userId
      final querySnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('id', isEqualTo: id)
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Expense not found',
        };
      }

      final doc = querySnapshot.docs.first;
      final updatedData = {
        'name': name,
        'amount': amount,
        'category': category,
        'categoryIcon': categoryIcon.codePoint,
        'date': date.toIso8601String(),
        'description': description,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await doc.reference.update(updatedData);

      final updatedExpense = Expense.fromJson({
        ...doc.data(),
        ...updatedData,
      });

      return {
        'success': true,
        'message': 'Expense updated successfully',
        'expense': updatedExpense,
      };
    } catch (e) {
      print('Error updating expense: $e');
      return {
        'success': false,
        'message': 'Failed to update expense: ${e.toString()}',
      };
    }
  }

  // Delete expense
  static Future<Map<String, dynamic>> deleteExpense(String id) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      // Find the document by ID and userId
      final querySnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('id', isEqualTo: id)
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Expense not found',
        };
      }

      // Delete the document
      await querySnapshot.docs.first.reference.delete();

      return {
        'success': true,
        'message': 'Expense deleted successfully',
      };
    } catch (e) {
      print('Error deleting expense: $e');
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

}
