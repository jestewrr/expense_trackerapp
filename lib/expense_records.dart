import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/expense_service.dart';
import 'services/category_service.dart';
import 'models/expense.dart';
import 'utils/responsive_dialog.dart';
import 'categooryaddexpense.dart';

class ExpenseRecordsPage extends StatefulWidget {
  const ExpenseRecordsPage({super.key});

  @override
  State<ExpenseRecordsPage> createState() => _ExpenseRecordsPageState();
}

class _ExpenseRecordsPageState extends State<ExpenseRecordsPage> {
  int selectedTab = 1; // 0: Today, 1: Weekly, 2: Monthly, 3: Annual
  bool isSelectionMode = false;
  Set<String> selectedExpenseIds = {};
  String searchQuery = '';
  String sortBy = 'date'; // date, amount, category, name
  String? selectedCategory; // For category-specific sorting
  List<Map<String, dynamic>> userCategories = []; // User's actual categories
  
  List<Expense> allExpenses = [];
  List<Expense> filteredExpenses = [];
  double totalAmount = 0.0;
  Map<String, double> categoryTotals = {};
  Map<String, double> dateTotals = {};

  @override
  void initState() {
    super.initState();
    _loadExpenseData();
    _loadUserCategories();
  }

  Future<void> _loadExpenseData() async {
    setState(() {
    });

    try {
      // Load expenses more efficiently based on selected tab
      final now = DateTime.now();
      List<Expense> expenses = [];
      
      switch (selectedTab) {
        case 0: // Today
          expenses = await ExpenseService.getTodaysExpenses();
          break;
        case 1: // Weekly
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 7));
          expenses = await ExpenseService.getExpensesByDateRange(
            startDate: weekStart,
            endDate: weekEnd,
          );
          break;
        case 2: // Monthly
          final monthStart = DateTime(now.year, now.month, 1);
          final monthEnd = DateTime(now.year, now.month + 1, 0);
          expenses = await ExpenseService.getExpensesByDateRange(
            startDate: monthStart,
            endDate: monthEnd,
          );
          break;
        case 3: // Annual
          final yearStart = DateTime(now.year, 1, 1);
          final yearEnd = DateTime(now.year, 12, 31);
          expenses = await ExpenseService.getExpensesByDateRange(
            startDate: yearStart,
            endDate: yearEnd,
          );
          break;
      }
      
