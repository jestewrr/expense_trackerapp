class PlannedExpenseItem {
  final String id;
  final String name;
  final double cost;
  final bool isPurchased;
  final DateTime? purchasedAt;
  final String category; // category this item belongs to

  PlannedExpenseItem({
    required this.id,
    required this.name,
    required this.cost,
    this.isPurchased = false,
    this.purchasedAt,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cost': cost,
      'isPurchased': isPurchased,
      'purchasedAt': purchasedAt?.toIso8601String(),
      'category': category,
    };
  }

  factory PlannedExpenseItem.fromJson(Map<String, dynamic> json) {
    return PlannedExpenseItem(
      id: json['id'],
      name: json['name'],
      cost: (json['cost'] as num).toDouble(),
      isPurchased: json['isPurchased'] ?? false,
      purchasedAt: json['purchasedAt'] != null ? DateTime.parse(json['purchasedAt']) : null,
      category: json['category'] ?? '',
    );
  }

  PlannedExpenseItem copyWith({
    String? id,
    String? name,
    double? cost,
    bool? isPurchased,
    DateTime? purchasedAt,
    String? category,
  }) {
    return PlannedExpenseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      cost: cost ?? this.cost,
      isPurchased: isPurchased ?? this.isPurchased,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      category: category ?? this.category,
    );
  }
}

class PlannedExpense {
  final String id;
  final String name;
  final String category;
  final double cost;
  final DateTime startDate;
  final DateTime endDate;
  final double totalBudget;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PlannedExpenseItem> items;
  final List<String> categories;
  final String? notes; // <-- Add this line

  PlannedExpense({
    required this.id,
    required this.name,
    required this.category,
    required this.cost,
    required this.startDate,
    required this.endDate,
    required this.totalBudget,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.categories = const [],
    this.notes, // <-- Add this line
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'cost': cost,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalBudget': totalBudget,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
      'categories': categories,
      'notes': notes, // <-- Add this line
    };
  }

  factory PlannedExpense.fromJson(Map<String, dynamic> json) {
    return PlannedExpense(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      cost: (json['cost'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalBudget: (json['totalBudget'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      items: (json['items'] as List?)?.map((e) => PlannedExpenseItem.fromJson(e)).toList() ?? const [],
      categories: (json['categories'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      notes: json['notes'], // <-- Add this line
    );
  }

  PlannedExpense copyWith({
    String? id,
    String? name,
    String? category,
    double? cost,
    DateTime? startDate,
    DateTime? endDate,
    double? totalBudget,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PlannedExpenseItem>? items,
    List<String>? categories,
    String? notes, // <-- Add this line
  }) {
    return PlannedExpense(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      cost: cost ?? this.cost,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalBudget: totalBudget ?? this.totalBudget,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      categories: categories ?? this.categories,
      notes: notes ?? this.notes, // <-- Add this line
    );
  }

  // Calculate the remaining amount after deducting checked items
  double get remainingAmount {
    double checkedAmount = items
        .where((item) => item.isPurchased)
        .fold(0.0, (sum, item) => sum + item.cost);
    return cost - checkedAmount;
  }

  // Calculate the total amount of checked items
  double get checkedAmount {
    return items
        .where((item) => item.isPurchased)
        .fold(0.0, (sum, item) => sum + item.cost);
  }
}

final plannedExpense = PlannedExpense(
  id: 'some-id',
  name: 'Test',
  category: 'Food',
  cost: 100.0,
  startDate: DateTime.now(),
  endDate: DateTime.now(),
  totalBudget: 100.0,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  items: [
    PlannedExpenseItem(
      id: 'item-id',
      name: 'Burger',
      cost: 50.0,
      isPurchased: false,
      purchasedAt: null,
      category: 'Food',
    ),
  ],
  categories: ['Food'],
  notes: 'This is a note',
);
