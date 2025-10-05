import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'addsetexpense.dart' as addset;
import 'services/planned_expense_service.dart';
import 'models/planned_expense.dart';

class ViewSetExpensePage extends StatefulWidget {
  final String? plannedExpenseId; // Optional ID for specific planned expense
  final String sortBy;

  const ViewSetExpensePage({
    super.key,
    this.plannedExpenseId,
    this.sortBy = "Highest",
  });

  @override
  State<ViewSetExpensePage> createState() => _ViewSetExpensePageState();
}

class _ViewSetExpensePageState extends State<ViewSetExpensePage> {
  // Track which items are checked (not used in simplified view)
  Map<String, bool> checkedItems = {};
  bool isLoading = true;
  final Logger _logger = Logger();
  
  // Real data
  PlannedExpense? plannedExpense;
  List<PlannedExpense> plannedExpenses = [];
  List<PlannedExpense> filteredPlannedExpenses = [];
  double totalBudget = 0.0;
  String dateRange = '';
  String currentSortBy = 'Highest';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (widget.plannedExpenseId != null) {
        // Load specific planned expense
        final pe = await PlannedExpenseService.getPlannedExpenseById(widget.plannedExpenseId!);
        if (pe != null) {
          plannedExpense = pe;
          plannedExpenses = [pe];
          totalBudget = pe.totalBudget;
          dateRange = '${_formatDate(pe.startDate)} - ${_formatDate(pe.endDate)}';
        }
      } else {
        // Load all planned expenses for current month
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        plannedExpenses = await PlannedExpenseService.getPlannedExpensesByDateRange(
          startDate: startOfMonth,
          endDate: endOfMonth,
        );
        if (plannedExpenses.isNotEmpty) {
          totalBudget = plannedExpenses.first.totalBudget; // assume same budget across entries
          dateRange = '${_formatDate(plannedExpenses.first.startDate)} - ${_formatDate(plannedExpenses.first.endDate)}';
        }
      }

