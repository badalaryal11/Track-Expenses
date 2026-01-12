import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:track_expenses/screens/add_expense_screen.dart';
import 'package:track_expenses/widgets/expense_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedView = 'Daily'; // Options: Daily, Weekly, Yearly
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    // Get stats based on selection
    double currentTotal = 0.0;

    if (_selectedView == 'Daily') {
      currentTotal = expenseProvider.calculateDailyTotal();
    } else if (_selectedView == 'Weekly') {
      currentTotal = expenseProvider.calculateWeeklyTotal();
    } else {
      currentTotal = expenseProvider.calculateMonthlyTotal(_selectedDate);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              _showYearlyTotalDialog(context, expenseProvider);
            },
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Yearly Spending',
          ),
          IconButton(
            onPressed: () {
              expenseProvider.exportExpenses();
            },
            icon: const Icon(Icons.download),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // View Selector
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'Daily',
                    label: Text('Daily'),
                    icon: Icon(Icons.calendar_view_day),
                  ),
                  ButtonSegment<String>(
                    value: 'Weekly',
                    label: Text('Weekly'),
                    icon: Icon(Icons.calendar_view_week),
                  ),
                  ButtonSegment<String>(
                    value: 'Monthly',
                    label: Text('Monthly'),
                    icon: Icon(Icons.calendar_month),
                  ),
                ],
                selected: <String>{_selectedView},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedView = newSelection.first;
                  });
                },
              ),
            ),

            // Month Selector (Only visible for Monthly view)
            if (_selectedView == 'Monthly')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month - 1,
                          );
                        });
                      },
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedDate),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month + 1,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Summary Card (Updated with Graph)
            Card(
              margin: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Icon
                    SizedBox(
                      height: 50,
                      width: 50,
                      child: Image.asset('assets/icon/app_icon.png'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_selectedView Spending',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${currentTotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Financial freedom starts with small steps!",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        textAlign: TextAlign.center,
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
            SizedBox(height: 400, child: const ExpenseList()),
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

  void _showYearlyTotalDialog(BuildContext context, ExpenseProvider provider) {
    final year = DateTime.now().year;
    final total = provider.calculateYearlyTotal(year);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Yearly Spending ($year)'),
          content: Text(
            'Rs. ${total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
