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
    
    // Add listener to amount controller to update remaining amount
    _amountController.addListener(() {
      setState(() {});
    });
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

  double _calculateRemainingAmount() {
    final mainAmount = double.tryParse(_amountController.text) ?? 0.0;
    final checkedAmount = _checklist
        .where((item) => item.checked)
        .fold(0.0, (sum, item) => sum + item.amount);
    return mainAmount - checkedAmount;
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Checklist Items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Checklist items display
          ..._checklist.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Delete button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _checklist.removeAt(index);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name, 
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "₱${item.amount.toStringAsFixed(2)}", 
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          // Add more button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Add more items?",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: [
                            Icon(Icons.add_circle, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            const Text("Add Checklist Item"),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _checklistNameController,
                              decoration: InputDecoration(
                                labelText: "Item Name",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: Colors.blue[200]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: Colors.blue[200]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.label_outline),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _checklistAmountController,
                              decoration: InputDecoration(
                                labelText: "Amount (₱)",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: Colors.blue[200]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: Colors.blue[200]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.attach_money),
                                prefixText: '₱ ',
                              ),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Add Item"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add Item"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.blue[700],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
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
            // Planned Payment Summary (Top Section) - Enhanced design
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Expense Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.blue[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.blue[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Amount (₱)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.blue[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.blue[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                            prefixText: '₱ ',
                            prefixStyle: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Show remaining amount if checklist is active
            if (_showChecklist && _checklist.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.blue[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining Amount:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '₱${_calculateRemainingAmount().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _calculateRemainingAmount() > 0 ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Category dropdown
            const SizedBox(height: 16),
            Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: _categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.blue[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.blue[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            // Date picker
            Text(
              'Date',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _selectedDate == null ? Colors.grey[600] : Colors.blue[700],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blue[600],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Notes field
            Text(
              'Notes (Optional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.blue[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.blue[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: 'Add any additional notes...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            // Checklist toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.checklist,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Make this into a checklist?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  Switch(
                    value: _showChecklist,
                    onChanged: (value) {
                      setState(() {
                        _showChecklist = value;
                      });
                    },
                    activeColor: Colors.blue[400],
                    activeTrackColor: Colors.blue[200],
                  ),
                ],
              ),
            ),
            if (_showChecklist) _buildChecklist(),
            const SizedBox(height: 24),
            // Save button
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePlannedExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.blue.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Save Planned Expense',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
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

}