import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/providers/expense_provider.dart';

class ExpenseList extends StatelessWidget {
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ExpenseList({super.key, this.physics, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final expenses = provider.expenses;

        if (expenses.isEmpty) {
          return Center(
            child: Text(
              'No expenses yet!',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.builder(
          physics: physics,
          shrinkWrap: shrinkWrap,
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final categoryColor = _getCategoryColor(expense.category);
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: categoryColor.withValues(alpha: 0.15),
                  child: Icon(
                    _getCategoryIcon(expense.category),
                    color: categoryColor,
                  ),
                ),
                title: Text(
                  expense.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(DateFormat.yMMMd().format(expense.date)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        provider.deleteExpense(expense);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Color getCategoryColor(String category) {
    return _getCategoryColorStatic(category);
  }

  static Color _getCategoryColorStatic(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'travel':
        return Colors.blue;
      case 'leisure':
        return Colors.purple;
      case 'work':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getCategoryColor(String category) {
    return _getCategoryColorStatic(category);
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'travel':
        return Icons.flight;
      case 'leisure':
        return Icons.movie;
      case 'work':
        return Icons.work;
      default:
        return Icons.attach_money;
    }
  }
}
