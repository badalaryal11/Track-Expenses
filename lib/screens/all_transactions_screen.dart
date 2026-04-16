import 'package:flutter/material.dart';
import 'package:track_expenses/screens/search_screen.dart';
import 'package:track_expenses/widgets/expense_list.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search & Filter',
          ),
        ],
      ),
      body: const ExpenseList(),
    );
  }
}
