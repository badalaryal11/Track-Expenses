import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/models/expense.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:track_expenses/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ExpenseProvider())],
      child: MaterialApp(
        title: 'Track Expenses',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const InitWrapper(),
      ),
    );
  }
}

class InitWrapper extends StatefulWidget {
  const InitWrapper({super.key});

  @override
  State<InitWrapper> createState() => _InitWrapperState();
}

class _InitWrapperState extends State<InitWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ExpenseProvider>(context, listen: false).init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}
