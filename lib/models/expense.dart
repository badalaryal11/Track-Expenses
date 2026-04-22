import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String currency;

  @HiveField(6, defaultValue: false)
  final bool isRecurring;

  @HiveField(7, defaultValue: 'None')
  final String recurrenceInterval; // 'None', 'Daily', 'Weekly', 'Monthly', 'Yearly'

  @HiveField(8, defaultValue: null)
  DateTime? nextRecurrenceDate;

  @HiveField(9, defaultValue: 'Cash')
  final String account; // 'Cash', 'Bank Account', 'Credit Card', etc.

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.currency = 'NPR', // Default currency
    this.isRecurring = false,
    this.recurrenceInterval = 'None',
    this.nextRecurrenceDate,
    this.account = 'Cash',
  });
}
