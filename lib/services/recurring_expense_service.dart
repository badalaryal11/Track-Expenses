import 'package:track_expenses/models/expense.dart';
import 'package:track_expenses/repositories/expense_repository.dart';
import 'package:uuid/uuid.dart';

class RecurringExpenseService {
  final ExpenseRepository repository;

  RecurringExpenseService(this.repository);

  /// Evaluates and processes any outstanding recurring templates, automatically
  /// registering new standard clones into the repository.
  /// Returns the list of newly created expenses (caller is responsible for
  /// adding them to its own in-memory list).
  Future<List<Expense>> processRecurringExpenses(List<Expense> currentExpenses) async {
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
            case 'Monthly':
              final targetMonth = nextDate.month + 1;
              final targetYear = targetMonth > 12 ? nextDate.year + 1 : nextDate.year;
              final normalizedMonth = targetMonth > 12 ? targetMonth - 12 : targetMonth;
              final daysInTargetMonth = DateTime(targetYear, normalizedMonth + 1, 0).day;
              final clampedDay = nextDate.day > daysInTargetMonth ? daysInTargetMonth : nextDate.day;
              nextDate = DateTime(targetYear, normalizedMonth, clampedDay);
              break;
            case 'Yearly':
              final targetYear = nextDate.year + 1;
              final daysInTargetMonth = DateTime(targetYear, nextDate.month + 1, 0).day;
              final clampedDay = nextDate.day > daysInTargetMonth ? daysInTargetMonth : nextDate.day;
              nextDate = DateTime(targetYear, nextDate.month, clampedDay);
              break;
            default: nextDate = today.add(const Duration(days: 1)); break;
          }
          expense.nextRecurrenceDate = nextDate;
          await repository.saveExpense(expense);
        }
      }
    }
    return newExpenses;
  }
}

