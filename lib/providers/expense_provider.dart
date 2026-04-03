import 'package:flutter/foundation.dart';
import 'package:track_expenses/models/expense.dart';
import 'package:track_expenses/repositories/expense_repository.dart';
import 'package:track_expenses/services/export_service.dart';
import 'package:track_expenses/services/recurring_expense_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();
  late final RecurringExpenseService _recurringService;
  late final ExportService _exportService;

  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  ExpenseProvider() {
    _recurringService = RecurringExpenseService(_repository);
    _exportService = ExportService();
  }

  Future<void> init() async {
    await _repository.init();
    _expenses = _repository.getAllExpenses();

    _sortExpenses();
    bool hasUpdates = await _recurringService.processRecurringExpenses(_expenses);
    if (hasUpdates) {
      _sortExpenses();
    }
    notifyListeners();
  }

  void _sortExpenses() {
    _expenses.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addExpense(Expense expense) async {
    await _repository.addExpense(expense);
    _expenses.add(expense);
    _sortExpenses();
    notifyListeners();
  }

  Future<void> deleteExpense(Expense expense) async {
    await _repository.deleteExpense(expense);
    _expenses.remove(expense);
    notifyListeners();
  }

  Future<void> updateExpense(Expense oldExpense, Expense updatedExpense) async {
    await _repository.deleteExpense(oldExpense);
    _expenses.remove(oldExpense);
    await _repository.addExpense(updatedExpense);
    _expenses.add(updatedExpense);
    _sortExpenses();
    notifyListeners();
  }

  double get totalSpending {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // --- Aggregation Logic ---

  // Daily Stats: Last 7 days (or current week).
  // Map of <WeekDay Index (1-7), Total Amount> for the current week.
  Map<int, double> getDailyStats({String? currency}) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final Map<int, double> stats = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

    if (_expenses.isEmpty) return stats;

    for (var expense in _expenses) {
      if (currency != null && expense.currency != currency) continue;

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

  // --- Helper for Unique Currencies ---
  List<String> get uniqueCurrencies {
    return _expenses.map((e) => e.currency).toSet().toList();
  }

  // --- Total Calculation Logic ---

  double calculateDailyTotal({String? currency}) {
    final now = DateTime.now();
    return _expenses
        .where((e) {
          final isSameDate =
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day;
          if (currency != null) {
            return isSameDate && e.currency == currency;
          }
          return isSameDate;
        })
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double calculateWeeklyTotal({String? currency}) {
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
          final isWithinWeek =
              e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              e.date.isBefore(end.add(const Duration(seconds: 1)));

          if (currency != null) {
            return isWithinWeek && e.currency == currency;
          }
          return isWithinWeek;
        })
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double calculateMonthlyTotal(DateTime targetDate, {String? currency}) {
    return _expenses
        .where((e) {
          final isSameMonth =
              e.date.year == targetDate.year &&
              e.date.month == targetDate.month;

          if (currency != null) {
            return isSameMonth && e.currency == currency;
          }
          return isSameMonth;
        })
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double calculateYearlyTotal(int targetYear, {String? currency}) {
    return _expenses
        .where((e) {
          final isSameYear = e.date.year == targetYear;
          if (currency != null) {
            return isSameYear && e.currency == currency;
          }
          return isSameYear;
        })
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Returns spending totals grouped by category for the given view/currency.
  Map<String, double> getCategoryTotals({
    required String view,
    DateTime? selectedDate,
    String? currency,
  }) {
    final now = DateTime.now();
    final Map<String, double> totals = {};

    for (var expense in _expenses) {
      // Filter by currency
      if (currency != null && expense.currency != currency) continue;

      bool include = false;
      if (view == 'Daily') {
        include = expense.date.year == now.year &&
            expense.date.month == now.month &&
            expense.date.day == now.day;
      } else if (view == 'Weekly') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final end = DateTime(
          endOfWeek.year,
          endOfWeek.month,
          endOfWeek.day,
          23,
          59,
          59,
        );
        include =
            expense.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            expense.date.isBefore(end.add(const Duration(seconds: 1)));
      } else if (view == 'Monthly') {
        final target = selectedDate ?? now;
        include =
            expense.date.year == target.year &&
            expense.date.month == target.month;
      }

      if (include) {
        totals[expense.category] =
            (totals[expense.category] ?? 0) + expense.amount;
      }
    }

    return totals;
  }

  /// Returns daily spending broken down by day of the month for the given month and currency.
  Map<int, double> getDailySpendingForMonth(DateTime monthDate, {String? currency}) {
    final Map<int, double> spendingByDay = {};
    
    // Find the number of days in the month
    int daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    
    // Initialize all days to 0
    for(int i = 1; i <= daysInMonth; i++) {
        spendingByDay[i] = 0.0;
    }

    for (var expense in _expenses) {
      if (expense.date.year == monthDate.year && expense.date.month == monthDate.month) {
        if (currency == null || expense.currency == currency) {
          int day = expense.date.day;
          spendingByDay[day] = (spendingByDay[day] ?? 0) + expense.amount;
        }
      }
    }
    return spendingByDay;
  }

  // --- Data Export Logic ---

  Future<void> exportExpenses() async {
    await _exportService.exportExpenses(_expenses);
  }
}
