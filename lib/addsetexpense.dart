import 'package:flutter/material.dart';
import 'services/planned_expense_service.dart';
import 'services/category_service.dart';
import 'models/planned_expense.dart';

class ChecklistItem {
  String name;
  double amount;
  bool checked;
  ChecklistItem({required this.name, required this.amount, this.checked = false});
}

class AddSetExpensePage extends StatefulWidget {
  final Map<String, dynamic>? initialExpense;

  const AddSetExpensePage({super.key, this.initialExpense});

  @override
  State<AddSetExpensePage> createState() => _AddSetExpensePageState();
}

class _AddSetExpensePageState extends State<AddSetExpensePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedCategory;
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isEditing = false;

  // Checklist
  bool _showChecklist = false;
  List<ChecklistItem> _checklist = [];
  final TextEditingController _checklistNameController = TextEditingController();
  final TextEditingController _checklistAmountController = TextEditingController();

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.initialExpense != null) {
      _isEditing = true;
      _nameController.text = widget.initialExpense!['name'] ?? '';
      _amountController.text = widget.initialExpense!['amount'] ?? '';
      _selectedCategory = widget.initialExpense!['category'];
      _selectedDate = DateTime.tryParse(widget.initialExpense!['date'] ?? '');
      _notesController.text = widget.initialExpense!['notes'] ?? '';
      // Load checklist from initialExpense if present
      if (widget.initialExpense!['items'] != null) {
        final items = widget.initialExpense!['items'] as List;
        _checklist = items.map((e) => ChecklistItem(
          name: e['name'],
          amount: (e['cost'] as num).toDouble(),
          checked: e['isPurchased'] ?? false,
        )).toList();
        if (_checklist.isNotEmpty) _showChecklist = true;
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.getCategoryNames();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      // Fallback to default categories if loading fails
      setState(() {
        _categories = ['Food', 'Transport', 'Bills', 'Shopping', 'Other'];
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _checklistNameController.dispose();
    _checklistAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100), // Allow future dates for planned expenses
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _savePlannedExpense() async {
    if (_nameController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      // Prepare checklist items for backend if needed
      // final items = _showChecklist
      //     ? _checklist
      //         .map((e) => {
      //               'name': e.name,
      //               'cost': e.amount,
      //               'isPurchased': e.checked,
      //               'category': _selectedCategory, // connect to main category
      //             })
      //         .toList()
      //     : [];

      if (_isEditing && widget.initialExpense != null) {
        // Convert checklist items to PlannedExpenseItem objects
        final items = _showChecklist
            ? _checklist.map((item) => PlannedExpenseItem(
                  id: DateTime.now().microsecondsSinceEpoch.toString() + item.name.hashCode.toString(),
                  name: item.name,
                  cost: item.amount,
                  category: _selectedCategory!,
                  isPurchased: item.checked,
                )).toList()
            : <PlannedExpenseItem>[];

        final result = await PlannedExpenseService.updatePlannedExpense(
          id: widget.initialExpense!['id']!,
          name: _nameController.text,
          category: _selectedCategory!,
          cost: amount,
          startDate: _selectedDate!,
          endDate: _selectedDate!,
          totalBudget: amount,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          categories: [_selectedCategory!],
          items: items,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Updated'),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          ),
        );
        if (result['success'] == true) Navigator.pop(context, result);
        return;
      }

      // Convert checklist items to PlannedExpenseItem objects
      final items = _showChecklist
          ? _checklist.map((item) => PlannedExpenseItem(
                id: DateTime.now().microsecondsSinceEpoch.toString() + item.name.hashCode.toString(),
                name: item.name,
                cost: item.amount,
                category: _selectedCategory!,
                isPurchased: item.checked,
              )).toList()
          : <PlannedExpenseItem>[];

      final created = await PlannedExpenseService.createPlannedExpense(
        name: _nameController.text,
        category: _selectedCategory!,
        cost: amount,
        startDate: _selectedDate!,
        endDate: _selectedDate!,
        totalBudget: amount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        categories: [_selectedCategory!],
        items: items,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(created['message'] ?? 'Saved'),
          backgroundColor: created['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (created['success'] == true) Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePlannedExpense() async {
    if (widget.initialExpense == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await PlannedExpenseService.deletePlannedExpense(widget.initialExpense!['id']!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Deleted'),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (result['success'] == true) Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildChecklist() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Total: ₱${widget.initialExpense != null ? double.parse(widget.initialExpense!['amount'] ?? '0').toStringAsFixed(2) : '0.00'}", 
                       style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
                  Text("Remaining: ₱${_calculateRemainingAmount().toStringAsFixed(2)}", 
                       style: TextStyle(fontWeight: FontWeight.bold, color: _calculateRemainingAmount() > 0 ? Colors.green[700] : Colors.red[700])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._checklist.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Row(
              children: [
                // Undo button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _checklist.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.undo,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.name, style: const TextStyle(fontSize: 15)),
                ),
                Text("₱${item.amount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15)),
              ],
            );
          }),
          Row(
            children: [
              const Text("Add more?", style: TextStyle(fontWeight: FontWeight.w500)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Add Checklist Item"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _checklistNameController,
                            decoration: const InputDecoration(labelText: "Name"),
                          ),
                          TextField(
                            controller: _checklistAmountController,
                            decoration: const InputDecoration(labelText: "Amount"),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            _checklistNameController.clear();
                            _checklistAmountController.clear();
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final name = _checklistNameController.text.trim();
                            final amount = double.tryParse(_checklistAmountController.text) ?? 0.0;
                            final mainAmount = double.tryParse(_amountController.text) ?? 0.0;
                            final currentTotal = _checklist.fold(0.0, (sum, item) => sum + item.amount);
                            
                            if (name.isEmpty || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter valid name and amount'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            if (currentTotal + amount > mainAmount) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Checklist total (${(currentTotal + amount).toStringAsFixed(2)}) cannot exceed main amount (${mainAmount.toStringAsFixed(2)})'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            setState(() {
                              _checklist.add(ChecklistItem(name: name, amount: amount));
                            });
                            _checklistNameController.clear();
                            _checklistAmountController.clear();
                            Navigator.pop(context);
                          },
                          child: const Text("Add"),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showChecklist = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                ),
                child: const Text("Finish", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit planned payment' : 'Add planned payment',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              onPressed: _isLoading ? null : _deletePlannedExpense,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and Amount fields
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name:',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount:',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Category dropdown
            const SizedBox(height: 8),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: _categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val;
                });
              },
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            const SizedBox(height: 18),
            // Date picker
            Row(
              children: [
                const Text('Date:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black26)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedDate == null
                                ? ''
                                : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Notes field
            const Text('Notes:', style: TextStyle(fontWeight: FontWeight.w500)),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 18),
            // Checklist button
            Row(
              children: [
                const Text('Make this into a checklist?', style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _showChecklist = !_showChecklist;
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.lightBlue[200],
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      _showChecklist ? Icons.remove : Icons.add,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            if (_showChecklist) _buildChecklist(),
            const SizedBox(height: 24),
            // Save button
            Center(
              child: SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePlannedExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Colors.black),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  double _calculateRemainingAmount() {
    final originalAmount = widget.initialExpense != null ? double.parse(widget.initialExpense!['amount'] ?? '0') : 0.0;
    final checklistTotal = _checklist.fold(0.0, (sum, item) => sum + item.amount);
    return originalAmount - checklistTotal;
  }
}