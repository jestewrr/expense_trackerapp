import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/expense_service.dart';
import 'models/expense.dart';
import 'edit_delete_setexpense.dart';
import 'categooryaddexpense.dart';

class ExpenseRecordsPage extends StatefulWidget {
  const ExpenseRecordsPage({super.key});

  @override
  State<ExpenseRecordsPage> createState() => _ExpenseRecordsPageState();
}

class _ExpenseRecordsPageState extends State<ExpenseRecordsPage> {
  int selectedTab = 1; // 0: Today, 1: Weekly, 2: Monthly
  bool isLoading = true;
  bool isSelectionMode = false;
  Set<String> selectedExpenseIds = {};
  String searchQuery = '';
  String sortBy = 'date'; // date, amount, category, name
  
  List<Expense> allExpenses = [];
  List<Expense> filteredExpenses = [];
  double totalAmount = 0.0;
  Map<String, double> categoryTotals = {};
  Map<String, double> dateTotals = {};

  @override
  void initState() {
    super.initState();
    _loadExpenseData();
  }

  Future<void> _loadExpenseData() async {
    setState(() {
      isLoading = true;
    });

    try {
      allExpenses = await ExpenseService.getAllExpenses();
      await _filterExpenses();
    } catch (e) {
      // Log error for debugging purposes
      debugPrint('Error loading expenses: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _filterExpenses() async {
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
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      expenses = expenses.where((expense) {
        return expense.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
               expense.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
               (expense.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
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

    // Calculate date totals for chart
    Map<String, double> dateTotals = {};
    for (final expense in expenses) {
      final dateKey = _formatDateForChart(expense.date);
      dateTotals[dateKey] = (dateTotals[dateKey] ?? 0.0) + expense.amount;
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
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateForChart(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  Future<void> _refreshData() async {
    await _loadExpenseData();
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Expenses'),
        content: Text('Are you sure you want to delete ${selectedExpenseIds.length} expense(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        isLoading = true;
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
      builder: (context) => AlertDialog(
        title: const Text('Search Expenses'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by name, category, or description...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
            _filterExpenses();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                searchQuery = '';
              });
              _filterExpenses();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort by'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('date', 'Date (Newest First)'),
            _buildSortOption('amount', 'Amount (Highest First)'),
            _buildSortOption('category', 'Category (A-Z)'),
            _buildSortOption('name', 'Name (A-Z)'),
          ],
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
        });
        _filterExpenses();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D5FEF)),
          ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTab('Today', 0),
                    const SizedBox(width: 12),
                    _buildTab('Weekly', 1),
                    const SizedBox(width: 12),
                    _buildTab('Monthly', 2),
                  ],
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
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[100]!, Colors.blue[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                        : _buildDateChart(),
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
            backgroundColor: const Color(0xFF5D5FEF),
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.lightBlue[200] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.lightBlue[200]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.black,
            fontSize: 16,
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
          builder: (context) => AlertDialog(
            title: const Text('Delete Expense'),
            content: const Text('Are you sure you want to delete this expense?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
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
          } else {
            // Navigate to edit/delete page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditDeleteSetExpensePage(expense: expense),
              ),
            ).then((_) {
              // Refresh data when returning from edit page
              _refreshData();
            });
          }
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
              Icon(expense.categoryIcon, size: 32, color: Colors.black),
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
    if (dateTotals.isEmpty) return const SizedBox();

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

    // Create line chart data points
    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), amounts[i]));
    }

    return LineChart(
      LineChartData(
        maxY: maxAmount * 1.2, // Add some padding above the max value
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final date = sortedDates[touchedSpot.x.toInt()];
                final amount = amounts[touchedSpot.x.toInt()];
                return LineTooltipItem(
                  '$date\n₱${amount.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
                  // Show day of week for better readability
                  final dayOfWeek = _getDayOfWeek(date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dayOfWeek,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '₱${value.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.white,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: Colors.white.withOpacity(0.8),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxAmount / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  String _getDayOfWeek(String dateString) {
    final date = _parseDateFromString(dateString);
    // Custom abbreviations: Mon, Tue, Wed, Thu, Fri, Sat, Sun
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[date.weekday - 1];
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
}