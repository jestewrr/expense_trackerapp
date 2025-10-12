import 'package:flutter/material.dart';
import 'planned_expense_service.dart';
import 'firebase_auth_service.dart';
import '../viewsetexpense.dart';

class NotificationService {
  // Get current user ID from Firebase Auth
  static Future<String?> _getCurrentUserId() async {
    final firebaseAuth = FirebaseAuthService();
    return firebaseAuth.currentUserId;
  }


  // Check for overdue planned expenses (past end date)
  static Future<List<Map<String, dynamic>>> checkOverduePlannedExpenses() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return [];
      }

      final now = DateTime.now();
      
      // Get all planned expenses
      final plannedExpenses = await PlannedExpenseService.getAllPlannedExpenses();
      
      // Filter expenses that are overdue (past end date)
      final overdueExpenses = plannedExpenses.where((expense) {
        final endDate = expense.endDate;
        return endDate.isBefore(now);
      }).toList();

      // Convert to notification format
      return overdueExpenses.map((expense) => {
        'id': expense.id,
        'name': expense.name,
        'category': expense.category,
        'endDate': expense.endDate,
        'isCompleted': expense.items.every((item) => item.isPurchased),
        'completedItems': expense.items.where((item) => item.isPurchased).length,
        'totalItems': expense.items.length,
        'remainingAmount': expense.remainingAmount,
        'totalAmount': expense.cost,
        'daysOverdue': now.difference(expense.endDate).inDays,
      }).toList();
    } catch (e) {
      print('Error checking overdue planned expenses: $e');
      return [];
    }
  }


  // Show notification dialog for overdue expenses
  static Future<void> showOverdueExpensesNotification(BuildContext context) async {
    final overdueExpenses = await checkOverduePlannedExpenses();
    
    if (overdueExpenses.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 // Header
                 Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     gradient: LinearGradient(
                       colors: [Colors.red[400]!, Colors.red[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                               'Overdue Planned Expenses',
                               style: TextStyle(
                                 fontWeight: FontWeight.bold,
                                 fontSize: 16,
                                 color: Colors.white,
                               ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You have ${overdueExpenses.length} expense${overdueExpenses.length > 1 ? 's' : ''} that are overdue',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                 // Content
                 Flexible(
                   child: SingleChildScrollView(
                     padding: const EdgeInsets.all(16),
                     child: Column(
                       children: [
                         // Warning message
                         Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(
                             color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.warning_outlined,
                                  color: Colors.red[700],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'These expenses are overdue. Please take action to complete or update them.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red[700],
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Expense items
                        ...overdueExpenses.map<Widget>((expense) {
                           return Container(
                             margin: const EdgeInsets.only(bottom: 8),
                             child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ViewSetExpensePage(
                                      plannedExpenseId: expense['id'],
                                    ),
                                  ),
                                );
                              },
                               child: Container(
                                 padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.shopping_cart,
                                        color: Colors.red[600],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            expense['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '₱${expense['remainingAmount'].toStringAsFixed(2)} remaining',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Colors.red[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${expense['completedItems']}/${expense['totalItems']} items completed • ${expense['daysOverdue']} days overdue',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.grey[500],
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                // Action buttons
                Container(
                   padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                             padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Dismiss',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            if (overdueExpenses.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ViewSetExpensePage(
                                    plannedExpenseId: overdueExpenses.first['id'],
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                             padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Check and show all notifications
  static Future<void> checkAndShowNotifications(BuildContext context) async {
    // Only show overdue expenses notifications
    await showOverdueExpensesNotification(context);
  }
}
