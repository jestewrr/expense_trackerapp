import 'package:expense_tracker_application/categooryaddexpense.dart';
import 'package:flutter/material.dart';
import 'services/expense_service.dart';
import 'services/planned_expense_service.dart';
import 'models/expense.dart';

class CategoryClickedPage extends StatefulWidget {
  final IconData icon;
  final String category;

  const CategoryClickedPage({
    super.key,
    required this.icon,
    required this.category,
  });

  @override
  State<CategoryClickedPage> createState() => _CategoryClickedPageState();
}

class _CategoryClickedPageState extends State<CategoryClickedPage> {
  List<Expense> expenses = [];
  bool _isLoading = true;
  double _totalAmount = 0.0;
  double _dailyExpense = 0.0;
  
  // Add dropdown functionality like dashboard
  final List<String> expenseOptions = ['Weekly', 'Monthly', 'Yearly'];
  int selectedExpenseOption = 0; // 0: Weekly, 1: Monthly, 2: Yearly

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categoryExpenses = await ExpenseService.getExpensesByCategory(widget.category);
      
      // Calculate totals based on selected period for this category
      await _calculateCategoryExpenses();
      
      // Calculate daily expense for this category
      await _calculateDailyExpense();
      
      setState(() {
        expenses = categoryExpenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading expenses: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _calculateCategoryExpenses() async {
    final now = DateTime.now();
    DateTime rangeStart;
    DateTime rangeEnd;
    
    switch (selectedExpenseOption) {
      case 0: // Weekly
        rangeStart = now.subtract(Duration(days: now.weekday - 1));
        rangeEnd = rangeStart.add(const Duration(days: 7));
        break;
      case 1: // Monthly
        rangeStart = DateTime(now.year, now.month, 1);
        rangeEnd = DateTime(now.year, now.month + 1, 0);
        break;
      case 2: // Yearly
        rangeStart = DateTime(now.year, 1, 1);
        rangeEnd = DateTime(now.year, 12, 31);
        break;
      default:
        rangeStart = DateTime(now.year, now.month, 1);
        rangeEnd = DateTime(now.year, now.month + 1, 0);
    }

    // Calculate total expense for the selected period for this category
    try {
      final spentExpenses = await ExpenseService.getExpensesByDateRange(
        startDate: rangeStart,
        endDate: rangeEnd,
      );
      
      // Filter expenses for this specific category
      final categoryExpenses = spentExpenses.where(
        (expense) => expense.category == widget.category
      ).toList();
      
      _totalAmount = categoryExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    } catch (_) {
      _totalAmount = 0.0;
    }
  }

  Future<void> _calculateDailyExpense() async {
    try {
      // Get today's regular expenses for this category
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final todaysExpenses = await ExpenseService.getExpensesByDateRange(
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      final categoryTodaysExpenses = todaysExpenses.where(
        (expense) => expense.category == widget.category
      ).toList();
      
      final regularExpenseTotal = categoryTodaysExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      
      // Get today's planned expenses for this category
      final plannedExpenses = await PlannedExpenseService.getPlannedExpensesByDateRange(
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      // Calculate total from planned expenses that were purchased today for this category
      double plannedExpenseTotal = 0.0;
      for (final plannedExpense in plannedExpenses) {
        for (final item in plannedExpense.items) {
          if (item.isPurchased && item.purchasedAt != null && item.category == widget.category) {
            final purchasedDate = item.purchasedAt!;
            if (purchasedDate.isAfter(startOfDay) && purchasedDate.isBefore(endOfDay)) {
              plannedExpenseTotal += item.cost;
            }
          }
        }
      }
      
      _dailyExpense = regularExpenseTotal + plannedExpenseTotal;
    } catch (_) {
      _dailyExpense = 0.0;
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    try {
      final result = await ExpenseService.deleteExpense(expense.id);
      if (result['success']) {
        await _loadExpenses(); // Reload the list
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
            content: Text('Error deleting expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _getDateRangeText() {
    final now = DateTime.now();
    
    switch (selectedExpenseOption) {
      case 0: // Weekly
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${_formatDateForRange(weekStart)} - ${_formatDateForRange(weekEnd)}';
      case 1: // Monthly
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        return '${_formatDateForRange(monthStart)} - ${_formatDateForRange(monthEnd)}';
      case 2: // Yearly
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year, 12, 31);
        return '${_formatDateForRange(yearStart)} - ${_formatDateForRange(yearEnd)}';
      default:
        return '';
    }
  }

  String _formatDateForRange(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _navigateToEdit(Expense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditClickedCategoryPage(
          expense: expense,
          onExpenseUpdated: _loadExpenses,
        ),
      ),
    );
    // Always refresh after returning from edit page
    await _loadExpenses();
  }

  void _showDeleteConfirmation(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExpense(expense);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // makes it scrollable
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Name + Edit button at top
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    expense.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _navigateToEdit(expense);
                    },
                  )
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Amount: ₱${expense.amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[600], // ✅ Money is green
                ),
              ),
              const SizedBox(height: 8),
              // Date + Delete button at bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Date: ${_formatDate(expense.date)}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(expense);
                    },
                  )
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button and category
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(widget.icon, size: 28, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            // Balance Card with dropdown and date range
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue[300],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Total Expense',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: expenseOptions[selectedExpenseOption],
                          dropdownColor: const Color(0xFF8EA7FF),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          underline: const SizedBox(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          onChanged: (String? newValue) async {
                            setState(() {
                              selectedExpenseOption = expenseOptions.indexOf(newValue!);
                            });
                            await _calculateCategoryExpenses();
                            setState(() {});
                          },
                          items: expenseOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('₱${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32)),
                    const SizedBox(height: 8),
                    const Text('Daily Expenses',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    Text('₱${_dailyExpense.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getDateRangeText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Lists header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Text('Lists:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            // Expenses Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : expenses.isEmpty
                      ? const Center(
                          child: Text(
                            'No expenses yet',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        )
                      : GridView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                  return GestureDetector(
                    onTap: () => _showExpenseDetails(expense),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[100]!, Colors.blue[200]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + Edit icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                expense.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.black54, size: 20),
                                onPressed: () async {
                                  await _navigateToEdit(expense);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Amount
                          Text(
                            "₱${expense.amount.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[600], // ✅ Green money
                            ),
                          ),
                          const Spacer(),
                          // Date + Delete icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(expense.date),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () {
                                  _showDeleteConfirmation(expense);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Add button
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 32),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryAddExpensePage(
                            category: widget.category,
                            icon: widget.icon,
                          ),
                        ),
                      );
                      if (result != null) {
                        await _loadExpenses();
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditClickedCategoryPage extends StatefulWidget {
  final Expense expense;
  final VoidCallback onExpenseUpdated;

  const EditClickedCategoryPage({
    super.key,
    required this.expense,
    required this.onExpenseUpdated,
  });

  @override
  State<EditClickedCategoryPage> createState() => _EditClickedCategoryPageState();
}

class _EditClickedCategoryPageState extends State<EditClickedCategoryPage> {
  late TextEditingController amountController;
  late TextEditingController nameController;
  late TextEditingController dateController;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(text: widget.expense.amount.toString());
    nameController = TextEditingController(text: widget.expense.name);
    selectedDate = widget.expense.date;
    dateController = TextEditingController(text: _formatDate(widget.expense.date));
  }

  @override
  void dispose() {
    amountController.dispose();
    nameController.dispose();
    dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Only allow current and past dates
    );
    
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = _formatDate(picked);
      });
      // Automatically show time picker after date selection
      await _pickTime();
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        // Update the selected date with the chosen time
        if (selectedDate != null) {
          selectedDate = DateTime(
            selectedDate!.year,
            selectedDate!.month,
            selectedDate!.day,
            picked.hour,
            picked.minute,
          );
          dateController.text = _formatDate(selectedDate!);
        }
      });
    }
  }

  Future<void> _updateExpense() async {
    if (nameController.text.isEmpty || amountController.text.isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.tryParse(amountController.text);
      if (amount == null) {
        throw Exception('Invalid amount');
      }

      final result = await ExpenseService.updateExpense(
        id: widget.expense.id,
        name: nameController.text,
        amount: amount,
        category: widget.expense.category,
        categoryIcon: widget.expense.categoryIcon,
        date: selectedDate!,
        description: widget.expense.description,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          widget.onExpenseUpdated();
          Navigator.pop(context, result);
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
            content: Text('Error updating expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteExpense() async {
    try {
      final result = await ExpenseService.deleteExpense(widget.expense.id);
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          widget.onExpenseUpdated();
          Navigator.pop(context, result);
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
            content: Text('Error deleting expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Edit Expenses',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Amount field
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: amountController,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Amount:',
                    prefixText: '₱',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 20),
              // Name field
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Name:',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Date field
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: 'Date:',
                        ),
                        readOnly: true,
                        onTap: _pickDate,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Update button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Update',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Delete button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Expense'),
                        content: Text('Are you sure you want to delete "${widget.expense.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteExpense();
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
