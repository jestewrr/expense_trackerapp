import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'addsetexpense.dart' as addset;
import 'services/planned_expense_service.dart';
import 'services/expense_service.dart';
import 'models/planned_expense.dart';

class ViewSetExpensePage extends StatefulWidget {
  final String? plannedExpenseId;

  const ViewSetExpensePage({
    super.key,
    this.plannedExpenseId,
  });

  @override
  State<ViewSetExpensePage> createState() => _ViewSetExpensePageState();
}

class _ViewSetExpensePageState extends State<ViewSetExpensePage> {
  bool isLoading = true;
  final Logger _logger = Logger();
  
  PlannedExpense? plannedExpense;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (widget.plannedExpenseId != null) {
        final pe = await PlannedExpenseService.getPlannedExpenseById(widget.plannedExpenseId!);
        if (pe != null) {
          plannedExpense = pe;
        }
      }
    } catch (e) {
      _logger.e('Error loading planned expense data: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]},${date.day},${date.year}';
  }

  double _calculateRemainingAmount(PlannedExpense expense) {
    // Calculate total amount of checked items
    double checkedAmount = 0.0;
    for (final item in expense.items) {
      if (item.isPurchased) {
        checkedAmount += item.cost;
      }
    }
    
    // Return remaining amount (original cost - checked items)
    return expense.cost - checkedAmount;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
      case 'Food & Drinks':
        return Icons.fastfood;
      case 'Transport':
        return Icons.directions_car;
      case 'Bills':
        return Icons.receipt_long;
      case 'Shopping':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Details",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D5FEF)),
          ),
        ),
      );
    }

    if (plannedExpense == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Details",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: false,
        ),
        body: const Center(
          child: Text(
            'Planned expense not found',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      );
    }

    final exp = plannedExpense!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "List",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            // Main expense card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expense name
                  Text(
                    exp.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category, icon, amount, and date in one row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getCategoryIcon(exp.category),
                          size: 24,
                          color: Colors.blue[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          exp.category,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₱${exp.remainingAmount.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue[800],
                              ),
                            ),
                            if (exp.items.isNotEmpty && exp.remainingAmount != exp.cost) ...[
                              const SizedBox(height: 2),
                              Text(
                                "of ₱${exp.cost.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(exp.startDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Checklist details
                  if (exp.items.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.checklist,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Checklist Items",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...exp.items.map((item) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: item.isPurchased ? Colors.green[50] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.isPurchased ? Colors.green[200]! : Colors.grey[200]!,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () async {
                                // Toggle the item's purchased state
                                final result = await PlannedExpenseService.toggleItemPurchased(
                                  plannedExpenseId: exp.id,
                                  itemId: item.id,
                                  isPurchased: !item.isPurchased,
                                );
                                
                                if (result['success']) {
                                  // Reload the data to reflect changes
                                  await _loadData();
                                  setState(() {});
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message']),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                children: [
                                  // Checkbox
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: item.isPurchased ? Colors.green[600] : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: item.isPurchased ? Colors.green[600]! : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      item.isPurchased ? Icons.check : Icons.check_box_outline_blank,
                                      size: 16,
                                      color: item.isPurchased ? Colors.white : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Item name
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: item.isPurchased ? Colors.green[700] : Colors.black87,
                                        decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // Item amount
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: item.isPurchased ? Colors.green[100] : Colors.blue[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "₱${item.cost.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: item.isPurchased ? Colors.green[700] : Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Edit button
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => addset.AddSetExpensePage(
                                initialExpense: {
                                  'id': exp.id,
                                  'name': exp.name,
                                  'category': exp.category,
                                  'amount': exp.cost.toString(),
                                  'date': exp.startDate.toIso8601String(),
                                  'notes': exp.notes ?? '',
                                  'items': exp.items.map((item) => {
                                    'name': item.name,
                                    'cost': item.cost,
                                    'isPurchased': item.isPurchased,
                                  }).toList(),
                                },
                              ),
                            ),
                          );
                          if (result != null) {
                            await _loadData();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      // Checkmark button
                      GestureDetector(
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Mark as Completed'),
                              content: Text('Are you sure you want to mark "${exp.name}" as completed? This will add it to your expense records.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                                  child: const Text('Mark Complete'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true) {
                            try {
                              // Add to expense records
                              await ExpenseService.createExpense(
                                name: exp.name,
                                amount: exp.cost,
                                category: exp.category,
                                categoryIcon: _getCategoryIcon(exp.category),
                                date: DateTime.now(),
                                description: exp.notes ?? 'Completed planned expense',
                              );
                              
                              // Remove from planned expenses
                              await PlannedExpenseService.deletePlannedExpense(exp.id);
                              
                              if (mounted) {
                                Navigator.pop(context); // Go back to previous screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Expense marked as completed and added to records'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error completing expense: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      // Delete button
                      GestureDetector(
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Planned Expense'),
                              content: Text('Are you sure you want to delete "${exp.name}"?\n\nThis action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Yes, Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            try {
                              await PlannedExpenseService.deletePlannedExpense(exp.id);
                              if (mounted) {
                                Navigator.pop(context); // Go back to previous screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Planned expense deleted successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error deleting expense: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}