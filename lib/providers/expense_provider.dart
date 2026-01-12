import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
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
}
