import 'package:track_expenses/models/expense.dart';
import 'package:track_expenses/repositories/expense_repository.dart';
import 'package:uuid/uuid.dart';

class RecurringExpenseService {
  final ExpenseRepository repository;

  RecurringExpenseService(this.repository);

  /// Evaluates and processes any outstanding recurring templates, automatically registering new standard clones into the repository.
  Future<bool> processRecurringExpenses(List<Expense> currentExpenses) async {
    bool hasUpdates = false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<Expense> newExpenses = [];

    for (var expense in currentExpenses) {
      if (expense.isRecurring && expense.nextRecurrenceDate != null) {
        while (!expense.nextRecurrenceDate!.isAfter(today)) {
          // Create a new regular expense clone for missed cycles
          final newExpense = Expense(
            id: const Uuid().v4(),
            title: expense.title,
            amount: expense.amount,
            date: expense.nextRecurrenceDate!,
            category: expense.category,
            currency: expense.currency,
            isRecurring: false, 
            recurrenceInterval: 'None',
          );
          
          await repository.addExpense(newExpense);
          newExpenses.add(newExpense);

          // Update the parent's nextRecurrenceDate
          DateTime nextDate = expense.nextRecurrenceDate!;
          switch (expense.recurrenceInterval) {
            case 'Daily': nextDate = nextDate.add(const Duration(days: 1)); break;
            case 'Weekly': nextDate = nextDate.add(const Duration(days: 7)); break;
            case 'Monthly': nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day); break;
            case 'Yearly': nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day); break;
            default: nextDate = today.add(const Duration(days: 1)); break; // fallback
          }
          expense.nextRecurrenceDate = nextDate;
          await repository.saveExpense(expense);
          hasUpdates = true;
        }
      }
    }
    currentExpenses.addAll(newExpenses);
    return hasUpdates;
  }
}
