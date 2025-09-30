import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.savings, size: 40, color: Colors.lightBlue[300]),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Welcome!', style: TextStyle(fontSize: 16)),
                      Text('John Doe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: const [
                  Text('Total Balance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 8),
                  Text('\$ 0.00', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
                  SizedBox(height: 8),
                  Text('Daily Expenses', style: TextStyle(color: Colors.white, fontSize: 14)),
                  Text('\$ 400.00', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Expense Records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text('View all', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _expenseItem(Icons.lunch_dining, 'Food', '-\$100.00'),
                  _expenseItem(Icons.videogame_asset, 'Entertainment', '-\$100.00'),
                  _expenseItem(Icons.shopping_bag, 'Shopping', '-\$100.00'),
                  _expenseItem(Icons.flight, 'Travel', '-\$100.00'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.edit, size: 32, color: Colors.black),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                  Icon(Icons.notifications, size: 32, color: Colors.black),
                ],
              ),
            ),
            Container(
              height: 40,
              color: Colors.blue[100],
            ),
          ],
        ),
      ),
    );
  }

  Widget _expenseItem(IconData icon, String label, String amount) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.black),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}