import 'package:flutter/material.dart';

class ExpenseRecordsPage extends StatefulWidget {
  const ExpenseRecordsPage({super.key});

  @override
  State<ExpenseRecordsPage> createState() => _ExpenseRecordsPageState();
}

class _ExpenseRecordsPageState extends State<ExpenseRecordsPage> {
  int selectedTab = 1; // 0: Today, 1: Weekly, 2: Monthly

  // Dummy data
  final List<Map<String, dynamic>> expenses = [
    {
      'icon': Icons.lunch_dining,
      'category': 'Food',
      'desc': 'Buying Burger',
      'amount': 50.0,
      'date': 'Mon, 6 Oct 2025'
    },
    {
      'icon': Icons.videogame_asset,
      'category': 'Entertainment',
      'desc': 'Buying a Gift',
      'amount': 50.0,
      'date': 'Mon, 6 Oct 2025'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Records', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
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
                      selectedTab == 0
                          ? 'Oct 6 2025'
                          : selectedTab == 1
                              ? 'Oct 6 2025 - Oct 12 2025'
                              : 'Oct 1 2025 - Oct 31 2025',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '\$348.00',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Dummy chart (replace with fl_chart for real chart)
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[100]!, Colors.blue[300]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: CustomPaint(
                  painter: _DummyChartPainter(),
                ),
              ),
              const SizedBox(height: 18),
              // Day and total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    expenses[0]['date'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    '\$100.00',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Expense list
              ...expenses.map((exp) => _buildExpenseItem(exp)).toList(),
            ],
          ),
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
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItem(Map<String, dynamic> exp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(exp['icon'], size: 32, color: Colors.black),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exp['category'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('-${exp['desc']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
          Text('\$${exp['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

// Dummy chart painter for illustration only
class _DummyChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.2, size.width * 0.4, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.6, size.height * 1.1, size.width * 0.8, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.5, size.width, size.height * 0.7);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Optionally, draw axis lines or labels here
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}