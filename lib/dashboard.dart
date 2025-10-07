import 'package:flutter/material.dart';
import 'loginpage.dart';
import 'categoryclicked.dart';
import 'expense_records.dart'; // Add this import
import 'setexpense.dart'; // Add this import
import 'services/auth_service.dart';
import 'services/expense_service.dart';
import 'services/planned_expense_service.dart';
import 'models/user.dart';
import 'models/expense.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedTab = 3; // 0: Today, 1: Weekly, 2: Monthly, 3: Yearly
  User? currentUser;
  bool isLoading = true;

  // Add this at the top of your _DashboardPageState:
  final List<String> balanceOptions = ['Weekly', 'Monthly', 'Yearly'];
  int selectedBalanceOption = 0; // 0: Weekly, 1: Monthly, 2: Yearly

  double totalBalance = 0.00;
  double dailyExpense = 0.00;
  List<Expense> allExpenses = [];
  Map<String, List<Expense>> expensesByCategory = {};

  List<Map<String, dynamic>> categories = [];

  final List<IconData> availableIcons = [
    Icons.lunch_dining,
    Icons.videogame_asset,
    Icons.shopping_bag,
    Icons.flight,
    Icons.home,
    Icons.school,
    Icons.medical_services,
    Icons.pets,
    Icons.directions_car,
    Icons.coffee,
    Icons.book,
    Icons.sports_soccer,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning from other pages
    _refreshData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });
    
    await _loadCurrentUser();
    await _loadExpenseData();
    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUser();
    setState(() {
      currentUser = user;
    });
  }

  Future<void> _loadExpenseData() async {
    try {
      // Load all expenses
      allExpenses = await ExpenseService.getAllExpenses();
      
      // Group expenses by category
      expensesByCategory = await ExpenseService.getExpensesGroupedByCategory();
      
      // Calculate totals based on selected period
      await _calculateBalances();
      
      // Build categories list with real data
      _buildCategoriesList();
    } catch (e) {
      print('Error loading expense data: $e');
    }
  }

  Future<void> _calculateBalances() async {
    final now = DateTime.now();
    DateTime rangeStart;
    DateTime rangeEnd;
    
    switch (selectedBalanceOption) {
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

    // Use total planned budget for the selected period as Total Balance
    try {
      final plannedTotal = await PlannedExpenseService.getTotalBudgetForDateRange(
        startDate: rangeStart,
        endDate: rangeEnd,
      );
      final spentExpenses = await ExpenseService.getExpensesByDateRange(
        startDate: rangeStart,
        endDate: rangeEnd,
      );
      final spentTotal = spentExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
      totalBalance = (plannedTotal - spentTotal).clamp(0.0, double.infinity);
    } catch (_) {
      totalBalance = 0.0;
    }
    
    // Calculate daily expense (today's total)
    final todaysExpenses = await ExpenseService.getTodaysExpenses();
    dailyExpense = todaysExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  void _buildCategoriesList() {
    categories.clear();
    
    // Get unique categories from expenses
    final Set<String> uniqueCategories = allExpenses.map((e) => e.category).toSet();
    
    for (final category in uniqueCategories) {
      final categoryExpenses = expensesByCategory[category] ?? [];
      final totalAmount = categoryExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      final icon = categoryExpenses.isNotEmpty ? categoryExpenses.first.categoryIcon : Icons.category;
      
      categories.add({
        'icon': icon,
        'label': category,
        'amount': '-\$${totalAmount.toStringAsFixed(2)}',
      });
    }
    
    // Sort categories by amount (highest first)
    categories.sort((a, b) {
      final amountA = double.parse(a['amount'].toString().replaceAll(RegExp(r'[^0-9.-]'), ''));
      final amountB = double.parse(b['amount'].toString().replaceAll(RegExp(r'[^0-9.-]'), ''));
      return amountB.compareTo(amountA);
    });
  }

  String _getDateRangeText() {
    final now = DateTime.now();
    
    switch (selectedBalanceOption) {
      case 0: // Weekly
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';
      case 1: // Monthly
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        return '${_formatDate(monthStart)} - ${_formatDate(monthEnd)}';
      case 2: // Yearly
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _refreshData() async {
    await _loadExpenseData();
    setState(() {});
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showAddCategoryDialog() {
    String newLabel = '';
    IconData? selectedIcon = availableIcons[0];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.purple[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text('Add Category'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Category Name'),
                    onChanged: (value) {
                      newLabel = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: availableIcons.map((icon) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedIcon = icon;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: selectedIcon == icon
                              ? Colors.blue[200]
                              : Colors.grey[200],
                          child: Icon(icon, color: Colors.black),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newLabel.trim().isNotEmpty && selectedIcon != null) {
                  // Add the category to the list
                  setState(() {
                    categories.add({
                      'icon': selectedIcon,
                      'label': newLabel,
                      'amount': '-\$0.00',
                    });
                  });
                  Navigator.pop(context);
                  // Show a message that category was added
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Category "$newLabel" added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D5FEF)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseRecordsPage(),
            ),
          );
        },
        child: const Icon(Icons.bar_chart, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: const Color(0xFFDAD6F7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Set Expense icon on the left
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SetExpensePage(),
                    ),
                  );
                },
              ),
              // Chart button is now handled by floatingActionButton in the center
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Top Welcome + piggy + logout
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.savings,
                          size: 36, color: Color(0xFF5D5FEF)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome!',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54)),
                          Text(currentUser?.username ?? 'User',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.black),
                        tooltip: 'Refresh',
                        onPressed: _refreshData,
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.black),
                        tooltip: 'Logout',
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Balance Card with dynamic balance and date range
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 110, 131, 208),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Total Balance",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: balanceOptions[selectedBalanceOption],
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
                            selectedBalanceOption = balanceOptions.indexOf(newValue!);
                          });
                          await _calculateBalances();
                        },
                        items: balanceOptions.map((String option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "\$ ${totalBalance.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Daily Expenses",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "\$ ${dailyExpense.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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

            const SizedBox(height: 20),

            // Category title + add
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Category",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _showAddCategoryDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Category'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Category List (larger cards with clickable functionality restored)
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return GestureDetector(
                    onTap: () {
                      // ✅ Restored category click functionality
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryClickedPage(
                            icon: cat['icon'],
                            category: cat['label'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDAD6F7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(cat['icon'] as IconData,
                                  size: 34, color: Colors.black),
                              const SizedBox(width: 16),
                              Text(cat['label'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18)),
                            ],
                          ),
                          Text(cat['amount'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

}


