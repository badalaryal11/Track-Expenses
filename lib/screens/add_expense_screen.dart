import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/models/expense.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:uuid/uuid.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedCategory = 'Food';
  final _categories = ['Food', 'Travel', 'Leisure', 'Work', 'Other'];

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

    final newExpense = Expense(
      id: const Uuid().v4(),
      title: enteredTitle,
      amount: enteredAmount,
      date: _selectedDate!,
      category: _selectedCategory,
    );

    Provider.of<ExpenseProvider>(context, listen: false).addExpense(newExpense);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'No Date Chosen!'
                        : 'Picked Date: ${DateFormat.yMd().format(_selectedDate!)}',
                  ),
                ),
                TextButton(
                  onPressed: _presentDatePicker,
                  child: const Text(
                    'Choose Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedCategory,
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
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitData,
              child: const Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
