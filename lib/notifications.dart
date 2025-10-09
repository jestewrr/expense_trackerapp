import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/expense_service.dart';
import 'services/planned_expense_service.dart';
import 'models/planned_expense.dart';

class NotificationItem {
  final String id;
  final String type; // 'expense', 'planned_expense', 'completed_expense'
  final String title;
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final IconData icon;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.icon,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem> notifications = [];
  bool isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Start timer to refresh notifications every minute for real-time updates
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild to update relative times
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final List<NotificationItem> allNotifications = [];

      // Load regular expenses
      final expenses = await ExpenseService.getAllExpenses();
      for (final expense in expenses) {
        allNotifications.add(NotificationItem(
          id: expense.id,
          type: 'expense',
          title: 'Expense Added',
          description: '${expense.name} - ${expense.category}',
          amount: expense.amount,
          category: expense.category,
          date: expense.date,
          icon: _getCategoryIcon(expense.category),
        ));
      }

      // Load planned expenses
      final plannedExpenses = await PlannedExpenseService.getAllPlannedExpenses();
      for (final plannedExpense in plannedExpenses) {
        allNotifications.add(NotificationItem(
          id: plannedExpense.id,
          type: 'planned_expense',
          title: 'Planned Expense Created',
          description: '${plannedExpense.name} - ${plannedExpense.category}',
          amount: plannedExpense.cost,
          category: plannedExpense.category,
          date: plannedExpense.createdAt,
          icon: _getCategoryIcon(plannedExpense.category),
        ));
      }

      // Sort by date (newest first)
      allNotifications.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        notifications = allNotifications;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & drinks':
        return Icons.fastfood;
      case 'transport':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt_long;
      case 'shopping':
        return Icons.shopping_bag;
      case 'games':
        return Icons.games;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.health_and_safety;
      case 'education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(date.year, date.month, date.day);
    
    if (notificationDate == today) {
      // For today's notifications, show relative time
      final difference = now.difference(date);
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      }
    }
    
    // For other days, show the actual time
    return DateFormat('h:mm a').format(date);
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'expense':
        return Colors.red;
      case 'planned_expense':
        return Colors.blue;
      case 'completed_expense':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'expense':
        return 'Expense';
      case 'planned_expense':
        return 'Planned';
      case 'completed_expense':
        return 'Completed';
      default:
        return 'Activity';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your activity history will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Icon container
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _getTypeColor(notification.type).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                notification.icon,
                                color: _getTypeColor(notification.type),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getTypeColor(notification.type).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _getTypeText(notification.type),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _getTypeColor(notification.type),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '₱${notification.amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: _getTypeColor(notification.type),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatDate(notification.date),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(notification.date),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
