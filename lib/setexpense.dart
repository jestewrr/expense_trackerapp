import 'package:flutter/material.dart';
import 'addsetexpense.dart'; // Add this import
import 'viewsetexpense.dart'; // Add this import

class SetExpensePage extends StatefulWidget {
  const SetExpensePage({super.key});

  @override
  State<SetExpensePage> createState() => _SetExpensePageState();
}

class _SetExpensePageState extends State<SetExpensePage> {
  // Dummy planned expense dates
  final List<Map<String, String>> plannedExpenses = [
    {'start': '10/11/2025', 'end': '10/20/2025'},
    {'start': '10/21/2025', 'end': '10/30/2025'},
    {'start': '11/1/2025', 'end': '11/15/2025'},
  ];

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
        child: plannedExpenses.isEmpty
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
                              "Date:  ${exp['start']} - ${exp['end']}",
                              style: const TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            const Spacer(),
                            const Icon(Icons.calendar_month, color: Colors.black),
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
                                      initialExpense: exp, // Pass the expense to edit
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  setState(() {
                                    // Update the plannedExpenses list with the edited result
                                    final index = plannedExpenses.indexOf(exp);
                                    plannedExpenses[index] = result;
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye, size: 28),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewSetExpensePage(
                                      dateRange: "${exp['start']} - ${exp['end']}",
                                      totalBudget: 1000.0, // Replace with your actual budget value
                                      expenses: [
                                        // Replace with your actual expense details
                                        {
                                          'icon': Icons.lunch_dining,
                                          'category': 'Food',
                                          'total': 140.0,
                                          'items': [
                                            {'name': 'Deserts', 'cost': 40.0},
                                            {'name': 'Bread', 'cost': 20.0},
                                            {'name': 'Rice', 'cost': 50.0},
                                            {'name': 'Canned Goods', 'cost': 30.0},
                                          ],
                                        },
                                        {
                                          'icon': Icons.shopping_bag,
                                          'category': 'Shopping',
                                          'total': 120.0,
                                          'items': [
                                            {'name': 'Clothes', 'cost': 70.0},
                                            {'name': 'Skin Care', 'cost': 50.0},
                                          ],
                                        },
                                      ],
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
                                        onPressed: () {
                                          setState(() {
                                            plannedExpenses.remove(exp);
                                          });
                                          Navigator.pop(context);
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddSetExpensePage(),
            ),
          );
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