import 'package:flutter/material.dart';
import 'loginpage.dart';
import 'categoryclicked.dart';
import 'expense_records.dart';
import 'setexpense.dart';
import 'notifications.dart';
import 'services/firebase_auth_service.dart';
import 'services/expense_service.dart';
import 'services/planned_expense_service.dart';
import 'services/category_service.dart';
import 'services/notification_service.dart';
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

  // Add this at the top of your _DashboardPageState:
  final List<String> expenseOptions = ['Weekly', 'Monthly', 'Yearly'];
  int selectedExpenseOption = 0; // 0: Weekly, 1: Monthly, 2: Yearly

  double totalExpense = 0.00;
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
    // Initialize real-time notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.initializeRealTimeNotifications(context);
      // Check for notifications on startup - prioritize overdue expenses
      _checkOverdueExpensesOnStartup();
    });
  }

  // Check for overdue expenses immediately on app startup
  Future<void> _checkOverdueExpensesOnStartup() async {
    // Small delay to ensure UI is fully loaded
    await Future.delayed(const Duration(milliseconds: 500));
    await NotificationService.showOverdueExpensesNotification(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning from other pages
    _refreshData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
      });
      
      await _loadCurrentUser();
      await _loadExpenseData();
      
      setState(() {
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
      });
    }
  }
  

  Future<void> _loadCurrentUser() async {
    try {
      final firebaseAuth = FirebaseAuthService();
      final currentUserId = firebaseAuth.currentUserId;
      
      if (currentUserId != null) {
        final userData = await firebaseAuth.getUserData(currentUserId);
        if (userData != null) {
          final user = User(
            id: userData['uid'] ?? currentUserId,
            username: userData['username'] ?? 'User',
            email: userData['email'] ?? '',
            password: '', // Don't store password in User model
            createdAt: userData['createdAt'] != null 
                ? (userData['createdAt'] as dynamic).toDate() 
                : DateTime.now(),
          );
          setState(() {
            currentUser = user;
          });
        }
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadExpenseData() async {
    try {
      // Load all expenses
      allExpenses = await ExpenseService.getAllExpenses();
      
      // Group expenses by category
      expensesByCategory = await ExpenseService.getExpensesGroupedByCategory();
      
      // Calculate totals based on selected period
      await _calculateExpenses();
      
      // Build categories list with real data
      await _buildCategoriesList();
    } catch (e) {
      print('Error loading expense data: $e');
    }
  }

  Future<void> _calculateExpenses() async {
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

    // Calculate total expense for the selected period
    try {
      final spentExpenses = await ExpenseService.getExpensesByDateRange(
        startDate: rangeStart,
        endDate: rangeEnd,
      );
      totalExpense = spentExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    } catch (_) {
      totalExpense = 0.0;
    }
    
    // Calculate daily expense (today's total including planned expenses)
    await _calculateDailyExpense();
  }

  Future<void> _calculateDailyExpense() async {
    try {
      // Get today's regular expenses
      final todaysExpenses = await ExpenseService.getTodaysExpenses();
      final regularExpenseTotal = todaysExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      
      // Get today's planned expenses (items that were purchased today)
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final plannedExpenses = await PlannedExpenseService.getPlannedExpensesByDateRange(
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      // Calculate total from planned expenses that were purchased today
      double plannedExpenseTotal = 0.0;
      for (final plannedExpense in plannedExpenses) {
        for (final item in plannedExpense.items) {
          if (item.isPurchased && item.purchasedAt != null) {
            final purchasedDate = item.purchasedAt!;
            if (purchasedDate.isAfter(startOfDay) && purchasedDate.isBefore(endOfDay)) {
              plannedExpenseTotal += item.cost;
            }
          }
        }
      }
      
      dailyExpense = regularExpenseTotal + plannedExpenseTotal;
    } catch (_) {
      dailyExpense = 0.0;
    }
  }

  Future<void> _buildCategoriesList() async {
    try {
      // Update category amounts based on current expenses
      await CategoryService.updateCategoryAmounts();
      
      // Get categories from service
      final serviceCategories = await CategoryService.getAllCategories();
      
      categories.clear();
      
      for (final category in serviceCategories) {
        final categoryName = category['label'] as String;
        final categoryExpenses = expensesByCategory[categoryName] ?? [];
        final totalAmount = categoryExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
        final iconCodePoint = category['icon'] as int;
        final icon = IconData(
          iconCodePoint,
          fontFamily: category['iconFamily'] as String? ?? 'MaterialIcons',
        );
        
        categories.add({
          'id': category['id'],
          'icon': icon,
          'label': categoryName,
          'amount': '₱${totalAmount.toStringAsFixed(2)}',
          'isDefault': category['isDefault'] ?? false,
        });
      }
      
      // Sort categories by amount (highest first)
      categories.sort((a, b) {
        final amountA = double.parse(a['amount'].toString().replaceAll(RegExp(r'[^0-9.-]'), ''));
        final amountB = double.parse(b['amount'].toString().replaceAll(RegExp(r'[^0-9.-]'), ''));
        return amountB.compareTo(amountA);
      });
    } catch (e) {
      print('Error building categories list: $e');
    }
  }

  String _getDateRangeText() {
    final now = DateTime.now();
    
    switch (selectedExpenseOption) {
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
    return '${months[date.month - 1]}. ${date.day}, ${date.year}';
  }

  Future<void> _refreshData() async {
    await _loadExpenseData();
    setState(() {});
  }

  Future<void> _logout() async {
    final FirebaseAuthService firebaseAuth = FirebaseAuthService();
    await firebaseAuth.signOut();
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
          backgroundColor: Colors.blue[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Add Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: UnderlineInputBorder(),
                    ),
                    onChanged: (value) {
                      newLabel = value;
                    },
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableIcons.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedIcon = icon;
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[200] : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue[200]!,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.black,
                            size: 24,
                          ),
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
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.blue[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newLabel.trim().isNotEmpty && selectedIcon != null) {
                  // Add the category to the service
                  final result = await CategoryService.addCategory(
                    label: newLabel,
                    icon: selectedIcon!,
                  );
                  
                  if (result['success']) {
                    // Reload categories from service
                    await _buildCategoriesList();
                    setState(() {});
                    Navigator.pop(context);
                    // Show a message that category was added
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Category "$newLabel" added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    // Show error message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message']),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a category name and select an icon'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.blue[50],
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
        color: Colors.blue[100],
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
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
                      Image.asset(
                        "lib/images/pig.png",
                        height: 36,
                        width: 36,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome!',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54)),
                          Text(
                            (currentUser?.username ?? 'User'),
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
                gradient: LinearGradient(
                  colors: [Colors.blue[100]!, Colors.blue[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          "Total Expense",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: DropdownButton<String>(
                          value: expenseOptions[selectedExpenseOption],
                          dropdownColor: Colors.blue[100],
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                          underline: const SizedBox(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          onChanged: (String? newValue) async {
                            setState(() {
                              selectedExpenseOption = expenseOptions.indexOf(newValue!);
                            });
                            await _calculateExpenses();
                          },
                          items: expenseOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(option),
                              ),
                            );
                          }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "₱${totalExpense.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Daily Expenses",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "₱${dailyExpense.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.blue[700],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _getDateRangeText(),
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                  ElevatedButton.icon(
                    onPressed: _showAddCategoryDialog,
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Add Category', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
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
                          child: Row(
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
                        ),
                        Row(
                          children: [
                            Text(cat['amount'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ],
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
