import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/models/expense.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:track_expenses/screens/auth_wrapper.dart';
import 'package:track_expenses/screens/dashboard_screen.dart';
import 'package:track_expenses/services/exchange_rate_service.dart';

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
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ExpenseAdapter());
  }

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
              scaffoldBackgroundColor: const Color(0xFFF4F7F7),
              appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.teal.withValues(alpha: 0.18),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                elevation: 1,
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
              appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.teal.withValues(alpha: 0.35),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                elevation: 1,
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
  Object? _initError;

  @override
  void initState() {
    super.initState();
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _initialize();
      }
    });
  }

  Future<void> _initialize() async {
    try {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      await provider.init();
      await ExchangeRateService.instance.initialize(provider.defaultCurrency);
      
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _initError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Could not load app data.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _initialize,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const AuthWrapper(child: DashboardScreen());
  }
}
