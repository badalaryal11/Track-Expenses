import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/models/expense.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:track_expenses/widgets/expense_list.dart';
import 'package:track_expenses/constants/app_constants.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final _searchController = TextEditingController();
  
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedCurrency;
  String? _selectedAccount;
  String _selectedSort = 'Date (Newest First)';
  final List<String> _sortOptions = [
    'Date (Newest First)', 
    'Date (Oldest First)', 
    'Amount (Highest First)', 
    'Amount (Lowest First)'
  ];
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sort & Filter',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Sort Order
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Sort By', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSort,
                        isDense: true,
                        items: _sortOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() { _selectedSort = val; });
                            setState(() { _selectedSort = val; });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Filter
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Category', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedCategory,
                        isDense: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Categories')),
                          ...Provider.of<ExpenseProvider>(context, listen: false).expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                        ],
                        onChanged: (val) {
                          setModalState(() { _selectedCategory = val; });
                          setState(() { _selectedCategory = val; });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Currency Filter
                  Builder(
                    builder: (context) {
                      final provider = Provider.of<ExpenseProvider>(context, listen: false);
                      final actualCurrencies = provider.uniqueCurrencies;
                      if (_selectedCurrency != null && !actualCurrencies.contains(_selectedCurrency)) {
                        _selectedCurrency = null;
                      }
                      return InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Currency', 
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.currency_exchange),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedCurrency,
                            isDense: true,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Currencies')),
                              ...actualCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                            ],
                            onChanged: (val) {
                              setModalState(() { _selectedCurrency = val; });
                              setState(() { _selectedCurrency = val; });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Account Filter
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Account', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedAccount,
                        isDense: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Accounts')),
                          ...AppConstants.accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))),
                        ],
                        onChanged: (val) {
                          setModalState(() { _selectedAccount = val; });
                          setState(() { _selectedAccount = val; });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  List<Expense> _getFilteredExpenses(List<Expense> allExpenses) {
    final filtered = allExpenses.where((expense) {
      bool matchesTitle = _searchQuery.isEmpty || expense.title.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesCategory = _selectedCategory == null || expense.category == _selectedCategory;
      bool matchesCurrency = _selectedCurrency == null || expense.currency == _selectedCurrency;
      bool matchesAccount = _selectedAccount == null || expense.account == _selectedAccount;
      return matchesTitle && matchesCategory && matchesCurrency && matchesAccount;
    }).toList();

    filtered.sort((a, b) {
      if (_selectedSort == 'Date (Newest First)') {
        return b.date.compareTo(a.date);
      } else if (_selectedSort == 'Date (Oldest First)') {
        return a.date.compareTo(b.date);
      } else if (_selectedSort == 'Amount (Highest First)') {
        return b.amount.compareTo(a.amount);
      } else if (_selectedSort == 'Amount (Lowest First)') {
        return a.amount.compareTo(b.amount);
      }
      return 0;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_selectedCategory != null || _selectedCurrency != null || _selectedAccount != null || _selectedSort != 'Date (Newest First)')
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  )
              ],
            ),
            onPressed: _openFilterDialog,
            tooltip: 'Sort & Filter',
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final filteredExpenses = _getFilteredExpenses(provider.expenses);
          
          if (filteredExpenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No matching transactions.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters or search query.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ExpenseList(
            customExpenses: filteredExpenses,
            displayCurrency: provider.defaultCurrency,
          );
        },
      ),
    );
  }
}
