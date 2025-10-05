import 'package:flutter/material.dart';
import 'services/planned_expense_service.dart';

class AddSetExpensePage extends StatefulWidget {
  final Map<String, String>? initialExpense;

  const AddSetExpensePage({super.key, this.initialExpense});

  @override
  State<AddSetExpensePage> createState() => _AddSetExpensePageState();
}

class _AddSetExpensePageState extends State<AddSetExpensePage> {
  final TextEditingController _budgetController = TextEditingController();
  final List<TextEditingController> _categoryControllers = [];
  DateTime? _startDate;
  DateTime? _endDate;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialExpense != null) {
      _isEditing = true;
      _budgetController.text = widget.initialExpense!['budget'] ?? '';
      _categoryControllers.add(
        TextEditingController(text: widget.initialExpense!['category'] ?? ''),
      );
      _startDate = DateTime.tryParse(widget.initialExpense!['startDate'] ?? '');
      _endDate = DateTime.tryParse(widget.initialExpense!['endDate'] ?? '');
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    for (final c in _categoryControllers) {
      c.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _savePlannedExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a total budget'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_categoryControllers.isEmpty || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one category and select start/end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final budget = double.tryParse(_budgetController.text) ?? 0.0;

      if (_isEditing && widget.initialExpense != null) {
        final result = await PlannedExpenseService.updatePlannedExpense(
          id: widget.initialExpense!['id']!,
          name: _categoryControllers.first.text,
          category: _categoryControllers.first.text,
          cost: 0.0,
          startDate: _startDate!,
          endDate: _endDate!,
          totalBudget: budget,
          items: const [],
          categories: _categoryControllers.map((c) => c.text).toList(),
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

      final created = await PlannedExpenseService.createPlannedExpense(
        name: _categoryControllers.first.text,
        category: _categoryControllers.first.text,
        cost: 0.0,
        startDate: _startDate!,
        endDate: _endDate!,
        totalBudget: budget,
        items: const [],
        categories: _categoryControllers.map((c) => c.text).toList(),
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

  Widget _buildInputField({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

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
          'Planned Expense',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
            child: Column(
              children: [
                _buildInputField(
                  child: Row(
                    children: [
                      const Text(
                        'Total budget:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a budget';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '1,000',
                            hintStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildInputField(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Categories:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _categoryControllers.add(TextEditingController());
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Category'),
                          ),
                        ],
                      ),
                      if (_categoryControllers.isEmpty)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('No categories yet', style: TextStyle(color: Colors.black54)),
                        )
                      else
                        ...List.generate(_categoryControllers.length, (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _categoryControllers[i],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter category';
                                        }
                                        return null;
                                      },
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Category name',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _categoryControllers.removeAt(i);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
                _buildInputField(
                  child: Row(
                    children: [
                      const Text('Start date:', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _pickDate(isStart: true),
                      ),
                      Text(
                        _startDate == null
                            ? ''
                            : '${_startDate!.month}-${_startDate!.day}-${_startDate!.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                _buildInputField(
                  child: Row(
                    children: [
                      const Text('End date:', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _pickDate(isStart: false),
                      ),
                      Text(
                        _endDate == null
                            ? ''
                            : '${_endDate!.month}-${_endDate!.day}-${_endDate!.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePlannedExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 48,
        color: Colors.blue[100],
      ),
    );
  }
}