      allExpenses = expenses;
      await _filterExpenses();
    } catch (e) {
      // Log error for debugging purposes
      debugPrint('Error loading expenses: $e');
    }

    setState(() {
    });
  }

  Future<void> _refreshData() async {
    await _loadExpenseData();
    await _loadUserCategories();
  }

  Future<void> _loadUserCategories() async {
    try {
      final categories = await CategoryService.getAllCategories();
      setState(() {
        userCategories = categories;
      });
    } catch (e) {
      print('Error loading user categories: $e');
    }
  }

  Future<void> _filterExpenses() async {
    // Use already loaded expenses instead of making new database calls
    List<Expense> expenses = List.from(allExpenses);

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      expenses = expenses.where((expense) {
        return expense.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
               expense.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
               (expense.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply category filter if specific category is selected
    if (selectedCategory != null) {
      expenses = expenses.where((expense) {
        return expense.category.toLowerCase() == selectedCategory!.toLowerCase();
      }).toList();
    }

    // Apply sorting
    switch (sortBy) {
      case 'date':
        expenses.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'amount':
        expenses.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'category':
        expenses.sort((a, b) => a.category.compareTo(b.category));
        break;
      case 'name':
        expenses.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    // Calculate category totals for chart
    Map<String, double> categoryTotals = {};
    for (final expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }

    // Calculate date totals for chart based on selected time period
    Map<String, double> dateTotals = {};
    for (final expense in expenses) {
      String dateKey;
      final expenseDate = expense.date;
      
      switch (selectedTab) {
        case 0: // Today - group by hour
          dateKey = '${expenseDate.hour}:00';
          break;
        case 1: // Weekly - group by day
          dateKey = '${expenseDate.day} ${_getMonthName(expenseDate.month)}';
          break;
        case 2: // Monthly - group by week
          final weekNumber = ((expenseDate.day - 1) / 7).floor() + 1;
          dateKey = 'Week $weekNumber';
          break;
        case 3: // Annual - group by month
          dateKey = _getMonthName(expenseDate.month);
          break;
        default:
          dateKey = '${expenseDate.day} ${_getMonthName(expenseDate.month)}';
      }
      
      dateTotals[dateKey] = (dateTotals[dateKey] ?? 0.0) + expense.amount;
    }

    // Debug: Print expenses for today
    if (selectedTab == 0) {
      print('=== TODAY EXPENSES DEBUG ===');
      print('Total expenses found: ${expenses.length}');
      for (final expense in expenses) {
        print('Expense: ${expense.name} - ₱${expense.amount} - Date: ${expense.date}');
      }
      print('Total amount: ₱${expenses.fold(0.0, (sum, expense) => sum + expense.amount)}');
      print('========================');
    }

    setState(() {
      filteredExpenses = expenses;
      totalAmount = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      this.categoryTotals = categoryTotals;
      this.dateTotals = dateTotals;
    });
  }

  String _getDateRangeText() {
    final now = DateTime.now();
    
    switch (selectedTab) {
      case 0: // Today
        return _formatDate(now);
      case 1: // Weekly
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';
      case 2: // Monthly
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        return '${_formatDate(monthStart)} - ${_formatDate(monthEnd)}';
      case 3: // Annual
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year, 12, 31);
        return '${_formatDate(yearStart)} - ${_formatDate(yearEnd)}';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}. ${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      selectedExpenseIds.clear();
    });
  }

  void _toggleExpenseSelection(String expenseId) {
    setState(() {
      if (selectedExpenseIds.contains(expenseId)) {
        selectedExpenseIds.remove(expenseId);
      } else {
        selectedExpenseIds.add(expenseId);
      }
    });
  }

  Future<void> _deleteSelectedExpenses() async {
    if (selectedExpenseIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveDialog.createConfirmationDialog(
        context: context,
        title: 'Delete Expenses',
        message: 'Are you sure you want to delete ${selectedExpenseIds.length} expense(s)? This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        icon: Icons.delete_outline,
        iconColor: Colors.red[600],
        confirmColor: Colors.red[600],
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirmed == true) {
      setState(() {
      });

      try {
        for (final expenseId in selectedExpenseIds) {
          await ExpenseService.deleteExpense(expenseId);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${selectedExpenseIds.length} expense(s) deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        setState(() {
          selectedExpenseIds.clear();
          isSelectionMode = false;
        });
        
        await _loadExpenseData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting expenses: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                          'Search Expenses',
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
                    decoration: const InputDecoration(
                      hintText: 'Search by name, category, or description...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                      _filterExpenses();
                    },
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
                            setState(() {
                              searchQuery = '';
                            });
                            _filterExpenses();
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Clear',
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
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Close',
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
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
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
                          Icons.sort,
                          color: Colors.blue[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sort by',
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSortOption('date', 'Date (Newest First)'),
                        _buildSortOption('amount', 'Amount (Highest First)'),
                        _buildSortOption('category', 'Category (A-Z)'),
                        _buildSortOption('name', 'Name (A-Z)'),
                        const Divider(),
                        const Text(
                          'Sort by Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Add user's actual category options
                        if (userCategories.isNotEmpty)
                          ...userCategories.map((category) {
                            return _buildCategorySortOption(
                              category['name'] ?? category['label'] ?? 'Unknown',
                              category['icon'] ?? Icons.category,
                            );
                          })
                        else
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No categories found. Create some categories first.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label) {
    final bool isSelected = sortBy == value;
    return ListTile(
      title: Text(label),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? const Color(0xFF5D5FEF) : Colors.grey,
      ),
      onTap: () {
        setState(() {
          sortBy = value;
          selectedCategory = null; // Clear category selection
        });
        _filterExpenses();
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCategorySortOption(String categoryName, dynamic icon) {
    final bool isSelected = selectedCategory == categoryName;
    IconData iconData;
    
    // Handle different icon types
    if (icon is IconData) {
      iconData = icon;
    } else if (icon is int) {
      iconData = IconData(icon, fontFamily: 'MaterialIcons');
    } else {
      iconData = Icons.category;
    }
    
    return ListTile(
      title: Text(categoryName),
      leading: Icon(
        iconData,
        color: isSelected ? const Color(0xFF5D5FEF) : Colors.grey[600],
        size: 20,
      ),
      trailing: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? const Color(0xFF5D5FEF) : Colors.grey,
      ),
      onTap: () {
        setState(() {
          selectedCategory = categoryName;
          sortBy = 'category';
        });
        _filterExpenses();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (allExpenses.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Expense Records', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.blue[50],
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Loading...'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: isSelectionMode 
          ? Text('${selectedExpenseIds.length} selected', style: const TextStyle(fontWeight: FontWeight.bold))
          : const Text('Expense Records', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blue[50],
        foregroundColor: Colors.black,
        elevation: 0,
        leading: isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
        actions: isSelectionMode
          ? [
              if (selectedExpenseIds.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteSelectedExpenses,
                ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _showSearchDialog,
              ),
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: _showSortDialog,
              ),
              IconButton(
                icon: const Icon(Icons.checklist),
                onPressed: _toggleSelectionMode,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
              ),
            ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTab('Today', 0),
                      const SizedBox(width: 6),
                      _buildTab('Weekly', 1),
                      const SizedBox(width: 6),
                      _buildTab('Monthly', 2),
                      const SizedBox(width: 6),
                      _buildTab('Annual', 3),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Date range and total
                Center(
                  child: Column(
                    children: [
                      Text(
                        _getDateRangeText(),
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Real chart showing expenses by category
                Container(
                  height: 180,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[100]!, Colors.blue[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0),
                    child: dateTotals.isEmpty
                        ? const Center(
                            child: Text(
                              'No data to display',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : Center(child: _buildDateChart()),
                  ),
                ),
                const SizedBox(height: 18),
                // Show message if no expenses
                if (filteredExpenses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No expenses found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add some expenses to see them here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Expense list
                  ...filteredExpenses.map((expense) => _buildExpenseItem(expense)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: isSelectionMode
        ? null
        : FloatingActionButton(
            onPressed: () async {
              // Navigate to add expense page
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryAddExpensePage(
                    category: 'General',
                    icon: Icons.category,
                  ),
                ),
              );
              if (result != null && mounted) {
                await _loadExpenseData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            backgroundColor: Colors.black,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
    );
  }

  Widget _buildTab(String label, int index) {
    final bool selected = selectedTab == index;
    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedTab = index;
        });
        await _filterExpenses();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.lightBlue[200] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.lightBlue[200]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    final isSelected = selectedExpenseIds.contains(expense.id);
    
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
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
                        color: Colors.red[50],
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
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red[600],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Delete Expense',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Are you sure you want to delete this expense? This action cannot be undone.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Actions
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, false),
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
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Delete',
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
          ),
        );
      },
      onDismissed: (direction) async {
        final result = await ExpenseService.deleteExpense(expense.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['success'] ? 'Expense deleted successfully' : result['message']),
              backgroundColor: result['success'] ? Colors.green : Colors.red,
            ),
          );
        }
        await _loadExpenseData();
      },
      child: GestureDetector(
        onTap: () {
          if (isSelectionMode) {
            _toggleExpenseSelection(expense.id);
          }
          // Edit functionality has been removed - no action on tap
        },
        onLongPress: () {
          if (!isSelectionMode) {
            _toggleSelectionMode();
            _toggleExpenseSelection(expense.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[300] : Colors.blue[100],
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? Border.all(color: Colors.blue[600]!, width: 2) : null,
          ),
          child: Row(
            children: [
              if (isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleExpenseSelection(expense.id),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                expense.categoryIcon, 
                size: 32, 
                color: Colors.black
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.category,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      expense.name,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    if (expense.description != null && expense.description!.isNotEmpty)
                      Text(
                        expense.description!,
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    Text(
                      _formatDate(expense.date),
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '₱${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateChart() {
    if (dateTotals.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Center(
          child: Text(
            'No data to display',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Sort dates for proper chronological order
    final sortedDates = dateTotals.keys.toList();
    sortedDates.sort((a, b) {
      // Parse dates for comparison
      final dateA = _parseDateFromString(a);
      final dateB = _parseDateFromString(b);
      return dateA.compareTo(dateB);
    });

    final amounts = sortedDates.map((date) => dateTotals[date]!).toList();
    final maxAmount = amounts.isNotEmpty ? amounts.reduce((a, b) => a > b ? a : b) : 0.0;
    final minAmount = amounts.isNotEmpty ? amounts.reduce((a, b) => a < b ? a : b) : 0.0;

    // Create line chart data points
    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), amounts[i]));
    }

    // Calculate better Y-axis range
    final range = maxAmount - minAmount;
    final yMin = minAmount > 0 ? (minAmount - range * 0.1).clamp(0.0, double.infinity) : 0.0;
    final yMax = maxAmount + range * 0.2;
    
    // Ensure we have valid data
    if (amounts.isEmpty || maxAmount == 0) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Center(
          child: Text(
            'No expense data available',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: LineChart(
        LineChartData(
        minY: yMin,
        maxY: yMax,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final date = sortedDates[touchedSpot.x.toInt()];
                final amount = amounts[touchedSpot.x.toInt()];
                final formattedDate = _formatDateForTooltip(date);
                return LineTooltipItem(
                  '$formattedDate\n₱${amount.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                  final date = sortedDates[value.toInt()];
                  
                  String displayText;
                  switch (selectedTab) {
                    case 0: // Today - show hour
                      displayText = date;
                      break;
                    case 1: // Weekly - show day abbreviation
                      displayText = _getDayOfWeek(date);
                      break;
                    case 2: // Monthly - show week number
                      displayText = date;
                      break;
                    case 3: // Annual - show month abbreviation
                      displayText = date.length > 3 ? date.substring(0, 3) : date;
                      break;
                    default:
                      displayText = _getDayOfWeek(date);
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      displayText,
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: selectedTab == 3 ? 8 : 10,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }
                return const Text('');
              },
              interval: sortedDates.length > 7 ? (sortedDates.length / 7).ceil().toDouble() : 1, // Dynamic interval based on data points
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                // Format amounts better
                String formattedAmount;
                if (value >= 1000) {
                  formattedAmount = '₱${(value / 1000).toStringAsFixed(1)}k';
                } else {
                  formattedAmount = '₱${value.toInt()}';
                }
                return Text(
                  formattedAmount,
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                );
              },
              reservedSize: 40,
              interval: (yMax - yMin) / 5 > 0 ? (yMax - yMin) / 5 : 1.0, // Show 5 Y-axis labels, minimum 1.0
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.blue[200]!,
            width: 1,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue[600]!,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: Colors.blue[600]!,
                  strokeWidth: 3,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue[600]!.withOpacity(0.3),
                  Colors.blue[600]!.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: (yMax - yMin) / 5 > 0 ? (yMax - yMin) / 5 : 1.0,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.blue[100]!,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.blue[100]!,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
      ),
      ),
    );
  }

  String _getDayOfWeek(String dateString) {
    // Handle different date formats
    if (dateString.contains(' ')) {
      // Format like "15 Oct" - parse and get day of week
      final date = _parseDateFromString(dateString);
      const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      return days[date.weekday - 1];
    } else {
      // For other formats, return as is
      return dateString;
    }
  }

  DateTime _parseDateFromString(String dateString) {
    // Parse date string like "15 Oct" to DateTime
    final parts = dateString.split(' ');
    if (parts.length != 2) return DateTime.now();
    
    final day = int.tryParse(parts[0]) ?? 1;
    final monthName = parts[1];
    
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final month = months.indexOf(monthName) + 1;
    final now = DateTime.now();
    
    return DateTime(now.year, month, day);
  }

  String _formatDateForTooltip(String dateString) {
    final date = _parseDateFromString(dateString);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}