      // Initialize filtered list
      filteredPlannedExpenses = List.from(plannedExpenses);
      _sortExpenses();
    } catch (e) {
      _logger.e('Error loading planned expense data: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _sortExpenses() {
    setState(() {
      filteredPlannedExpenses = List.from(plannedExpenses);

      if (searchQuery.isNotEmpty) {
        filteredPlannedExpenses = filteredPlannedExpenses.where((pe) {
          return pe.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 pe.category.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }

      switch (currentSortBy) {
        case 'Highest':
          filteredPlannedExpenses.sort((a, b) => b.cost.compareTo(a.cost));
          break;
        case 'Lowest':
          filteredPlannedExpenses.sort((a, b) => a.cost.compareTo(b.cost));
          break;
        case 'Category':
          filteredPlannedExpenses.sort((a, b) => a.category.compareTo(b.category));
          break;
        case 'Items':
          // Not applicable; fall back to name length
          filteredPlannedExpenses.sort((a, b) => a.name.length.compareTo(b.name.length));
          break;
      }
    });
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort by'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOption('Highest', 'Amount (High to Low)'),
              _buildSortOption('Lowest', 'Amount (Low to High)'),
              _buildSortOption('Category', 'Category Name'),
              _buildSortOption('Items', 'Number of Items'),
            ],
          ),
        ),
    );
  }

  Widget _buildSortOption(String value, String label) {
    final bool isSelected = currentSortBy == value;
    return ListTile(
      title: Text(label),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? const Color(0xFF5D5FEF) : Colors.grey,
      ),
      onTap: () {
        setState(() {
          currentSortBy = value;
        });
        _sortExpenses();
        Navigator.pop(context);
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search categories or items...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
            _sortExpenses();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                searchQuery = '';
              });
              _sortExpenses();
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

  Future<void> _toggleItem(PlannedExpense pe, PlannedExpenseItem item, bool value) async {
    setState(() {
      isLoading = true;
    });
    final result = await PlannedExpenseService.toggleItemPurchased(
      plannedExpenseId: pe.id,
      itemId: item.id,
      isPurchased: value,
    );
    if (!mounted) return;
    if (!(result['success'] == true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to update item'), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated'), backgroundColor: Colors.green),
      );
    }
    await _loadData();
  }

  double _getTotalCheckedAmount() {
    return 0.0; // Placeholder as items are not checkable in this simplified listing
  }

  Future<void> _showAddItemDialog(PlannedExpense pe, String category) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add item to $category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Item name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (name.isEmpty || amount <= 0) {
                return;
              }
              Navigator.pop(context);
              final result = await PlannedExpenseService.addItem(
                plannedExpenseId: pe.id,
                name: name,
                cost: amount,
                category: category,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Failed to add item'),
                  backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                ),
              );
              await _loadData();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D5FEF)),
          ),
        ),
      );
    }

    if (plannedExpenses.isEmpty) {
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No planned expenses found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a planned expense to see it here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          shape: const CircleBorder(),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const addset.AddSetExpensePage(),
              ),
            );
            if (result != null && mounted) {
              _loadData();
            }
          },
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      );
    }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
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
                  child: Column(
                    children: [
                      Text(
                        "Total Budget: \$${totalBudget.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Selected: \$${_getTotalCheckedAmount().toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
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
                      IconButton(
                        icon: const Icon(Icons.search, size: 20),
                        onPressed: _showSearchDialog,
                        tooltip: 'Search',
                      ),
                      const Text("Sort by: ", style: TextStyle(fontSize: 15)),
                      GestureDetector(
                        onTap: _showSortDialog,
                        child: Row(
                          children: [
                            Text(currentSortBy, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filteredPlannedExpenses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filter',
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
                ...filteredPlannedExpenses.map((pe) => Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_note, size: 32, color: Colors.black),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                          pe.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        ),
                        Text(
                          "\$${pe.cost.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.black54),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => addset.AddSetExpensePage(
                                    initialExpense: {
                                      'id': pe.id,
                                      'name': pe.name,
                                      'category': pe.category,
                                      'cost': pe.cost.toString(),
                                      'startDate': pe.startDate.toIso8601String(),
                                      'endDate': pe.endDate.toIso8601String(),
                                      'budget': pe.totalBudget.toString(),
                                    },
                                  ),
                                ),
                              );
                              if (!context.mounted) return;
                              if (result != null) {
                                await _loadData();
                              }
                            } else if (value == 'delete') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Planned Expense'),
                                  content: Text('Are you sure you want to delete "${pe.name}"?'),
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
                                final result = await PlannedExpenseService.deletePlannedExpense(pe.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message']),
                                    backgroundColor: result['success'] ? Colors.green : Colors.red,
                                  ),
                                );
                                await _loadData();
                              }
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(height: 10),
                    // Render each category as its own blue card
                    ...List.generate((pe.categories.isEmpty ? 1 : pe.categories.length), (index) {
                      final String category = pe.categories.isEmpty ? pe.category : pe.categories[index];
                      final List<PlannedExpenseItem> catItems = pe.items.where((it) => (it.category.isNotEmpty ? it.category : pe.category) == category).toList();
                      final double catTotal = catItems.fold<double>(0.0, (sum, it) => sum + it.cost);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.category, color: Colors.black),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${index + 1}. $category',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Text(
                                  '\$${catTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _showAddItemDialog(pe, category),
                                  tooltip: 'Add item',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (catItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                                child: Text('No items', style: TextStyle(color: Colors.black54)),
                              )
                            else
                              ...catItems.map((it) => Row(
                                children: [
                                  Checkbox(
                                    value: it.isPurchased,
                                    onChanged: (val) => _toggleItem(pe, it, val ?? false),
                                  ),
                                  Expanded(
                                    child: Text(
                                      it.name,
                                      style: TextStyle(
                                        decoration: it.isPurchased ? TextDecoration.lineThrough : TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  Text('\$${it.cost.toStringAsFixed(2)}'),
                                ],
                              )),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              )),
            ],
          ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        shape: const CircleBorder(),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const addset.AddSetExpensePage(),
            ),
          );
          if (!context.mounted) return;
          if (result != null) {
            await _loadData();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Planned expense updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
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