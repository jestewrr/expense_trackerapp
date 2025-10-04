import 'package:flutter/material.dart';
import 'addsetexpense.dart'; // Add this import

class ViewSetExpensePage extends StatelessWidget {
  final String dateRange;
  final double totalBudget;
  final List<Map<String, dynamic>> expenses;
  final String sortBy;

  const ViewSetExpensePage({
    super.key,
    required this.dateRange,
    required this.totalBudget,
    required this.expenses,
    this.sortBy = "Highest",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateRange,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.lightBlue[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    "Total Budget: \$${totalBudget.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("List", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      const Text("Sort by: ", style: TextStyle(fontSize: 15)),
                      Text(sortBy, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...expenses.map((exp) => Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(exp['icon'], size: 32, color: Colors.black),
                        const SizedBox(width: 10),
                        Text(
                          exp['category'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const Spacer(),
                        Text(
                          "\$${exp['total'].toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...exp['items'].map<Widget>((item) => Row(
                      children: [
                        Checkbox(
                          value: false,
                          onChanged: null,
                        ),
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "\$${item['cost'].toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    )),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        shape: const CircleBorder(),
        onPressed: () async {
          // Go back to AddSetExpensePage, passing current data if needed
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddSetExpensePage(),
              // You can pass current expenses if you want to prefill
            ),
          );
          // Optionally handle result here (e.g., refresh view)
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        height: 48,
        color: Colors.blue[100],
      ),
    );
  }
}