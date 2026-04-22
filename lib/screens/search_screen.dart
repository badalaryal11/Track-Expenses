import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/models/expense.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:track_expenses/widgets/expense_list.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedCurrency;
  
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
                    'Filter Transactions',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
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
                      // Reset filter if selected currency no longer exists
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
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    return allExpenses.where((expense) {
      // Title match
      bool matchesTitle = _searchQuery.isEmpty || expense.title.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Category match
      bool matchesCategory = _selectedCategory == null || expense.category == _selectedCategory;
      
      // Currency match
      bool matchesCurrency = _selectedCurrency == null || expense.currency == _selectedCurrency;

      return matchesTitle && matchesCategory && matchesCurrency;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search expenses...',
            border: InputBorder.none,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_selectedCategory != null || _selectedCurrency != null)
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
            tooltip: 'Filter results',
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

          return ExpenseList(customExpenses: filteredExpenses);
        },
      ),
    );
  }
}
