import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/providers/expense_provider.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  String _enteredPin = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialAuth();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      if (provider.hasPinSetup) {
        setState(() {
          _isAuthenticated = false;
          _enteredPin = '';
          _errorMessage = '';
        });
      }
    }
  }

  void _checkInitialAuth() {
    if (!mounted) return;
    
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    if (!provider.hasPinSetup) {
      setState(() {
        _isAuthenticated = true;
      });
    }
  }

  void _onDigitPressed(String digit) {
    setState(() {
      _errorMessage = '';
      if (_enteredPin.length < 4) {
        _enteredPin += digit;
      }
      
      if (_enteredPin.length == 4) {
        final provider = Provider.of<ExpenseProvider>(context, listen: false);
        if (_enteredPin == provider.appPin) {
          _isAuthenticated = true;
        } else {
          _errorMessage = 'Incorrect PIN';
          _enteredPin = '';
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      _errorMessage = '';
      if (_enteredPin.isNotEmpty) {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      }
    });
  }

  Widget _buildDot(int index) {
    bool isFilled = index < _enteredPin.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? Theme.of(context).colorScheme.primary : Colors.transparent,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String label, {IconData? icon, VoidCallback? onPressed}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AspectRatio(
          aspectRatio: 1.5,
          child: FilledButton.tonal(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: icon != null
                ? Icon(icon, size: 28)
                : Text(label, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    
    if (!provider.hasPinSetup || _isAuthenticated) {
      return widget.child;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(Icons.lock, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Enter App PIN',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => _buildDot(index)),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildKeypadButton('1', onPressed: () => _onDigitPressed('1')),
                      _buildKeypadButton('2', onPressed: () => _onDigitPressed('2')),
                      _buildKeypadButton('3', onPressed: () => _onDigitPressed('3')),
                    ],
                  ),
                  Row(
                    children: [
                      _buildKeypadButton('4', onPressed: () => _onDigitPressed('4')),
                      _buildKeypadButton('5', onPressed: () => _onDigitPressed('5')),
                      _buildKeypadButton('6', onPressed: () => _onDigitPressed('6')),
                    ],
                  ),
                  Row(
                    children: [
                      _buildKeypadButton('7', onPressed: () => _onDigitPressed('7')),
                      _buildKeypadButton('8', onPressed: () => _onDigitPressed('8')),
                      _buildKeypadButton('9', onPressed: () => _onDigitPressed('9')),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(child: SizedBox()), // empty slot
                      _buildKeypadButton('0', onPressed: () => _onDigitPressed('0')),
                      _buildKeypadButton('', icon: Icons.backspace_outlined, onPressed: _onDeletePressed),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
