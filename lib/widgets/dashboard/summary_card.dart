import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final List<String> currencies;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final String selectedView;
  final double currentTotal;
  final String currentQuote;
  final double monthlyBudget;
  final bool isPortrait;

  const SummaryCard({
    super.key,
    required this.currencies,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.selectedView,
    required this.currentTotal,
    required this.currentQuote,
    required this.monthlyBudget,
    this.isPortrait = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // App Icon
                SizedBox(
                  height: 50,
                  width: 50,
                  child: Image.asset('assets/icon/app_icon.png'),
                ),
                if (currencies.isNotEmpty)
                  DropdownButton<String>(
                    value: selectedCurrency,
                    underline: Container(),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: currencies.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        onCurrencyChanged(newValue);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$selectedView Spending',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: Text(
                '$selectedCurrency ${currentTotal.toStringAsFixed(2)}',
                key: ValueKey('${isPortrait ? "portrait_" : ""}$selectedView$selectedCurrency$currentTotal'),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            if (selectedView == 'Monthly' && monthlyBudget > 0) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Budget: $selectedCurrency ${monthlyBudget.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${(currentTotal / monthlyBudget * 100).clamp(0, 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentTotal > monthlyBudget ? Colors.red : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (currentTotal / monthlyBudget).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        currentTotal > monthlyBudget ? Colors.red : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (currentTotal > monthlyBudget) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Over budget by $selectedCurrency ${(currentTotal - monthlyBudget).toStringAsFixed(2)}!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                currentQuote,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
