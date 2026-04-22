import 'package:flutter/material.dart';

class AppCategory {
  final String name;
  final IconData icon;
  final Color color;

  const AppCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class AppConstants {
  static const quotes = [
    'Financial freedom starts with small steps!',
    'A penny saved is a penny earned.',
    'Track today, thrive tomorrow.',
    'Every expense tracked is a step toward control.',
    'Budgeting isn\'t about limiting — it\'s about freedom.',
    'Small leaks sink great ships. Track everything!',
    'Know where your money goes, and make it work for you.',
    'The habit of saving is itself an education.',
    'Don\'t save what is left after spending — spend what is left after saving.',
    'Financial awareness is the first step to wealth.',
    'Your future self will thank you for tracking today.',
    'Wealth is not about having a lot — it\'s about managing wisely.',
  ];

  static const dashboardViews = ['Daily', 'Weekly', 'Monthly'];

  static const List<AppCategory> categories = [
    AppCategory(name: 'Food', icon: Icons.fastfood, color: Colors.orange),
    AppCategory(name: 'Travel', icon: Icons.flight, color: Colors.blue),
    AppCategory(name: 'Leisure', icon: Icons.movie, color: Colors.purple),
    AppCategory(name: 'Work', icon: Icons.work, color: Colors.green),
    AppCategory(name: 'Other', icon: Icons.attach_money, color: Colors.grey),
  ];

  static List<String> get expenseCategories => categories.map((c) => c.name).toList();

  static Color getCategoryColor(String categoryName) {
    final category = categories.firstWhere(
      (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => const AppCategory(name: 'Other', icon: Icons.attach_money, color: Colors.grey),
    );
    return category.color;
  }

  static IconData getCategoryIcon(String categoryName) {
    final category = categories.firstWhere(
      (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => const AppCategory(name: 'Other', icon: Icons.attach_money, color: Colors.grey),
    );
    return category.icon;
  }

  static const currencies = [
    'NPR',
    'RS',
    'USD',
    'EUR',
    'GBP',
    'Other',
  ];
}
