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
  String _searchQuery = '';
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    _loadPlannedExpenses();
  }

  Future<void> _loadPlannedExpenses() async {
    setState(() {
    });

    try {
      final expenses = await PlannedExpenseService.getAllPlannedExpenses();
      setState(() {
        plannedExpenses = expenses;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
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
    return DateFormat('MMM. d, yyyy').format(date); // Example: Oct. 11, 2025
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
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.search,
                            color: Colors.blue[600],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search Planned Expenses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
            autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter name or category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
            onChanged: (value) {
              tempQuery = value;
            },
            controller: TextEditingController(text: _searchQuery),
          ),
                  ),
                  // Actions
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = tempQuery;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Search',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
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
      body: filteredExpenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Modern empty state icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          size: 50,
                          color: Colors.blue[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text(
                        "No Planned Expenses Yet",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          "Start planning your expenses by adding your first planned payment",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
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
                          color: Colors.blue[100], // Light blue color to match the theme
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
                                  "₱${exp.cost.toStringAsFixed(2)}",
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
                                    color: Colors.black,
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
                                      color: Colors.blue[200],
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
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.15),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Header
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green[50],
                                                    borderRadius: const BorderRadius.only(
                                                      topLeft: Radius.circular(16),
                                                      topRight: Radius.circular(16),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.green[100],
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Icon(
                                                          Icons.shopping_cart,
                                                          color: Colors.green[600],
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          'Mark as Completed',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.green[800],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Content
                                                Flexible(
                                                  child: SingleChildScrollView(
                                                    padding: const EdgeInsets.all(12),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Are you sure you want to mark this planned expense as completed?',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        
                                                        // Items section
                                                        if (exp.items.isNotEmpty) ...[
                                                          Container(
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                              color: Colors.green[50],
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: Colors.green[200]!),
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons.checklist,
                                                                      color: Colors.green[600],
                                                                      size: 16,
                                                                    ),
                                                                    const SizedBox(width: 6),
                                                                    Text(
                                                                      'Items (${exp.items.where((item) => item.isPurchased).length}/${exp.items.length} completed):',
                                                                      style: TextStyle(
                                                                        fontWeight: FontWeight.w600,
                                                                        fontSize: 14,
                                                                        color: Colors.green[700],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(height: 6),
                                                                ...exp.items.take(3).map((item) => Padding(
                                                                  padding: const EdgeInsets.only(bottom: 4),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                        item.isPurchased ? Icons.check_circle : Icons.radio_button_unchecked,
                                                                        color: item.isPurchased ? Colors.green[600] : Colors.grey[400],
                                                                        size: 14,
                                                                      ),
                                                                      const SizedBox(width: 6),
                                                                      Expanded(
                                                                        child: Text(
                                                                          item.name,
                                                                          style: TextStyle(
                                                                            fontSize: 12,
                                                                            color: item.isPurchased ? Colors.green[700] : Colors.black87,
                                                                            fontWeight: item.isPurchased ? FontWeight.w500 : FontWeight.normal,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        '₱${item.cost.toStringAsFixed(2)}',
                                                                        style: TextStyle(
                                                                          fontSize: 12,
                                                                          color: item.isPurchased ? Colors.green[600] : Colors.grey[600],
                                                                          fontWeight: FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )),
                                                                if (exp.items.length > 3) ...[
                                                                  const SizedBox(height: 4),
                                                                  Text(
                                                                    '... and ${exp.items.length - 3} more items',
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      color: Colors.grey[600],
                                                                      fontStyle: FontStyle.italic,
                                                                    ),
                                                                  ),
                                                                ],
                                                                const SizedBox(height: 6),
                                                                Container(
                                                                  padding: const EdgeInsets.all(6),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.green[200],
                                                                    borderRadius: BorderRadius.circular(4),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      Text(
                                                                        'Total:',
                                                                        style: TextStyle(
                                                                          fontWeight: FontWeight.bold,
                                                                          fontSize: 14,
                                                                          color: Colors.green[800],
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        '₱${exp.items.fold(0.0, (sum, item) => sum + item.cost).toStringAsFixed(2)}',
                                                                        style: TextStyle(
                                                                          fontWeight: FontWeight.bold,
                                                                          fontSize: 14,
                                                                          color: Colors.green[800],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ] else ...[
                                                          Container(
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                              color: Colors.green[50],
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: Colors.green[200]!),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons.check,
                                                                  color: Colors.green[600],
                                                                  size: 16,
                                                                ),
                                                                const SizedBox(width: 8),
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Text(
                                                                        exp.name,
                                                                        style: TextStyle(
                                                                          fontWeight: FontWeight.w600,
                                                                          fontSize: 14,
                                                                          color: Colors.black87,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        '₱${exp.cost.toStringAsFixed(2)}',
                                                                        style: TextStyle(
                                                                          color: Colors.green[600],
                                                                          fontSize: 12,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                        
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          'This will add it to your expense records.',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                // Actions
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[50],
                                                    borderRadius: const BorderRadius.only(
                                                      bottomLeft: Radius.circular(16),
                                                      bottomRight: Radius.circular(16),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextButton(
                                                          onPressed: () => Navigator.pop(context, false),
                                                          style: TextButton.styleFrom(
                                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'Cancel',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.green[600],
                                                            foregroundColor: Colors.white,
                                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            'Mark Complete',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 10,
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
                                      color: Colors.blue[200],
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
                                      builder: (context) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 35),
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
                                              // Modern header with warning icon
                                              Container(
                                                padding: const EdgeInsets.all(24),
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
                                                        Icons.delete_forever,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    const Expanded(
                                                        child: Text(
                                                          'Delete Planned Expense',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Content section
                                              Padding(
                                                padding: const EdgeInsets.all(24),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Warning message
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
                                                              'This action cannot be undone. All data will be permanently deleted.',
                                                              style: TextStyle(
                                                                fontSize: 8,
                                                                color: Colors.red[700],
                                                                height: 1.4,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    // Main question
                                                    Text(
                                                      'Are you sure you want to delete "${exp.name}"?',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black87,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Modern action buttons
                                              Container(
                                                padding: const EdgeInsets.all(24),
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
                                                        onPressed: () => Navigator.pop(context, false),
                                                        style: TextButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Cancel',
                                                          style: TextStyle(
                                                            color: Colors.grey[600],
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.red[600],
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          elevation: 2,
                                                        ),
                                                        child: const Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 10,
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
                                      color: Colors.blue[200],
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
            await _loadPlannedExpenses();
          }
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}