import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:track_expenses/screens/add_expense_screen.dart';
import 'package:track_expenses/widgets/expense_list.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Summary Card
            Card(
              margin: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Total Spending',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${expenseProvider.totalSpending.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Transactions Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to full list if needed
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),

            // Expense List
            SizedBox(
              height:
                  400, // Fixed height for now, or use Expanded if parent is adequate
              child: const ExpenseList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
