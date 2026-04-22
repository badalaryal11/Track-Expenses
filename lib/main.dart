import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/models/expense.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:track_expenses/screens/auth_wrapper.dart';
import 'package:track_expenses/screens/dashboard_screen.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
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
      child: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'My Expense',
            themeMode: provider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.light,
              ),
              textTheme: GoogleFonts.poppinsTextTheme(
                ThemeData(brightness: Brightness.light).textTheme,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.dark,
              ),
              textTheme: GoogleFonts.poppinsTextTheme(
                ThemeData(brightness: Brightness.dark).textTheme,
              ),
              useMaterial3: true,
            ),
            home: const InitWrapper(),
          );
        },
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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await Provider.of<ExpenseProvider>(context, listen: false).init();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return const AuthWrapper(child: DashboardScreen());
  }
}
