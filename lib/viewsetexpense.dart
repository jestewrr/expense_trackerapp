import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'addsetexpense.dart' as addset;
import 'services/planned_expense_service.dart';
import 'models/planned_expense.dart';
import 'utils/category_icons.dart';
import 'utils/responsive_dialog.dart';

class ViewSetExpensePage extends StatefulWidget {
  final String? plannedExpenseId;

  const ViewSetExpensePage({
    super.key,
    this.plannedExpenseId,
  });

  @override
  State<ViewSetExpensePage> createState() => _ViewSetExpensePageState();
}

class _ViewSetExpensePageState extends State<ViewSetExpensePage> {
  final Logger _logger = Logger();
  
  PlannedExpense? plannedExpense;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
    });

    try {
      if (widget.plannedExpenseId != null) {
        final pe = await PlannedExpenseService.getPlannedExpenseById(widget.plannedExpenseId!);
        if (pe != null) {
          plannedExpense = pe;
        }
      }
    } catch (e) {
      _logger.e('Error loading planned expense data: $e');
    }

    setState(() {
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]}. ${date.day}, ${date.year}';
  }


  IconData _getCategoryIcon(String category) {
    return CategoryIcons.getCategoryIcon(category);
  }

  @override
  Widget build(BuildContext context) {
    if (plannedExpense == null) {
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
            "Details",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: false,
        ),
        body: const Center(
          child: Text('Loading...'),
        ),
      );
    }

    if (plannedExpense == null) {
      return Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: AppBar(
          backgroundColor: Colors.blue[50],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Details",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: false,
        ),
        body: const Center(
          child: Text(
            'Planned expense not found',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      );
    }

    final exp = plannedExpense!;

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "List",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            // Main expense card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expense name
                  Text(
                    exp.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category, icon, amount, and date in one row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getCategoryIcon(exp.category),
                          size: 24,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          exp.category,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              // Show different amounts based on whether it's a checklist or simple planned expense
                              exp.items.isNotEmpty 
                                ? "₱${exp.checkedAmount.toStringAsFixed(2)}"  // Checklist: show purchased amount
                                : "₱${exp.cost.toStringAsFixed(2)}",         // Simple: show total cost
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            if (exp.items.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                "of ₱${exp.cost.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 2),
                              Text(
                                "Total Planned",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Start Date
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                                size: 14,
                              color: Colors.blue[600],
                            ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                              'Start: ${_formatDate(exp.startDate)}',
                              style: TextStyle(
                                    fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                      const SizedBox(width: 6),
                      // End Date
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event,
                                size: 14,
                              color: Colors.blue[600],
                            ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                              'End: ${_formatDate(exp.endDate)}',
                              style: TextStyle(
                                    fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Checklist details
                  if (exp.items.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1)
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
                                color: Colors.black,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Checklist Items",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...exp.items.map((item) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: item.isPurchased ? Colors.green[50] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.isPurchased ? Colors.green[200]! : Colors.grey[200]!,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () async {
                                if (!item.isPurchased) {
                                  // Show confirmation dialog when checking an item
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => ResponsiveDialog.createConfirmationDialog(
                                      context: context,
                                      title: 'Confirm Purchase',
                                      message: 'Have you purchased "${item.name}" for ₱${item.cost.toStringAsFixed(2)}?\n\nThis will mark the item as purchased and update your remaining budget.',
                                      confirmText: 'Confirm Purchase',
                                      cancelText: 'Cancel',
                                      icon: Icons.shopping_cart_checkout,
                                      iconColor: Colors.green[600],
                                      confirmColor: Colors.green[600],
                                      onConfirm: () => Navigator.pop(context, true),
                                      onCancel: () => Navigator.pop(context, false),
                                    ),
                                  );
                                  
                                  if (confirmed != true) return;
                                }
                                
                                // Optimistically update UI first
                                setState(() {
                                  for (var i = 0; i < plannedExpense!.items.length; i++) {
                                    if (plannedExpense!.items[i].id == item.id) {
                                      plannedExpense!.items[i] = plannedExpense!.items[i].copyWith(
                                        isPurchased: !item.isPurchased,
                                        purchasedAt: !item.isPurchased ? DateTime.now() : null,
                                      );
                                      break;
                                    }
                                  }
                                });
                                
                                // Then update in database
                                final result = await PlannedExpenseService.toggleItemPurchased(
                                  plannedExpenseId: exp.id,
                                  itemId: item.id,
                                  isPurchased: !item.isPurchased,
                                );
                                
                                if (result['success']) {
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            item.isPurchased ? Icons.undo : Icons.check_circle,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item.isPurchased 
                                                  ? 'Item unchecked - removed from purchases'
                                                  : 'Item marked as purchased!',
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.visible,
                                              softWrap: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: item.isPurchased ? Colors.orange[600] : Colors.green[600],
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                  
                                  // Reload the data to reflect changes
                                  await _loadData();
                                  setState(() {});
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error, color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              result['message'],
                                              overflow: TextOverflow.visible,
                                              softWrap: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.red[600],
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                children: [
                                  // Checkbox
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: item.isPurchased ? Colors.green[600] : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: item.isPurchased ? Colors.green[600]! : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      item.isPurchased ? Icons.check : Icons.check_box_outline_blank,
                                      size: 16,
                                      color: item.isPurchased ? Colors.white : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Item name
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: item.isPurchased ? Colors.green[700] : Colors.black87,
                                        decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // Item amount
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: item.isPurchased ? Colors.green[100] : Colors.blue[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "₱${item.cost.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: item.isPurchased ? Colors.green[700] : Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Action buttons row
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Edit button
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => addset.AddSetExpensePage(
                                initialExpense: {
                                  'id': exp.id,
                                  'name': exp.name,
                                  'category': exp.category,
                                  'amount': exp.cost.toString(),
                                  'date': exp.startDate.toIso8601String(),
                                  'notes': exp.notes ?? '',
                                  'items': exp.items.map((item) => {
                                    'name': item.name,
                                    'cost': item.cost,
                                    'isPurchased': item.isPurchased,
                                  }).toList(),
                                },
                              ),
                            ),
                          );
                          if (result != null) {
                            await _loadData();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      // Checkmark button
                      GestureDetector(
                        onTap: () async {
                          // Check if all items are purchased
                          final allItemsPurchased = exp.items.every((item) => item.isPurchased);
                          final purchasedItemsCount = exp.items.where((item) => item.isPurchased).length;
                          final totalItemsCount = exp.items.length;
                          
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => ResponsiveDialog.createScrollableDialog(
                              context: context,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.shopping_cart,
                                            color: Colors.green[600],
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Mark as Completed',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Content
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Are you sure you want to mark this planned expense as completed?',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Items summary
                                        if (exp.items.isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.green[200]!),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.checklist,
                                                      color: Colors.green[600],
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Items ($purchasedItemsCount/$totalItemsCount completed):',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16,
                                                        color: Colors.green[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                ...exp.items.take(5).map((item) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 8),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        item.isPurchased ? Icons.check_circle : Icons.radio_button_unchecked,
                                                        color: item.isPurchased ? Colors.green[600] : Colors.grey[400],
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          item.name,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: item.isPurchased ? Colors.green[700] : Colors.black87,
                                                            fontWeight: item.isPurchased ? FontWeight.w500 : FontWeight.normal,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        '₱${item.cost.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: item.isPurchased ? Colors.green[600] : Colors.grey[600],
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                                if (exp.items.length > 5) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '... and ${exp.items.length - 5} more items',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green[200],
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Total:',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Colors.green[800],
                                                        ),
                                                      ),
                                                      Text(
                                                        '₱${exp.items.fold(0.0, (sum, item) => sum + item.cost).toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Colors.green[800],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ] else ...[
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.green[200]!),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.check,
                                                  color: Colors.green[600],
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        exp.name,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 16,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      Text(
                                                        '₱${exp.cost.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          color: Colors.green[600],
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        
                                        const SizedBox(height: 16),
                                        Text(
                                          'This will add it to your expense records.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Actions
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green[600],
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'Mark Complete',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          
                          if (confirmed == true) {
                            // Show loading dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => ResponsiveDialog.createDialog(
                                context: context,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                                        strokeWidth: 3,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Completing expense...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                            
                            try {
                              // DO NOT record any additional expenses here
                              // Individual checked items are already recorded when they were checked
                              // We only need to remove the planned expense from the list
                              
                              // Remove from planned expenses
                              await PlannedExpenseService.deletePlannedExpense(exp.id);
                              
                              if (mounted) {
                                Navigator.pop(context); // Close loading dialog
                                Navigator.pop(context); // Go back to previous screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Planned expense completed! Only checked items were recorded.',
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.visible,
                                            softWrap: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.pop(context); // Close loading dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Error completing expense: ${e.toString()}',
                                            overflow: TextOverflow.visible,
                                            softWrap: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.red[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      // Delete button
                      GestureDetector(
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => ResponsiveDialog.createConfirmationDialog(
                              context: context,
                              title: 'Delete Planned Expense',
                              message: 'Are you sure you want to delete "${exp.name}"?\n\nThis action cannot be undone. All data will be permanently deleted.',
                              confirmText: 'Delete',
                              cancelText: 'Cancel',
                              icon: Icons.delete_forever,
                              iconColor: Colors.red[600],
                              confirmColor: Colors.red[600],
                              onConfirm: () => Navigator.pop(context, true),
                              onCancel: () => Navigator.pop(context, false),
                            ),
                          );
                          if (confirmed == true) {
                            try {
                              await PlannedExpenseService.deletePlannedExpense(exp.id);
                              if (mounted) {
                                Navigator.pop(context); // Go back to previous screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Planned expense deleted successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error deleting expense: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Add bottom padding
          ],
        ),
      ),
    );
  }
}