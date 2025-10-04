import 'package:flutter/material.dart';

class AddSetExpensePage extends StatefulWidget {
  final Map<String, String>? initialExpense; // Add this

  const AddSetExpensePage({super.key, this.initialExpense});

  @override
  State<AddSetExpensePage> createState() => _AddSetExpensePageState();
}

class _AddSetExpensePageState extends State<AddSetExpensePage> {
  final TextEditingController _budgetController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // List of expense forms
  List<Map<String, dynamic>> expenses = [
    {
      'name': TextEditingController(),
      'category': TextEditingController(),
      'cost': TextEditingController(),
      'startDate': null,
      'endDate': null,
    }
  ];

  @override
  void initState() {
    super.initState();
    // Prefill budget and first expense form if editing
    if (widget.initialExpense != null) {
      _budgetController.text = widget.initialExpense!['budget'] ?? "";
      expenses[0]['name'].text = widget.initialExpense!['name'] ?? "";
      expenses[0]['category'].text = widget.initialExpense!['category'] ?? "";
      expenses[0]['cost'].text = widget.initialExpense!['cost'] ?? "";
      // Date parsing
      DateTime? startDate = DateTime.tryParse(widget.initialExpense!['startDate'] ?? "");
      DateTime? endDate = DateTime.tryParse(widget.initialExpense!['endDate'] ?? "");
      expenses[0]['startDate'] = startDate;
      expenses[0]['endDate'] = endDate;
    }
  }

  // Helper for picking dates
  Future<void> _pickDate(int index, {required bool isStart}) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          expenses[index]['startDate'] = picked;
        } else {
          expenses[index]['endDate'] = picked;
        }
      });
    }
  }

  // Calculate total expense for each form
  String _getTotalExpense(int index) {
    final costText = expenses[index]['cost'].text;
    if (costText.isEmpty) return "0.00";
    return double.tryParse(costText)?.toStringAsFixed(2) ?? "0.00";
  }

  // Add new expense form and scroll to bottom
  void _addExpenseForm() {
    setState(() {
      expenses.add({
        'name': TextEditingController(),
        'category': TextEditingController(),
        'cost': TextEditingController(),
        'startDate': null,
        'endDate': null,
      });
    });
    // Scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  // Build input field
  Widget _buildInputField({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
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
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
          child: Column(
            children: [
              _buildInputField(
                child: Row(
                  children: [
                    const Text(
                      "Add total budget:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "1,000",
                          hintStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(expenses.length, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Expense ${index + 1}:",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      _buildInputField(
                        child: TextField(
                          controller: expenses[index]['name'],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Name:",
                            hintStyle: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      _buildInputField(
                        child: TextField(
                          controller: expenses[index]['category'],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Category:",
                            hintStyle: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      _buildInputField(
                        child: TextField(
                          controller: expenses[index]['cost'],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Cost:",
                            hintStyle: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      _buildInputField(
                        child: Row(
                          children: [
                            const Text("Start date:", style: TextStyle(fontSize: 16)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _pickDate(index, isStart: true),
                            ),
                            Text(
                              expenses[index]['startDate'] == null
                                  ? ""
                                  : "${expenses[index]['startDate'].month}-${expenses[index]['startDate'].day}-${expenses[index]['startDate'].year}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      _buildInputField(
                        child: Row(
                          children: [
                            const Text("End date:", style: TextStyle(fontSize: 16)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _pickDate(index, isStart: false),
                            ),
                            Text(
                              expenses[index]['endDate'] == null
                                  ? ""
                                  : "${expenses[index]['endDate'].month}-${expenses[index]['endDate'].day}-${expenses[index]['endDate'].year}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      _buildInputField(
                        child: Row(
                          children: [
                            Text(
                              "Total expense: ${_getTotalExpense(index)}",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addExpenseForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Add",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Collect planned expenses and pop to previous page
                        List<Map<String, dynamic>> plannedExpenses = expenses.map((exp) {
                          return {
                            'name': exp['name'].text,
                            'category': exp['category'].text,
                            'cost': exp['cost'].text,
                            'startDate': exp['startDate'],
                            'endDate': exp['endDate'],
                          };
                        }).toList();
                        Navigator.pop(context, {
                          'budget': _budgetController.text,
                          'expenses': plannedExpenses,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      // Remove floatingActionButton, buttons are now at the bottom
      bottomNavigationBar: Container(
        height: 48,
        color: Colors.blue[100],
      ),
    );
  }
}