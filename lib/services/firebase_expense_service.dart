import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';

class FirebaseExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add expense to Firestore
  Future<Map<String, dynamic>> addExpense({
    required String userId,
    required String name,
    required String category,
    required double amount,
    required String description,
    required DateTime date,
    required IconData categoryIcon,
  }) async {
    try {
      final expenseData = {
        'userId': userId,
        'name': name,
        'category': category,
        'amount': amount,
        'description': description,
        'date': Timestamp.fromDate(date),
        'categoryIcon': categoryIcon.codePoint,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final DocumentReference docRef = await _firestore
          .collection('expenses')
          .add(expenseData);

      return {
        'success': true,
        'message': 'Expense added successfully',
        'expenseId': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add expense: ${e.toString()}',
      };
    }
  }

  // Get expenses for a user
  Future<List<Expense>> getExpenses(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Expense(
          id: doc.id,
          name: data['name'] ?? '',
          category: data['category'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          description: data['description'] ?? '',
          date: (data['date'] as Timestamp).toDate(),
          categoryIcon: IconData(data['categoryIcon'] ?? Icons.receipt, fontFamily: 'MaterialIcons'),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Update expense
  Future<Map<String, dynamic>> updateExpense({
    required String expenseId,
    required String name,
    required String category,
    required double amount,
    required String description,
    required DateTime date,
    required IconData categoryIcon,
  }) async {
    try {
      await _firestore.collection('expenses').doc(expenseId).update({
        'name': name,
        'category': category,
        'amount': amount,
        'description': description,
        'date': Timestamp.fromDate(date),
        'categoryIcon': categoryIcon.codePoint,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Expense updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update expense: ${e.toString()}',
      };
    }
  }

  // Delete expense
  Future<Map<String, dynamic>> deleteExpense(String expenseId) async {
    try {
      await _firestore.collection('expenses').doc(expenseId).delete();

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

  // Get expenses by category
  Future<List<Expense>> getExpensesByCategory(String userId, String category) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Expense(
          id: doc.id,
          name: data['name'] ?? '',
          category: data['category'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          description: data['description'] ?? '',
          date: (data['date'] as Timestamp).toDate(),
          categoryIcon: IconData(data['categoryIcon'] ?? Icons.receipt, fontFamily: 'MaterialIcons'),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get expenses by date range
  Future<List<Expense>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Expense(
          id: doc.id,
          name: data['name'] ?? '',
          category: data['category'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          description: data['description'] ?? '',
          date: (data['date'] as Timestamp).toDate(),
          categoryIcon: IconData(data['categoryIcon'] ?? Icons.receipt, fontFamily: 'MaterialIcons'),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get total expenses for a user
  Future<double> getTotalExpenses(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      return 0;
    }
  }

  // Stream expenses for real-time updates
  Stream<List<Expense>> getExpensesStream(String userId) {
    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Expense(
          id: doc.id,
          name: data['name'] ?? '',
          category: data['category'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          description: data['description'] ?? '',
          date: (data['date'] as Timestamp).toDate(),
          categoryIcon: IconData(data['categoryIcon'] ?? Icons.receipt, fontFamily: 'MaterialIcons'),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }
}
