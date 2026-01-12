import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:track_expenses/models/expense.dart';

class ExpenseProvider with ChangeNotifier {
  late Box<Expense> _expenseBox;
  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  Future<void> init() async {
    // Determine which box to open. We'll simply use one box for now.
    _expenseBox = await Hive.openBox<Expense>('expenses');
    _expenses = _expenseBox.values.toList();
    _sortExpenses();
    notifyListeners();
  }

  void _sortExpenses() {
    _expenses.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addExpense(Expense expense) async {
    // Use the expense.id as key if you want stable keys,
    // or let Hive auto-increment.
    // Since we have an ID in the model, let's just add it.
    // Hive.add() returns an int key.
    // We can also use put(key, value).
    await _expenseBox.add(expense);
    _expenses.add(expense);
    _sortExpenses();
    notifyListeners();
  }

  Future<void> deleteExpense(Expense expense) async {
    await expense
        .delete(); // Deletes from the box using the key stored in the HiveObject
    _expenses.remove(expense);
    notifyListeners();
  }

  double get totalSpending {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // --- Aggregation Logic ---

  // Daily Stats: Last 7 days (or current week).
  // Let's implement reasonable "Daily" statistics:
  // Map of <WeekDay Index (1-7), Total Amount> for the current week.
  Map<int, double> getDailyStats() {
    final now = DateTime.now();
    // Validate if expenses are empty
    if (_expenses.isEmpty) return {};

    // Find the start of the current week (Monday)
    // weekday 1 = Mon, 7 = Sun
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final Map<int, double> stats = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

    for (var expense in _expenses) {
      // Check if expense is within the current week (ignoring time components for start/end comparison roughly)
      // A safer way is to truncate dates to YYYY-MM-DD for comparison
      if (_isSameDayOrAfter(expense.date, startOfWeek) &&
          _isSameDayOrBefore(expense.date, endOfWeek)) {
        stats[expense.date.weekday] =
            (stats[expense.date.weekday] ?? 0) + expense.amount;
      }
    }
    return stats;
  }

  // Weekly Stats: Weeks of the current month
  // Map of <Week Number (1-5), Total Amount>
  Map<int, double> getWeeklyStats() {
    final now = DateTime.now();
    if (_expenses.isEmpty) return {};

    final Map<int, double> stats = {};

    for (var expense in _expenses) {
      if (expense.date.month == now.month && expense.date.year == now.year) {
        // Calculate week number within the month roughly
        // Week 1: Days 1-7, Week 2: 8-14, etc.
        int weekNum = ((expense.date.day - 1) / 7).floor() + 1;
        stats[weekNum] = (stats[weekNum] ?? 0) + expense.amount;
      }
    }
    return stats;
  }

  // Yearly Stats: Months of the current year
  // Map of <Month Index (1-12), Total Amount>
  Map<int, double> getYearlyStats() {
    final now = DateTime.now();
    if (_expenses.isEmpty) return {};

    final Map<int, double> stats = {};
    for (int i = 1; i <= 12; i++) {
      stats[i] = 0;
    }

    for (var expense in _expenses) {
      if (expense.date.year == now.year) {
        stats[expense.date.month] =
            (stats[expense.date.month] ?? 0) + expense.amount;
      }
    }
    return stats;
  }

  // Helper for date comparison (removes time component)
  bool _isSameDayOrAfter(DateTime d1, DateTime d2) {
    final date1 = DateTime(d1.year, d1.month, d1.day);
    final date2 = DateTime(d2.year, d2.month, d2.day);
    return date1.isAtSameMomentAs(date2) || date1.isAfter(date2);
  }

  bool _isSameDayOrBefore(DateTime d1, DateTime d2) {
    final date1 = DateTime(d1.year, d1.month, d1.day);
    final date2 = DateTime(d2.year, d2.month, d2.day);
    return date1.isAtSameMomentAs(date2) || date1.isBefore(date2);
  }

  // --- Total Calculation Logic ---

  double calculateDailyTotal() {
    final now = DateTime.now();
    return _expenses
        .where((e) {
          return e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day;
        })
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double calculateWeeklyTotal() {
    final now = DateTime.now();
    // Week starting Monday
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    // Normalize dates to remove time component for accurate comparison
    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final end = DateTime(
      endOfWeek.year,
      endOfWeek.month,
      endOfWeek.day,
      23,
      59,
      59,
    );

    return _expenses
        .where((e) {
          return e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              e.date.isBefore(end.add(const Duration(seconds: 1)));
        })
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double calculateMonthlyTotal([DateTime? date]) {
    final targetDate = date ?? DateTime.now();
    return _expenses
        .where((e) {
          return e.date.year == targetDate.year &&
              e.date.month == targetDate.month;
        })
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double calculateYearlyTotal([int? year]) {
    final targetYear = year ?? DateTime.now().year;
    return _expenses
        .where((e) {
          return e.date.year == targetYear;
        })
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // --- Data Export Logic ---

  Future<void> exportExpenses() async {
    List<List<dynamic>> rows = [];

    // Add Header
    rows.add(["Date", "Title", "Amount", "Category", "Currency"]);

    // Add Data
    for (var expense in _expenses) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.title,
        expense.amount,
        expense.category,
        expense.currency,
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/expenses_export.csv";
    final file = File(path);
    await file.writeAsString(csvData);

    // ignore: deprecated_member_use
    await Share.shareXFiles([
      XFile(path),
    ], text: 'Here is your expense report.');
  }
}
