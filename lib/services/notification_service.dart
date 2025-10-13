import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'planned_expense_service.dart';
import 'firebase_auth_service.dart';
import 'expense_service.dart';
import '../viewsetexpense.dart';
import '../models/planned_expense.dart';
import '../models/expense.dart';

class NotificationService {
  static const String _lastNotificationCheckKey = 'last_notification_check';
  static const String _lastActivityKey = 'last_activity_';
  static const String _notificationReadKey = 'notification_read_';

  // Get current user ID from Firebase Auth
  static Future<String?> _getCurrentUserId() async {
    final firebaseAuth = FirebaseAuthService();
    return firebaseAuth.currentUserId;
  }

  // Get last notification check time
  static Future<DateTime> _getLastNotificationCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastNotificationCheckKey) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // Set last notification check time
  static Future<void> _setLastNotificationCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastNotificationCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Get last activity time for a specific type
  static Future<DateTime?> _getLastActivityTime(String activityType) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('$_lastActivityKey$activityType') ?? 0;
    return timestamp > 0 ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // Set last activity time for a specific type
  static Future<void> setLastActivityTime(String activityType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_lastActivityKey$activityType', DateTime.now().millisecondsSinceEpoch);
  }

  // Check if notification has been read
  static Future<bool> _isNotificationRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_notificationReadKey$notificationId') ?? false;
  }

  // Mark notification as read
  static Future<void> _markNotificationAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_notificationReadKey$notificationId', true);
  }

  // Mark all notifications as read
  static Future<void> markAllNotificationsAsRead() async {
    await _setLastNotificationCheck();
    
    // Get all notification IDs and mark them as read
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_notificationReadKey)) {
        await prefs.setBool(key, true);
      }
    }
    
    // Store the current timestamp as the last time notifications were read
    await prefs.setInt('notifications_last_read', DateTime.now().millisecondsSinceEpoch);
  }

  // Dismiss a specific notification (permanently)
  static Future<void> dismissNotification(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    // Store permanent dismissal
    await prefs.setBool('permanently_dismissed_$notificationId', true);
    // Also mark as read to prevent any popup
    await prefs.setBool('$_notificationReadKey$notificationId', true);
    await _setLastNotificationCheck();
  }

  // Check if a notification has been dismissed permanently
  static Future<bool> isNotificationDismissed(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('permanently_dismissed_$notificationId') ?? false;
  }
  
  // Clear all dismissed notifications (for debugging)
  static Future<void> clearAllDismissedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith('permanently_dismissed_') || key.startsWith('$_notificationReadKey')) {
        await prefs.remove(key);
      }
    }
    print('All dismissed notifications cleared');
  }

  // Dismiss all notifications of a specific type
  static Future<void> dismissAllNotificationsOfType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dismissed_$type', DateTime.now().toIso8601String());
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


  // Show prominent overdue expenses pop-up dialog
  static Future<void> showOverdueExpensesNotification(BuildContext context) async {
    final overdueExpenses = await checkOverduePlannedExpenses();
    
    if (overdueExpenses.isEmpty) return;

    // Check if user has already seen this overdue notification today
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastShownDate = prefs.getString('overdue_notification_shown_$today');
    
    if (lastShownDate == today) {
      return; // Don't show again today
    }

    // Mark as shown for today
    await prefs.setString('overdue_notification_shown_$today', today);

    showDialog(
      context: context,
      barrierDismissible: false, // Make it more prominent - user must interact
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - Red gradient like in the image
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[600]!, Colors.red[700]!],
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 24,
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
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You have ${overdueExpenses.length} expense${overdueExpenses.length > 1 ? 's' : ''} that ${overdueExpenses.length > 1 ? 'are' : 'is'} overdue',
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content - White section
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Warning message box
                        Container(
                          padding: const EdgeInsets.all(16),
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
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Overdue expense items
                        ...overdueExpenses.map<Widget>((expense) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
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
                                        Icons.shopping_cart_outlined,
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
                                          const SizedBox(height: 8),
                                          Text(
                                            '₱${expense['remainingAmount'].toStringAsFixed(2)} remaining',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: Colors.red[600],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${expense['completedItems']}/${expense['totalItems']} items completed • ${expense['daysOverdue']} days overdue',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
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
                        }),
                      ],
                    ),
                  ),
                ),
                // Action buttons - Footer
                Container(
                  padding: const EdgeInsets.all(20),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
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

  // Check for new expenses with smart grouping
  static Future<List<Map<String, dynamic>>> checkNewExpenses() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return [];

      final lastCheck = await _getLastNotificationCheck();
      final lastActivityTime = await _getLastActivityTime('new_expense');
      
      // Only check expenses added after the last notification check
      final startTime = lastActivityTime ?? lastCheck;
      
      // Get recent expenses
      final recentExpenses = await ExpenseService.getExpensesByDateRange(
        startDate: startTime,
        endDate: DateTime.now(),
      );

      if (recentExpenses.isEmpty) return [];

      // Group expenses by time (within 5 minutes = same activity)
      final groupedExpenses = <String, List<Expense>>{};
      for (final expense in recentExpenses) {
        final timeKey = '${expense.date.year}-${expense.date.month}-${expense.date.day}-${expense.date.hour}-${(expense.date.minute ~/ 5) * 5}';
        groupedExpenses.putIfAbsent(timeKey, () => []).add(expense);
      }

      // Return only the latest group of expenses
      if (groupedExpenses.isNotEmpty) {
        final latestGroup = groupedExpenses.values.last;
        final totalAmount = latestGroup.fold(0.0, (sum, expense) => sum + expense.amount);
        final categories = latestGroup.map((e) => e.category).toSet().toList();
        
        return [{
          'id': 'grouped_expenses_${DateTime.now().millisecondsSinceEpoch}',
          'name': latestGroup.length == 1 
              ? latestGroup.first.name 
              : '${latestGroup.length} expenses added',
          'category': categories.length == 1 ? categories.first : 'Multiple categories',
          'amount': totalAmount,
          'date': latestGroup.first.date,
          'type': 'new_expense',
          'count': latestGroup.length,
          'isGrouped': latestGroup.length > 1,
        }];
      }

      return [];
    } catch (e) {
      print('Error checking new expenses: $e');
      return [];
    }
  }

  // Check for new planned expenses with smart grouping
  static Future<List<Map<String, dynamic>>> checkNewPlannedExpenses() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return [];

      final lastCheck = await _getLastNotificationCheck();
      final lastActivityTime = await _getLastActivityTime('new_planned_expense');
      
      // Only check planned expenses added after the last notification check
      final startTime = lastActivityTime ?? lastCheck;
      
      // Get recent planned expenses
      final recentPlannedExpenses = await PlannedExpenseService.getPlannedExpensesByDateRange(
        startDate: startTime,
        endDate: DateTime.now(),
      );

      if (recentPlannedExpenses.isEmpty) return [];

      // Group planned expenses by time (within 5 minutes = same activity)
      final groupedExpenses = <String, List<PlannedExpense>>{};
      for (final expense in recentPlannedExpenses) {
        final timeKey = '${expense.createdAt.year}-${expense.createdAt.month}-${expense.createdAt.day}-${expense.createdAt.hour}-${(expense.createdAt.minute ~/ 5) * 5}';
        groupedExpenses.putIfAbsent(timeKey, () => []).add(expense);
      }

      // Return only the latest group of planned expenses
      if (groupedExpenses.isNotEmpty) {
        final latestGroup = groupedExpenses.values.last;
        final totalCost = latestGroup.fold(0.0, (sum, expense) => sum + expense.cost);
        final categories = latestGroup.map((e) => e.category).toSet().toList();
        
        return [{
          'id': 'grouped_planned_${DateTime.now().millisecondsSinceEpoch}',
          'name': latestGroup.length == 1 
              ? latestGroup.first.name 
              : '${latestGroup.length} planned expenses added',
          'category': categories.length == 1 ? categories.first : 'Multiple categories',
          'cost': totalCost,
          'date': latestGroup.first.createdAt,
          'type': 'new_planned_expense',
          'count': latestGroup.length,
          'isGrouped': latestGroup.length > 1,
        }];
      }

      return [];
    } catch (e) {
      print('Error checking new planned expenses: $e');
      return [];
    }
  }

  // Show pop-up notification for new activities
  static Future<void> showActivityNotification(BuildContext context, Map<String, dynamic> activity) async {
    // Check if this notification has already been shown
    final notificationId = activity['id'] ?? '';
    if (await _isNotificationRead(notificationId) || await isNotificationDismissed(notificationId)) {
      return; // Don't show if already read or dismissed
    }

    String title = '';
    String message = '';
    IconData icon = Icons.info;
    Color color = Colors.blue;

    switch (activity['type']) {
      case 'new_expense':
        title = 'New Expense Added';
        if (activity['isGrouped'] == true) {
          message = '${activity['count']} expenses - ₱${activity['amount'].toStringAsFixed(2)}';
        } else {
          message = '${activity['name']} - ₱${activity['amount'].toStringAsFixed(2)}';
        }
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case 'new_planned_expense':
        title = 'New Planned Expense';
        if (activity['isGrouped'] == true) {
          message = '${activity['count']} planned expenses - ₱${activity['cost'].toStringAsFixed(2)}';
        } else {
          message = '${activity['name']} - ₱${activity['cost'].toStringAsFixed(2)}';
        }
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case 'upcoming_expense':
        title = 'Planned Expense Ending Soon';
        message = '${activity['name']} - ${activity['daysRemaining']} days remaining';
        icon = Icons.alarm;
        color = Colors.blue;
        break;
      case 'overdue_expense':
        title = 'Overdue Planned Expense';
        message = '${activity['name']} is overdue by ${activity['daysOverdue']} days';
        icon = Icons.warning;
        color = Colors.red;
        break;
    }

    // Show snackbar notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () async {
            // Mark notification as read
            await _markNotificationAsRead(notificationId);
            // Update activity time
            await setLastActivityTime(activity['type']);
            
            // Navigate to appropriate page based on type
            if (activity['type'] == 'new_planned_expense' || activity['type'] == 'overdue_expense' || activity['type'] == 'upcoming_expense') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewSetExpensePage(
                    plannedExpenseId: activity['id'],
                  ),
                ),
              );
            } else if (activity['type'] == 'new_expense') {
              // For new expenses, navigate directly to the expense details
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewSetExpensePage(
                    plannedExpenseId: activity['id'],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // Real-time listener for planned expenses
  static Stream<List<Map<String, dynamic>>> getPlannedExpensesStream() {
    return FirebaseFirestore.instance
        .collection('planned_expenses')
        .snapshots()
        .asyncMap((snapshot) async {
      final userId = await _getCurrentUserId();
      if (userId == null) return <Map<String, dynamic>>[];

      final now = DateTime.now();
      final overdueExpenses = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['userId'] == userId) {
          final endDate = (data['endDate'] as Timestamp).toDate();
          if (endDate.isBefore(now)) {
            final items = (data['items'] as List?)?.map((item) => 
              PlannedExpenseItem.fromJson(item)).toList() ?? [];
            
            overdueExpenses.add({
              'id': doc.id,
              'name': data['name'],
              'category': data['category'],
              'endDate': endDate,
              'isCompleted': items.every((item) => item.isPurchased),
              'completedItems': items.where((item) => item.isPurchased).length,
              'totalItems': items.length,
              'remainingAmount': data['cost'] - items.where((item) => item.isPurchased)
                  .fold(0.0, (sum, item) => sum + item.cost),
              'totalAmount': data['cost'],
              'daysOverdue': now.difference(endDate).inDays,
              'type': 'overdue_expense',
            });
          }
        }
      }

      return overdueExpenses;
    });
  }

  // Real-time listener for expenses
  static Stream<List<Map<String, dynamic>>> getExpensesStream() {
    return FirebaseFirestore.instance
        .collection('expenses')
        .snapshots()
        .asyncMap((snapshot) async {
      final userId = await _getCurrentUserId();
      if (userId == null) return <Map<String, dynamic>>[];

      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      final newExpenses = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['userId'] == userId) {
          final createdAt = DateTime.parse(data['createdAt']);
          if (createdAt.isAfter(fiveMinutesAgo)) {
            newExpenses.add({
              'id': doc.id,
              'name': data['name'],
              'category': data['category'],
              'amount': data['amount'],
              'date': DateTime.parse(data['date']),
              'type': 'new_expense',
            });
          }
        }
      }

      return newExpenses;
    });
  }

  // Check and show all notifications
  static Future<void> checkAndShowNotifications(BuildContext context) async {
    // Check for overdue expenses
    await showOverdueExpensesNotification(context);
    
    // Check for new expenses (with smart grouping)
    final newExpenses = await checkNewExpenses();
    for (final expense in newExpenses) {
      await showActivityNotification(context, expense);
    }
    
    // Check for new planned expenses (with smart grouping)
    final newPlannedExpenses = await checkNewPlannedExpenses();
    for (final plannedExpense in newPlannedExpenses) {
      await showActivityNotification(context, plannedExpense);
    }
    
    // Check for upcoming planned expenses (ending soon)
    final upcomingExpenses = await checkUpcomingPlannedExpenses();
    for (final expense in upcomingExpenses) {
      await showActivityNotification(context, expense);
    }
  }
  
  // Check for upcoming planned expenses (ending within 3 days)
  static Future<List<Map<String, dynamic>>> checkUpcomingPlannedExpenses() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return [];
      }

      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));
      
      // Get all planned expenses
      final plannedExpenses = await PlannedExpenseService.getAllPlannedExpenses();
      
      // Filter expenses that are ending soon (within 3 days)
      final upcomingExpenses = plannedExpenses.where((expense) {
        final endDate = expense.endDate;
        return endDate.isAfter(now) && endDate.isBefore(threeDaysFromNow);
      }).toList();

      // Convert to notification format
      return upcomingExpenses.map((expense) => {
        'id': expense.id,
        'name': expense.name,
        'category': expense.category,
        'endDate': expense.endDate,
        'isCompleted': expense.items.every((item) => item.isPurchased),
        'completedItems': expense.items.where((item) => item.isPurchased).length,
        'totalItems': expense.items.length,
        'remainingAmount': expense.remainingAmount,
        'totalAmount': expense.cost,
        'daysRemaining': expense.endDate.difference(now).inDays,
        'type': 'upcoming_expense',
      }).toList();
    } catch (e) {
      print('Error checking upcoming planned expenses: $e');
      return [];
    }
  }

  // Initialize real-time notification listeners
  static void initializeRealTimeNotifications(BuildContext context) {
    // Listen for new expenses
    getExpensesStream().listen((expenses) {
      for (final expense in expenses) {
        showActivityNotification(context, expense);
      }
    });

    // Listen for overdue planned expenses
    getPlannedExpensesStream().listen((overdueExpenses) {
      for (final expense in overdueExpenses) {
        showActivityNotification(context, expense);
      }
    });
  }
}
