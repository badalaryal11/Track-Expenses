import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:track_expenses/models/expense.dart';

class ExportService {
  /// Exports all expense records into a local CSV file natively utilizing native OS sharing.
  Future<void> exportExpenses(List<Expense> expenses) async {
    List<List<dynamic>> rows = [];

    // Add Header
    rows.add(["Date", "Title", "Amount", "Category", "Currency", "Account", "Recurring", "Repeat Cycle", "Notes"]);

    // Add Data
    for (var expense in expenses) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.title,
        expense.amount,
        expense.category,
        expense.currency,
        expense.account,
        expense.isRecurring,
        expense.recurrenceInterval,
        expense.notes ?? '',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/expenses_export.csv";
    final file = File(path);
    await file.writeAsString(csvData);

    await Share.shareXFiles([
      XFile(path),
    ], text: 'Here is your expense report.');
  }
}
