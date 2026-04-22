import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/models/expense.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:track_expenses/constants/app_constants.dart';
import 'package:track_expenses/widgets/forms/custom_dropdown_field.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expenseToEdit;

  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _customCurrencyController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedCategory = 'Food';
  late String _selectedCurrency;
  String _selectedAccount = 'Cash';
  String _recurrenceInterval = 'None'; 

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();
    // Set default currency from provider (available synchronously after init)
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final defaultCur = provider.defaultCurrency;
    if (AppConstants.currencies.contains(defaultCur)) {
      _selectedCurrency = defaultCur;
    } else {
      _selectedCurrency = 'Other';
      _customCurrencyController.text = defaultCur;
    }

    final expense = widget.expenseToEdit;
    if (expense != null) {
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toString();
      _selectedDate = expense.date;
      // Check if currency is a standard one or custom
      if (AppConstants.currencies.contains(expense.currency)) {
        _selectedCurrency = expense.currency;
      } else {
        _selectedCurrency = 'Other';
        _customCurrencyController.text = expense.currency;
      }
      // Check if category is a standard one or custom
      final provider2 = Provider.of<ExpenseProvider>(context, listen: false);
      if (provider2.expenseCategories.contains(expense.category)) {
        _selectedCategory = expense.category;
      } else {
        _selectedCategory = 'Other';
        _customCategoryController.text = expense.category;
      }
      _selectedAccount = expense.account;
      _recurrenceInterval = expense.recurrenceInterval;
    }
  }

  void _presentDatePicker() {
    final initial = _selectedDate ?? DateTime.now();
    showDatePicker(
      context: context,
      initialDate: initial.isAfter(DateTime.now()) ? DateTime.now() : initial,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }


  void _deleteExpense() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text(
            'Are you sure you want to delete this expense? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final provider =
                  Provider.of<ExpenseProvider>(context, listen: false);
              provider.deleteExpense(widget.expenseToEdit!);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return ElevatedButton.icon(
      onPressed: _deleteExpense,
      icon: const Icon(Icons.delete_outline, color: Colors.white),
      label: const Text(
        'Delete Expense',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _submitData() {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _selectedDate == null) {
      return; // Show error toast in real app
    }

    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text);

    if (enteredAmount == null || enteredAmount <= 0) {
      return; // Show error toast
    }

    if (_selectedCategory == 'Other' &&
        _customCategoryController.text.isEmpty) {
      return; // Show error: user must specify category
    }

    if (_selectedCurrency == 'Other' &&
        _customCurrencyController.text.trim().isEmpty) {
      return; // Show error: user must specify currency
    }

    final currency = _selectedCurrency == 'Other'
        ? _customCurrencyController.text.trim()
        : _selectedCurrency;

    final isRecurring = _recurrenceInterval != 'None';
    DateTime? nextRecurrenceDate;
    if (isRecurring && !(_isEditing && widget.expenseToEdit!.isRecurring)) {
       if (_recurrenceInterval == 'Daily') nextRecurrenceDate = _selectedDate!.add(const Duration(days: 1));
       if (_recurrenceInterval == 'Weekly') nextRecurrenceDate = _selectedDate!.add(const Duration(days: 7));
       if (_recurrenceInterval == 'Monthly') {
         final targetMonth = _selectedDate!.month + 1;
         final targetYear = targetMonth > 12 ? _selectedDate!.year + 1 : _selectedDate!.year;
         final normalizedMonth = targetMonth > 12 ? targetMonth - 12 : targetMonth;
         final daysInMonth = DateTime(targetYear, normalizedMonth + 1, 0).day;
         final day = _selectedDate!.day > daysInMonth ? daysInMonth : _selectedDate!.day;
         nextRecurrenceDate = DateTime(targetYear, normalizedMonth, day);
       }
       if (_recurrenceInterval == 'Yearly') {
         final targetYear = _selectedDate!.year + 1;
         final daysInMonth = DateTime(targetYear, _selectedDate!.month + 1, 0).day;
         final day = _selectedDate!.day > daysInMonth ? daysInMonth : _selectedDate!.day;
         nextRecurrenceDate = DateTime(targetYear, _selectedDate!.month, day);
       }
    } else if (_isEditing && isRecurring) {
       nextRecurrenceDate = widget.expenseToEdit?.nextRecurrenceDate;
       if (nextRecurrenceDate == null) {
         if (_recurrenceInterval == 'Daily') nextRecurrenceDate = _selectedDate!.add(const Duration(days: 1));
         if (_recurrenceInterval == 'Weekly') nextRecurrenceDate = _selectedDate!.add(const Duration(days: 7));
         if (_recurrenceInterval == 'Monthly') {
         final targetMonth = _selectedDate!.month + 1;
         final targetYear = targetMonth > 12 ? _selectedDate!.year + 1 : _selectedDate!.year;
         final normalizedMonth = targetMonth > 12 ? targetMonth - 12 : targetMonth;
         final daysInMonth = DateTime(targetYear, normalizedMonth + 1, 0).day;
         final day = _selectedDate!.day > daysInMonth ? daysInMonth : _selectedDate!.day;
         nextRecurrenceDate = DateTime(targetYear, normalizedMonth, day);
       }
         if (_recurrenceInterval == 'Yearly') {
         final targetYear = _selectedDate!.year + 1;
         final daysInMonth = DateTime(targetYear, _selectedDate!.month + 1, 0).day;
         final day = _selectedDate!.day > daysInMonth ? daysInMonth : _selectedDate!.day;
         nextRecurrenceDate = DateTime(targetYear, _selectedDate!.month, day);
       }
       }
    }

    final newExpense = Expense(
      id: _isEditing ? widget.expenseToEdit!.id : const Uuid().v4(),
      title: enteredTitle,
      amount: enteredAmount,
      date: _selectedDate!,
      category: _selectedCategory == 'Other'
          ? _customCategoryController.text
          : _selectedCategory,
      currency: currency,
      account: _selectedAccount,
      isRecurring: isRecurring,
      recurrenceInterval: _recurrenceInterval,
      nextRecurrenceDate: nextRecurrenceDate,
    );

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    if (_isEditing) {
      provider.updateExpense(widget.expenseToEdit!, newExpense);
    } else {
      provider.addExpense(newExpense);
    }
    Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final titleField = TextField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
    );

    final amountRow = Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: CustomDropdownField(
            label: 'Currency',
            value: _selectedCurrency,
            items: AppConstants.currencies,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedCurrency = value;
              });
            },
          ),
        ),
      ],
    );

    final accountField = CustomDropdownField(
      label: 'Account',
      value: _selectedAccount,
      items: AppConstants.accounts,
      prefixIcon: Icons.account_balance_wallet,
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedAccount = value;
        });
      },
    );

    final customCurrencyField = _selectedCurrency == 'Other'
        ? Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextField(
              controller: _customCurrencyController,
              decoration: const InputDecoration(
                labelText: 'Enter Currency Code',
                hintText: 'e.g. AUD, JPY, INR',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_exchange),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          )
        : const SizedBox.shrink();

    final dateField = InkWell(
      onTap: _presentDatePicker,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _selectedDate == null
              ? 'No Date Chosen'
              : DateFormat.yMd().format(_selectedDate!),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final categoryField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: provider.allCategories.map((cat) {
            final isSelected = _selectedCategory == cat.name;
            return ChoiceChip(
              label: Text(cat.name),
              avatar: Icon(cat.icon, color: isSelected ? Colors.white : cat.color, size: 18),
              selected: isSelected,
              selectedColor: cat.color,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = cat.name;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );

    final customCategoryField = _selectedCategory == 'Other'
        ? Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextField(
              controller: _customCategoryController,
              decoration: const InputDecoration(
                labelText: 'Specify Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
            ),
          )
        : const SizedBox.shrink();

    final recurrenceField = CustomDropdownField(
      label: 'Repeat Cycle',
      value: _recurrenceInterval,
      items: const ['None', 'Daily', 'Weekly', 'Monthly', 'Yearly'],
      prefixIcon: Icons.autorenew,
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _recurrenceInterval = value;
        });
      },
    );

    final submitButton = ElevatedButton(
      onPressed: _submitData,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      child: Text(
        _isEditing ? 'Update Expense' : 'Add Expense',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add New Expense'),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLandscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              titleField,
                              const SizedBox(height: 16),
                              amountRow,
                              customCurrencyField,
                              const SizedBox(height: 16),
                              accountField,
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  dateField,
                                  const SizedBox(height: 16),
                                  categoryField,
                                  customCategoryField,
                                  const SizedBox(height: 16),
                                  recurrenceField,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          submitButton,
                          if (_isEditing) ...
                          [
                            const SizedBox(height: 12),
                            _buildDeleteButton(),
                          ],
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            titleField,
                            const SizedBox(height: 16),
                            amountRow,
                            customCurrencyField,
                            const SizedBox(height: 16),
                            accountField,
                            const SizedBox(height: 16),
                            dateField,
                            const SizedBox(height: 16),
                            categoryField,
                            customCategoryField,
                            const SizedBox(height: 16),
                            recurrenceField,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    submitButton,
                    if (_isEditing) ...
                    [
                      const SizedBox(height: 12),
                      _buildDeleteButton(),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
