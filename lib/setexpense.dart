import 'package:flutter/material.dart';
import 'addsetexpense.dart';
import 'viewsetexpense.dart';
import 'services/planned_expense_service.dart';
import 'services/expense_service.dart';
import 'models/planned_expense.dart';
import 'package:intl/intl.dart'; // For better date formatting

class SetExpensePage extends StatefulWidget {
  const SetExpensePage({super.key});

  @override
  State<SetExpensePage> createState() => _SetExpensePageState();
}

class _SetExpensePageState extends State<SetExpensePage> {
  List<PlannedExpense> plannedExpenses = [];
  List<PlannedExpense> filteredExpenses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    _loadPlannedExpenses();
  }

  Future<void> _loadPlannedExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expenses = await PlannedExpenseService.getAllPlannedExpenses();
      setState(() {
        plannedExpenses = expenses;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading planned expenses: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<PlannedExpense> temp = plannedExpenses.where((exp) {
      return exp.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          exp.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    temp.sort((a, b) => _sortAsc
        ? a.startDate.compareTo(b.startDate)
        : b.startDate.compareTo(a.startDate));

    setState(() {
      filteredExpenses = temp;
    });
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

  String _formatDate(DateTime date) {
    return DateFormat('MMM,d,yyyy').format(date); // Example: Oct,6,2025
  }

  String _getTodayLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Today";
    }
    return "";
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = _searchQuery;
        return AlertDialog(
          title: const Text('Search Planned Expenses'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter name or category'),
            onChanged: (value) {
              tempQuery = value;
            },
            controller: TextEditingController(text: _searchQuery),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = tempQuery;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _toggleSort() {
    setState(() {
      _sortAsc = !_sortAsc;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Planned Expense",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: Icon(_sortAsc ? Icons.sort_by_alpha : Icons.sort, color: Colors.black),
            onPressed: _toggleSort,
            tooltip: _sortAsc ? "Sort Ascending" : "Sort Descending",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredExpenses.isEmpty
              ? const Center(
                  child: Text(
                    "No planned expense yet",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final exp = filteredExpenses[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewSetExpensePage(
                              plannedExpenseId: exp.id,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1BEE7), // Light purple/blue color
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Expense name
                            Text(
                              exp.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Category, icon, and amount row
                            Row(
                              children: [
                                Icon(_getCategoryIcon(exp.category), size: 24, color: Colors.black),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    exp.category,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Text(
                                  "-₱${exp.cost.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Date and Today label row
                            Row(
                              children: [
                                Text(
                                  _formatDate(exp.startDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_getTodayLabel(exp.startDate).isNotEmpty)
                                  Text(
                                    _getTodayLabel(exp.startDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                              ],
                            ),
                            // Notes display
                            if (exp.notes != null && exp.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Notes: ${exp.notes}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                            // Checklist indicator and View more button
                            if (exp.items.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.checklist, size: 16, color: Colors.black),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "Checklist",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ViewSetExpensePage(
                                            plannedExpenseId: exp.id,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "View more",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
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
                                        builder: (context) => AddSetExpensePage(
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
                                      await _loadPlannedExpenses();
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
                                        
                                        // Refresh the list
                                        await _loadPlannedExpenses();
                                        
                                        if (mounted) {
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
                                        await _loadPlannedExpenses();
                                        if (mounted) {
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
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFB3E5FC),
        shape: const CircleBorder(),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddSetExpensePage(),
            ),
          );
          if (result != null) {
            await _loadPlannedExpenses();
          }
        },
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}