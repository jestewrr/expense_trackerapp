import 'package:flutter/material.dart';

class CategoryIcons {
  // Consistent icon mapping for all categories
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & drinks':
        return Icons.lunch_dining;
      case 'transport':
      case 'travel':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt_long;
      case 'shopping':
        return Icons.shopping_bag;
      case 'games':
        return Icons.videogame_asset;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'pets':
        return Icons.pets;
      case 'coffee':
        return Icons.coffee;
      case 'book':
        return Icons.book;
      case 'sports':
        return Icons.sports_soccer;
      case 'flight':
        return Icons.flight;
      case 'utilities':
        return Icons.electrical_services;
      case 'groceries':
        return Icons.shopping_cart;
      case 'clothing':
        return Icons.checkroom;
      case 'fuel':
        return Icons.local_gas_station;
      case 'maintenance':
        return Icons.build;
      case 'insurance':
        return Icons.security;
      case 'subscription':
        return Icons.subscriptions;
      case 'gift':
        return Icons.card_giftcard;
      case 'donation':
        return Icons.volunteer_activism;
      case 'savings':
        return Icons.savings;
      case 'investment':
        return Icons.trending_up;
      case 'other':
      default:
        return Icons.category;
    }
  }

  // Get all available categories with their icons
  static List<Map<String, dynamic>> getAvailableCategories() {
    return [
      {'name': 'Food', 'icon': Icons.lunch_dining},
      {'name': 'Transport', 'icon': Icons.directions_car},
      {'name': 'Bills', 'icon': Icons.receipt_long},
      {'name': 'Shopping', 'icon': Icons.shopping_bag},
      {'name': 'Games', 'icon': Icons.videogame_asset},
      {'name': 'Entertainment', 'icon': Icons.movie},
      {'name': 'Health', 'icon': Icons.medical_services},
      {'name': 'Education', 'icon': Icons.school},
      {'name': 'Home', 'icon': Icons.home},
      {'name': 'Pets', 'icon': Icons.pets},
      {'name': 'Coffee', 'icon': Icons.coffee},
      {'name': 'Book', 'icon': Icons.book},
      {'name': 'Sports', 'icon': Icons.sports_soccer},
      {'name': 'Flight', 'icon': Icons.flight},
      {'name': 'Utilities', 'icon': Icons.electrical_services},
      {'name': 'Groceries', 'icon': Icons.shopping_cart},
      {'name': 'Clothing', 'icon': Icons.checkroom},
      {'name': 'Fuel', 'icon': Icons.local_gas_station},
      {'name': 'Maintenance', 'icon': Icons.build},
      {'name': 'Insurance', 'icon': Icons.security},
      {'name': 'Subscription', 'icon': Icons.subscriptions},
      {'name': 'Gift', 'icon': Icons.card_giftcard},
      {'name': 'Donation', 'icon': Icons.volunteer_activism},
      {'name': 'Savings', 'icon': Icons.savings},
      {'name': 'Investment', 'icon': Icons.trending_up},
      {'name': 'Other', 'icon': Icons.category},
    ];
  }
}
