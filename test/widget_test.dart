import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:track_expenses/models/expense.dart';

import 'package:track_expenses/main.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp(
      'track_expenses_test_',
    );
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MyApp), findsOneWidget);
  });
}
