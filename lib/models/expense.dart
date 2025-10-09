import 'package:flutter/material.dart';

class Expense {
  final String id;
  final String name;
  final double amount;
  final String category;
  final IconData categoryIcon;
  final DateTime date;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.categoryIcon,
    required this.date,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'categoryIcon': categoryIcon.codePoint,
      'date': date.toIso8601String(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      name: json['name'],
      amount: json['amount'].toDouble(),
      category: json['category'],
      categoryIcon: IconData(json['categoryIcon'] as int, fontFamily: 'MaterialIcons'),
      date: DateTime.parse(json['date']),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Expense copyWith({
    String? id,
    String? name,
    double? amount,
    String? category,
    IconData? categoryIcon,
    DateTime? date,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      date: date ?? this.date,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
