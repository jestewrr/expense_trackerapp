import 'package:flutter/material.dart';
import 'addexpense.dart';
import 'loginpage.dart';
import 'categoryclicked.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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

      // FAB (circular + shadow)
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(), // ensures perfect circle
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddExpensePage()));
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom bar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: const Color(0xFFDAD6F7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.black),
                onPressed: () {
                  // Edit button functionality
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black),
                onPressed: () {
                  // Notifications functionality
                },
              ),
            ],
          ),
        ),
      ),

      // Body
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

            // Balance Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding:
                  const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF8EA7FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Total Balance",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("\$ ${totalBalance.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Daily Expenses",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text("\$ ${dailyExpense.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
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
}
