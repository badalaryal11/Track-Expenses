import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/constants/app_constants.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:track_expenses/screens/add_expense_screen.dart';
import 'package:track_expenses/screens/manage_categories_screen.dart';
import 'package:track_expenses/screens/pin_setup_screen.dart';
import 'package:track_expenses/widgets/category_chart.dart';
import 'package:track_expenses/widgets/dashboard/month_selector.dart';
import 'package:track_expenses/widgets/dashboard/summary_card.dart';
import 'package:track_expenses/widgets/dashboard/view_selector.dart';
import 'package:track_expenses/screens/all_transactions_screen.dart';
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
  String? _selectedCurrency;
  late final String _currentQuote;

  @override
  void initState() {
    super.initState();
    _currentQuote = AppConstants.quotes[Random().nextInt(AppConstants.quotes.length)];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final currencies = expenseProvider.uniqueCurrencies;

    // Initialize selected currency from saved default on first build
    _selectedCurrency ??= expenseProvider.defaultCurrency;

    // Ensure selected currency is valid
    if (currencies.isNotEmpty && !currencies.contains(_selectedCurrency)) {
      _selectedCurrency = currencies.first;
    } else if (currencies.isEmpty) {
      _selectedCurrency = expenseProvider.defaultCurrency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final currencies = expenseProvider.uniqueCurrencies;

    final String currency = _selectedCurrency ?? expenseProvider.defaultCurrency;

    // Get stats based on selection
    double currentTotal = 0.0;
    if (_selectedView == 'Daily') {
      currentTotal = expenseProvider.calculateDailyTotal(
        currency: currency,
      );
    } else if (_selectedView == 'Weekly') {
      currentTotal = expenseProvider.calculateWeeklyTotal(
        currency: currency,
      );
    } else {
      currentTotal = expenseProvider.calculateMonthlyTotal(
        _selectedDate,
        currency: currency,
      );
    }

    final categoryTotals = expenseProvider.getCategoryTotals(
      view: _selectedView,
      selectedDate: _selectedDate,
      currency: currency,
    );

    Map<int, double> dailySpendingMonth = {};
    if (_selectedView == 'Monthly') {
      dailySpendingMonth = expenseProvider.getDailySpendingForMonth(
        _selectedDate,
        currency: currency,
      );
    }

    Map<int, double> dailySpendingWeek = {};
    if (_selectedView == 'Weekly') {
      dailySpendingWeek = expenseProvider.getDailyStats(
        currency: currency,
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
          IconButton(
            onPressed: () {
              _showSettingsSheet(context, expenseProvider);
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
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
                          selectedCurrency: currency,
                          onCurrencyChanged: (c) => setState(() => _selectedCurrency = c),
                          selectedView: _selectedView,
                          currentTotal: currentTotal,
                          currentQuote: _currentQuote,
                          monthlyBudget: expenseProvider.monthlyBudget,
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
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AllTransactionsScreen()),
                                );
                              },
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(child: ExpenseList(itemLimit: 5)),
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
                    selectedCurrency: currency,
                    onCurrencyChanged: (c) => setState(() => _selectedCurrency = c),
                    selectedView: _selectedView,
                    currentTotal: currentTotal,
                    currentQuote: _currentQuote,
                    monthlyBudget: expenseProvider.monthlyBudget,
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
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AllTransactionsScreen()),
                            );
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
                    itemLimit: 5,
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
    final cur = _selectedCurrency ?? provider.defaultCurrency;
    final total = provider.calculateYearlyTotal(
      year,
      currency: cur,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Yearly Spending ($year)'),
          content: Text(
            '$cur ${total.toStringAsFixed(2)}',
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

  void _showDefaultCurrencyDialog(BuildContext context, ExpenseProvider provider) {
    final allCurrencies = AppConstants.currencies; // includes 'Other'
    final customController = TextEditingController();
    
    // Determine initial state
    final standardCurrencies = allCurrencies.where((c) => c != 'Other').toList();
    String selected;
    if (standardCurrencies.contains(provider.defaultCurrency)) {
      selected = provider.defaultCurrency;
    } else {
      selected = 'Other';
      customController.text = provider.defaultCurrency;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Default Currency'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Choose the currency used by default when adding new expenses.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    RadioGroup<String>(
                      groupValue: selected,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selected = val);
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...allCurrencies.map((c) => RadioListTile<String>(
                            title: Text(c),
                            value: c,
                          )),
                        ],
                      ),
                    ),
                    if (selected == 'Other')
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                        child: TextField(
                          controller: customController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Enter Currency Code',
                            hintText: 'e.g. AUD, JPY, INR',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_exchange),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final currency = selected == 'Other'
                        ? customController.text.trim().toUpperCase()
                        : selected;

                    if (currency.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a currency code')),
                      );
                      return;
                    }

                    provider.setDefaultCurrency(currency);
                    setState(() => _selectedCurrency = currency);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Default currency set to $currency')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSettingsSheet(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    provider.themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : provider.themeMode == ThemeMode.light
                            ? Icons.light_mode
                            : Icons.brightness_auto,
                  ),
                  title: const Text('Appearance'),
                  subtitle: Text(
                    provider.themeMode == ThemeMode.dark
                        ? 'Dark Mode'
                        : provider.themeMode == ThemeMode.light
                            ? 'Light Mode'
                            : 'System Default',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showThemeModeDialog(context, provider);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text('Default Currency'),
                  subtitle: Text('Currently: ${provider.defaultCurrency}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showDefaultCurrencyDialog(context, provider);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.track_changes),
                  title: const Text('Monthly Budget'),
                  subtitle: Text(provider.monthlyBudget > 0 ? 'Set to ${provider.defaultCurrency} ${provider.monthlyBudget.toStringAsFixed(0)}' : 'Not set'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showSetBudgetDialog(context, provider);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Manage Categories'),
                  subtitle: const Text('Add or remove custom categories'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.pin),
                  title: Text(provider.hasPinSetup ? 'Remove App PIN' : 'Set App PIN'),
                  subtitle: Text(provider.hasPinSetup ? 'Disable PIN lock' : 'Protect app with a 4-digit PIN'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (provider.hasPinSetup) {
                      provider.removeAppPin();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('App PIN removed')),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red.shade400),
                  title: Text(
                    'Clear All Data',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                  subtitle: const Text('Delete all expenses and reset settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showClearDataDialog(context, provider);
                  },
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }
  void _showThemeModeDialog(BuildContext context, ExpenseProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Appearance'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('System Default'),
                    subtitle: const Text('Follow device setting'),
                    leading: const Icon(Icons.brightness_auto),
                    trailing: provider.themeMode == ThemeMode.system ? const Icon(Icons.check, color: Colors.teal) : null,
                    onTap: () {
                      provider.setThemeMode(ThemeMode.system);
                      setDialogState(() {});
                    },
                  ),
                  ListTile(
                    title: const Text('Light Mode'),
                    leading: const Icon(Icons.light_mode),
                    trailing: provider.themeMode == ThemeMode.light ? const Icon(Icons.check, color: Colors.teal) : null,
                    onTap: () {
                      provider.setThemeMode(ThemeMode.light);
                      setDialogState(() {});
                    },
                  ),
                  ListTile(
                    title: const Text('Dark Mode'),
                    leading: const Icon(Icons.dark_mode),
                    trailing: provider.themeMode == ThemeMode.dark ? const Icon(Icons.check, color: Colors.teal) : null,
                    onTap: () {
                      provider.setThemeMode(ThemeMode.dark);
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSetBudgetDialog(BuildContext context, ExpenseProvider provider) {
    final controller = TextEditingController(
      text: provider.monthlyBudget > 0 ? provider.monthlyBudget.toStringAsFixed(0) : '',
    );
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set Monthly Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set a target limit for your monthly spending. Enter 0 to disable.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${provider.defaultCurrency} ',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final val = double.tryParse(controller.text) ?? 0.0;
                provider.setMonthlyBudget(val);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(val > 0 ? 'Monthly budget set to ${provider.defaultCurrency} ${val.toStringAsFixed(0)}' : 'Monthly budget disabled')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showClearDataDialog(BuildContext context, ExpenseProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 48),
          title: const Text('Clear All Data?'),
          content: const Text(
            'This will permanently delete all your expenses and reset your settings. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade400,
              ),
              onPressed: () async {
                await provider.clearAllData();
                setState(() => _selectedCurrency = null);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data has been cleared')),
                  );
                }
              },
              child: const Text('Delete Everything'),
            ),
          ],
        );
      },
    );
  }
}
