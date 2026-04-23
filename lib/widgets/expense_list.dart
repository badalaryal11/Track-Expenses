import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:track_expenses/screens/add_expense_screen.dart';
import 'package:track_expenses/models/expense.dart';

class ExpenseList extends StatelessWidget {
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final List<Expense>? customExpenses;
  final int? itemLimit;

  const ExpenseList({super.key, this.physics, this.shrinkWrap = false, this.customExpenses, this.itemLimit});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final allExpenses = customExpenses ?? provider.expenses;
        final expenses = itemLimit != null && allExpenses.length > itemLimit! 
            ? allExpenses.sublist(0, itemLimit)
            : allExpenses;

        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No expenses yet!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first expense',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: physics,
          shrinkWrap: shrinkWrap,
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final categoryColor = provider.getCategoryColor(expense.category);
            return Dismissible(
              key: ValueKey(expense.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Expense'),
                    content: Text(
                      'Are you sure you want to delete "${expense.title}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ) ?? false;
              },
              onDismissed: (_) {
                provider.deleteExpense(expense);
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 2,
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddExpenseScreen(expenseToEdit: expense),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: categoryColor.withValues(alpha: 0.15),
                    child: Icon(
                      provider.getCategoryIcon(expense.category),
                      color: categoryColor,
                    ),
                  ),
                  title: Text(
                    expense.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${expense.account} • ${DateFormat.yMMMd().format(expense.date)}'),
                      if (expense.notes != null && expense.notes!.isNotEmpty)
                        Text(
                          expense.notes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  trailing: Text(
                    '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

}
