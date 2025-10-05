import 'package:flutter/material.dart';
import 'addsetexpense.dart';
import 'viewsetexpense.dart';
import 'services/planned_expense_service.dart';
import 'models/planned_expense.dart';

class SetExpensePage extends StatefulWidget {
  const SetExpensePage({super.key});

  @override
  State<SetExpensePage> createState() => _SetExpensePageState();
}

class _SetExpensePageState extends State<SetExpensePage> {
  List<PlannedExpense> plannedExpenses = [];
  bool _isLoading = true;

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

  Future<void> _deletePlannedExpense(PlannedExpense expense) async {
    try {
      final result = await PlannedExpenseService.deletePlannedExpense(expense.id);
      if (result['success']) {
        setState(() {
          plannedExpenses.removeWhere((e) => e.id == expense.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting planned expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
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
          "Planned Expense",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : plannedExpenses.isEmpty
                ? const Center(
                    child: Text(
                      "No planned expense yet",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("List", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      ...plannedExpenses.map((exp) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Date:  ${_formatDate(exp.startDate)} - ${_formatDate(exp.endDate)}",
                              style: const TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            const Spacer(),
                            const Icon(Icons.calendar_month, color: Colors.black),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "Budget: \$${exp.totalBudget.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Text(
                              "Cost: \$${exp.cost.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 28),
                              onPressed: () async {
                                // Pass the selected expense data for editing
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddSetExpensePage(
                                      initialExpense: {
                                        'id': exp.id,
                                        'name': exp.name,
                                        'category': exp.category,
                                        'cost': exp.cost.toString(),
                                        'startDate': exp.startDate.toIso8601String(),
                                        'endDate': exp.endDate.toIso8601String(),
                                        'budget': exp.totalBudget.toString(),
                                      },
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  // Reload the expenses after editing
                                  await _loadPlannedExpenses();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye, size: 28),
                              onPressed: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewSetExpensePage(
                                      plannedExpenseId: exp.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 28),
                              onPressed: () {
                                // Confirm before deleting
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Planned Expense'),
                                    content: const Text('Are you sure you want to delete this planned expense?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await _deletePlannedExpense(exp);
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        shape: const CircleBorder(),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddSetExpensePage(),
            ),
          );
          if (result != null) {
            // Reload the expenses after adding
            await _loadPlannedExpenses();
          }
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        height: 48,
        color: Colors.blue[100],
      ),
    );
  }
}