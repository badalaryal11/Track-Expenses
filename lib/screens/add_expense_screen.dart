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
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedCategory = 'Food';
  late String _selectedCurrency;
  String _selectedAccount = 'Cash';
  String _recurrenceInterval = 'None';

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    _customCurrencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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
      _notesController.text = expense.notes ?? '';
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

  Future<void> _deleteExpense() async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final expense = widget.expenseToEdit!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Perform delete and exit screen
    try {
      await provider.deleteExpense(expense);
    } catch (_) {
      if (mounted) {
        _showError('Could not delete expense. Please try again.');
      }
      return;
    }
    if (!mounted) return;
    navigator.pop();

    // Show undo snackbar on the previous screen
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Expense deleted'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: primaryColor,
          onPressed: () async {
            await provider.addExpense(expense);
          },
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return ElevatedButton.icon(
      onPressed: () => _deleteExpense(),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  DateTime? _calculateNextRecurrenceDate(DateTime startDate, String interval) {
    switch (interval) {
      case 'Daily':
        return startDate.add(const Duration(days: 1));
      case 'Weekly':
        return startDate.add(const Duration(days: 7));
      case 'Monthly':
        final targetMonth = startDate.month + 1;
        final targetYear = targetMonth > 12
            ? startDate.year + 1
            : startDate.year;
        final normalizedMonth = targetMonth > 12
            ? targetMonth - 12
            : targetMonth;
        final daysInMonth = DateTime(targetYear, normalizedMonth + 1, 0).day;
        final day = startDate.day > daysInMonth ? daysInMonth : startDate.day;
        return DateTime(targetYear, normalizedMonth, day);
      case 'Yearly':
        final targetYear = startDate.year + 1;
        final daysInMonth = DateTime(targetYear, startDate.month + 1, 0).day;
        final day = startDate.day > daysInMonth ? daysInMonth : startDate.day;
        return DateTime(targetYear, startDate.month, day);
      default:
        return null;
    }
  }

  Future<void> _submitData() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a title for the expense.');
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      _showError('Please enter an amount.');
      return;
    }

    final enteredTitle = _titleController.text.trim();
    final enteredAmount = double.tryParse(_amountController.text);

    if (enteredAmount == null || enteredAmount <= 0) {
      _showError('Please enter a valid amount greater than zero.');
      return;
    }

    if (_selectedDate == null) {
      _showError('Please select a date.');
      return;
    }

    if (_selectedCategory == 'Other' &&
        _customCategoryController.text.trim().isEmpty) {
      _showError('Please specify a custom category name.');
      return;
    }

    if (_selectedCurrency == 'Other' &&
        _customCurrencyController.text.trim().isEmpty) {
      _showError('Please enter a custom currency code.');
      return;
    }

    final currency = _selectedCurrency == 'Other'
        ? _customCurrencyController.text.trim()
        : _selectedCurrency;

    final isRecurring = _recurrenceInterval != 'None';
    DateTime? nextRecurrenceDate;
    if (isRecurring) {
      final editingSameRecurringInterval =
          _isEditing &&
          widget.expenseToEdit!.isRecurring &&
          widget.expenseToEdit!.recurrenceInterval == _recurrenceInterval;

      if (editingSameRecurringInterval &&
          widget.expenseToEdit!.nextRecurrenceDate != null) {
        nextRecurrenceDate = widget.expenseToEdit!.nextRecurrenceDate;
      } else {
        nextRecurrenceDate = _calculateNextRecurrenceDate(
          _selectedDate!,
          _recurrenceInterval,
        );
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
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    try {
      if (_isEditing) {
        await provider.updateExpense(widget.expenseToEdit!, newExpense);
      } else {
        await provider.addExpense(newExpense);
      }
    } catch (_) {
      if (mounted) {
        _showError('Could not save expense. Please try again.');
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              _isEditing
                  ? 'Expense updated successfully!'
                  : 'Expense added successfully!',
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
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
              avatar: Icon(
                cat.icon,
                color: isSelected ? Colors.white : cat.color,
                size: 18,
              ),
              selected: isSelected,
              selectedColor: cat.color,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
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

    final notesField = TextField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (optional)',
        hintText: 'e.g. dinner with friends, annual renewal...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.notes),
      ),
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
    );

    final submitButton = ElevatedButton(
      onPressed: () => _submitData(),
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
                                  const SizedBox(height: 16),
                                  notesField,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          submitButton,
                          if (_isEditing) ...[
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
                            const SizedBox(height: 16),
                            notesField,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    submitButton,
                    if (_isEditing) ...[
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
