import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:track_expenses/screens/add_expense_screen.dart';
import 'package:track_expenses/widgets/category_chart.dart';
import 'package:track_expenses/widgets/expense_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedView = 'Daily'; // Options: Daily, Weekly, Yearly
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'Rs';

  static const _quotes = [
    'Financial freedom starts with small steps!',
    'A penny saved is a penny earned.',
    'Track today, thrive tomorrow.',
    'Every expense tracked is a step toward control.',
    'Budgeting isn\'t about limiting — it\'s about freedom.',
    'Small leaks sink great ships. Track everything!',
    'Know where your money goes, and make it work for you.',
    'The habit of saving is itself an education.',
    'Don\'t save what is left after spending — spend what is left after saving.',
    'Financial awareness is the first step to wealth.',
    'Your future self will thank you for tracking today.',
    'Wealth is not about having a lot — it\'s about managing wisely.',
  ];

  late final String _currentQuote;

  @override
  void initState() {
    super.initState();
    _currentQuote = _quotes[Random().nextInt(_quotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final currencies = expenseProvider.uniqueCurrencies;

    // Ensure selected currency is valid
    if (currencies.isNotEmpty && !currencies.contains(_selectedCurrency)) {
      _selectedCurrency = currencies.first;
    } else if (currencies.isEmpty) {
      _selectedCurrency = 'Rs';
    }

    // Get stats based on selection
    double currentTotal = 0.0;

    if (_selectedView == 'Daily') {
      currentTotal = expenseProvider.calculateDailyTotal(
        currency: _selectedCurrency,
      );
    } else if (_selectedView == 'Weekly') {
      currentTotal = expenseProvider.calculateWeeklyTotal(
        currency: _selectedCurrency,
      );
    } else {
      currentTotal = expenseProvider.calculateMonthlyTotal(
        _selectedDate,
        currency: _selectedCurrency,
      );
    }

    final categoryTotals = expenseProvider.getCategoryTotals(
      view: _selectedView,
      selectedDate: _selectedDate,
      currency: _selectedCurrency,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paisa'),
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

      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;

          if (isLandscape) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // View Selector
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SegmentedButton<String>(
                            showSelectedIcon: false,
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment<String>(
                                value: 'Daily',
                                label: Text('Daily'),
                              ),
                              ButtonSegment<String>(
                                value: 'Weekly',
                                label: Text('Weekly'),
                              ),
                              ButtonSegment<String>(
                                value: 'Monthly',
                                label: Text('Monthly'),
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // App Icon
                                    SizedBox(
                                      height: 50,
                                      width: 50,
                                      child: Image.asset(
                                        'assets/icon/app_icon.png',
                                      ),
                                    ),
                                    if (currencies.isNotEmpty)
                                      DropdownButton<String>(
                                        value: _selectedCurrency,
                                        underline: Container(),
                                        icon: const Icon(Icons.arrow_drop_down),
                                        items: currencies.map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _selectedCurrency = newValue;
                                            });
                                          }
                                        },
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                Text(
                                  '$_selectedView Spending',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    '$_selectedCurrency ${currentTotal.toStringAsFixed(2)}',
                                    key: ValueKey('$_selectedView$_selectedCurrency$currentTotal'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _currentQuote,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CategoryChart(categoryTotals: categoryTotals),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                      const Expanded(child: ExpenseList()),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // View Selector
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: 'Daily',
                          label: Text('Daily'),
                        ),
                        ButtonSegment<String>(
                          value: 'Weekly',
                          label: Text('Weekly'),
                        ),
                        ButtonSegment<String>(
                          value: 'Monthly',
                          label: Text('Monthly'),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // App Icon
                              SizedBox(
                                height: 50,
                                width: 50,
                                child: Image.asset('assets/icon/app_icon.png'),
                              ),
                              if (currencies.isNotEmpty)
                                DropdownButton<String>(
                                  value: _selectedCurrency,
                                  underline: Container(),
                                  icon: const Icon(Icons.arrow_drop_down),
                                  items: currencies.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedCurrency = newValue;
                                      });
                                    }
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$_selectedView Spending',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              '$_selectedCurrency ${currentTotal.toStringAsFixed(2)}',
                              key: ValueKey('portrait_$_selectedView$_selectedCurrency$currentTotal'),
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
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
                              _currentQuote,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Category Chart
                  CategoryChart(categoryTotals: categoryTotals),
                  const SizedBox(height: 8),

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
                  const SizedBox(
                    height: 400,
                    child: ExpenseList(physics: NeverScrollableScrollPhysics()),
                  ),
                ],
              ),
            );
          }
        },
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
    final total = provider.calculateYearlyTotal(
      year,
      currency: _selectedCurrency,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Yearly Spending ($year)'),
          content: Text(
            '$_selectedCurrency ${total.toStringAsFixed(2)}',
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
