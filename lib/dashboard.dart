import 'package:flutter/material.dart';
import 'loginpage.dart';
import 'categoryclicked.dart';
import 'expense_records.dart'; // Add this import
import 'setexpense.dart'; // Add this import

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedTab = 3; // 0: Today, 1: Weekly, 2: Monthly, 3: Yearly

  // Add this at the top of your _DashboardPageState:
  final List<String> balanceOptions = ['Weekly', 'Monthly', 'Yearly'];
  int selectedBalanceOption = 0; // 0: Weekly, 1: Monthly, 2: Yearly

  final List<double> balances = [400.00, 1200.00, 15000.00];
  final List<String> dateRanges = [
    'Oct 6, 2025 - Oct 12, 2025',
    'Oct 1, 2025 - Oct 31, 2025',
    'Jan 1, 2025 - Dec 31, 2025'
  ];

  double totalBalance = 0.00;
  double dailyExpense = 400.00;

  List<Map<String, dynamic>> categories = [
    {'icon': Icons.lunch_dining, 'label': 'Food', 'amount': '-\$100.00'},
    {'icon': Icons.videogame_asset, 'label': 'Entertainment', 'amount': '-\$100.00'},
    {'icon': Icons.shopping_bag, 'label': 'Shopping', 'amount': '-\$100.00'},
    {'icon': Icons.flight, 'label': 'Travel', 'amount': '-\$100.00'},
  ];

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
              onPressed: () {
                if (newLabel.trim().isNotEmpty && selectedIcon != null) {
                  setState(() {
                    categories.add({
                      'icon': selectedIcon,
                      'label': newLabel,
                      'amount': '-\$0.00',
                    });
                  });
                  Navigator.pop(context);
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
      body: SafeArea(
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
                        children: const [
                          Text('Welcome!',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54)),
                          Text('John Doe',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.black),
                    tooltip: 'Logout',
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
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
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedBalanceOption = balanceOptions.indexOf(newValue!);
                          });
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
                    "\$ ${balances[selectedBalanceOption].toStringAsFixed(2)}",
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
                      dateRanges[selectedBalanceOption],
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
    );
  }

  Widget _buildTab(String label, int index) {
    final bool selected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.lightBlue[200] : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.lightBlue[200]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
