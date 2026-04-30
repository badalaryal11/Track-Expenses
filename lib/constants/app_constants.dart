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
    'INR',
    'USD',
    'EUR',
    'GBP',
    'Other',
  ];

  static const accounts = [
    'Cash',
    'Bank Account',
    'Credit Card',
  ];

  static const List<IconData> availableIcons = [
    Icons.restaurant,
    Icons.local_cafe,
    Icons.shopping_bag,
    Icons.shopping_cart,
    Icons.home,
    Icons.pets,
    Icons.fitness_center,
    Icons.school,
    Icons.medical_services,
    Icons.child_care,
    Icons.phone_android,
    Icons.local_gas_station,
    Icons.electric_bolt,
    Icons.water_drop,
    Icons.wifi,
    Icons.subscriptions,
    Icons.card_giftcard,
    Icons.celebration,
    Icons.local_laundry_service,
    Icons.spa,
    Icons.sports_esports,
    Icons.music_note,
    Icons.book,
    Icons.local_parking,
    Icons.directions_bus,
    Icons.directions_car,
    Icons.local_taxi,
    Icons.train,
    Icons.local_hospital,
    Icons.storefront,
    Icons.handyman,
    Icons.savings,
    Icons.volunteer_activism,
    Icons.checkroom,
  ];

  static final List<Color> availableColors = [
    Colors.red,
    Colors.pink,
    Colors.deepOrange,
    Colors.orange,
    Colors.amber,
    Colors.yellow,
    Colors.lime,
    Colors.lightGreen,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.lightBlue,
    Colors.blue,
    Colors.indigo,
    Colors.deepPurple,
    Colors.purple,
    Colors.brown,
    Colors.blueGrey,
  ];
}
