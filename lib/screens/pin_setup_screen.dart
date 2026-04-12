import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/providers/expense_provider.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _enteredPin = '';
  String _confirmedPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';

  void _onDigitPressed(String digit) {
    setState(() {
      _errorMessage = '';
      if (_enteredPin.length < 4) {
        _enteredPin += digit;
      }
      if (_enteredPin.length == 4) {
        if (!_isConfirming) {
          _isConfirming = true;
          _confirmedPin = _enteredPin;
          _enteredPin = '';
        } else {
          if (_enteredPin == _confirmedPin) {
            _savePinAndExit();
          } else {
            _errorMessage = 'PINs do not match. Try again.';
            _isConfirming = false;
            _enteredPin = '';
            _confirmedPin = '';
          }
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

  void _savePinAndExit() async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    await provider.setAppPin(_confirmedPin);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App PIN set successfully')),
      );
      Navigator.of(context).pop();
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup PIN'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(Icons.lock_outline, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              _isConfirming ? 'Confirm your PIN' : 'Enter a 4-digit PIN',
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
                      Expanded(child: SizedBox()), // empty slot
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
