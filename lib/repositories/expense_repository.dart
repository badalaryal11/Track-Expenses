import 'package:hive/hive.dart';
import 'package:track_expenses/models/expense.dart';

class ExpenseRepository {
  late Box<Expense> _expenseBox;

  /// Opens the Hive box and runs necessary schema migrations automatically.
  Future<void> init() async {
    _expenseBox = await Hive.openBox<Expense>('expenses');
    await _runMigrations();
  }

  Future<void> _runMigrations() async {
    final expenses = getAllExpenses();
    final toMigrate = expenses.where((e) => e.currency == 'Rs').toList();
    for (final expense in toMigrate) {
      final updated = Expense(
        id: expense.id,
        title: expense.title,
        amount: expense.amount,
        date: expense.date,
        category: expense.category,
        currency: 'RS',
        isRecurring: expense.isRecurring,
        recurrenceInterval: expense.recurrenceInterval,
        nextRecurrenceDate: expense.nextRecurrenceDate,
      );
      await expense.delete();
      await _expenseBox.add(updated);
    }
  }

  /// Retrieves all expenses uniformly mapping from Hive key values.
  List<Expense> getAllExpenses() {
    return _expenseBox.values.toList();
  }

  /// Adds a completely new expense block to internal storage.
  Future<void> addExpense(Expense expense) async {
    await _expenseBox.add(expense);
  }

  /// Replaces exactly the underlying object pointing to [oldExpense.key].
  Future<void> updateExpense(Expense oldExpense, Expense newExpense) async {
    final key = oldExpense.key;
    if (key != null) {
      await _expenseBox.put(key, newExpense);
    }
  }

  /// Deletes natively tied Hive object using Hive extension method.
  Future<void> deleteExpense(Expense expense) async {
    await expense.delete();
  }

  /// Overrides exactly the current mapping with internal mutate bindings safely without a full Put replacement block.
  Future<void> saveExpense(Expense expense) async {
    await expense.save();
  }

  /// Clears all expenses from the database.
  Future<void> clearAll() async {
    await _expenseBox.clear();
  }
}
