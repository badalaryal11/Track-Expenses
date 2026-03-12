import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/models/expense.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:uuid/uuid.dart';

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
  DateTime? _selectedDate;
  String _selectedCategory = 'Food';
  String _selectedCurrency = 'NPR'; // Default currency
  final _categories = ['Food', 'Travel', 'Leisure', 'Work', 'Other'];
  final _currencies = [
    'NPR',
    'Rs',
    'USD',
    'EUR',
    'GBP',
  ];

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expenseToEdit;
    if (expense != null) {
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toString();
      _selectedDate = expense.date;
      _selectedCurrency = expense.currency;
      // Check if category is a standard one or custom
      if (_categories.contains(expense.category)) {
        _selectedCategory = expense.category;
      } else {
        _selectedCategory = 'Other';
        _customCategoryController.text = expense.category;
      }
    }
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
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

    final newExpense = Expense(
      id: _isEditing ? widget.expenseToEdit!.id : const Uuid().v4(),
      title: enteredTitle,
      amount: enteredAmount,
      date: _selectedDate!,
      category: _selectedCategory == 'Other'
          ? _customCategoryController.text
          : _selectedCategory,
      currency: _selectedCurrency,
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
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Currency',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCurrency,
                isDense: true,
                items: _currencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCurrency = value;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );

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

    final categoryField = InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isDense: true,
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedCategory = value;
            });
          },
        ),
      ),
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Expense' : 'Add New Expense')),
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
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          submitButton,
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
                            const SizedBox(height: 16),
                            dateField,
                            const SizedBox(height: 16),
                            categoryField,
                            customCategoryField,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    submitButton,
                  ],
                ),
        ),
      ),
    );
  }
}
