import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/constants/app_constants.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:track_expenses/screens/add_expense_screen.dart';
import 'package:track_expenses/widgets/category_chart.dart';
import 'package:track_expenses/widgets/dashboard/month_selector.dart';
import 'package:track_expenses/widgets/dashboard/summary_card.dart';
import 'package:track_expenses/widgets/dashboard/view_selector.dart';
import 'package:track_expenses/widgets/dashboard/monthly_bar_chart.dart';
import 'package:track_expenses/widgets/dashboard/weekly_bar_chart.dart';
import 'package:track_expenses/widgets/expense_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedView = 'Daily'; // Options: Daily, Weekly, Monthly
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'RS';
  late final String _currentQuote;

  @override
  void initState() {
    super.initState();
    _currentQuote = AppConstants.quotes[Random().nextInt(AppConstants.quotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final currencies = expenseProvider.uniqueCurrencies;

    // Ensure selected currency is valid
    if (currencies.isNotEmpty && !currencies.contains(_selectedCurrency)) {
      _selectedCurrency = currencies.first;
    } else if (currencies.isEmpty) {
      _selectedCurrency = 'RS';
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

    Map<int, double> dailySpendingMonth = {};
    if (_selectedView == 'Monthly') {
      dailySpendingMonth = expenseProvider.getDailySpendingForMonth(
        _selectedDate,
        currency: _selectedCurrency,
      );
    }

    Map<int, double> dailySpendingWeek = {};
    if (_selectedView == 'Weekly') {
      dailySpendingWeek = expenseProvider.getDailyStats(
        currency: _selectedCurrency,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expense'),
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
          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

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
                          child: ViewSelector(
                            selectedView: _selectedView,
                            onViewChanged: (view) => setState(() => _selectedView = view),
                          ),
                        ),

                        // Month Selector (Only visible for Monthly view)
                        if (_selectedView == 'Monthly')
                          MonthSelector(
                            selectedDate: _selectedDate,
                            onDateChanged: (date) => setState(() => _selectedDate = date),
                          ),

                        // Summary Card
                        SummaryCard(
                          currencies: currencies,
                          selectedCurrency: _selectedCurrency,
                          onCurrencyChanged: (currency) => setState(() => _selectedCurrency = currency),
                          selectedView: _selectedView,
                          currentTotal: currentTotal,
                          currentQuote: _currentQuote,
                          isPortrait: false,
                        ),

                        const SizedBox(height: 12),
                        CategoryChart(categoryTotals: categoryTotals),
                        if (_selectedView == 'Weekly') ...[
                          const SizedBox(height: 12),
                          WeeklyBarChart(dailySpending: dailySpendingWeek),
                        ],
                        if (_selectedView == 'Monthly') ...[
                          const SizedBox(height: 12),
                          MonthlyBarChart(dailySpending: dailySpendingMonth),
                        ],
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
                    child: ViewSelector(
                      selectedView: _selectedView,
                      onViewChanged: (view) => setState(() => _selectedView = view),
                    ),
                  ),

                  // Month Selector (Only visible for Monthly view)
                  if (_selectedView == 'Monthly')
                    MonthSelector(
                      selectedDate: _selectedDate,
                      onDateChanged: (date) => setState(() => _selectedDate = date),
                    ),

                  // Summary Card
                  SummaryCard(
                    currencies: currencies,
                    selectedCurrency: _selectedCurrency,
                    onCurrencyChanged: (currency) => setState(() => _selectedCurrency = currency),
                    selectedView: _selectedView,
                    currentTotal: currentTotal,
                    currentQuote: _currentQuote,
                    isPortrait: true,
                  ),

                  // Category Chart
                  CategoryChart(categoryTotals: categoryTotals),
                  if (_selectedView == 'Weekly') ...[
                    const SizedBox(height: 8),
                    WeeklyBarChart(dailySpending: dailySpendingWeek),
                  ],
                  if (_selectedView == 'Monthly') ...[
                    const SizedBox(height: 8),
                    MonthlyBarChart(dailySpending: dailySpendingMonth),
                  ],
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
                  const ExpenseList(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
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
