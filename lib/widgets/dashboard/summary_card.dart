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
    final theme = Theme.of(context);
    final dropdownCurrencies = {...currencies}.toList();
    final dropdownValue = dropdownCurrencies.contains(selectedCurrency)
        ? selectedCurrency
        : (dropdownCurrencies.isNotEmpty ? dropdownCurrencies.first : null);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                if (dropdownCurrencies.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.surface,
                    ),
                    child: DropdownButton<String>(
                      value: dropdownValue,
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down),
                      items: dropdownCurrencies.map((String value) {
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
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$selectedView Spending',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Text(
                '$selectedCurrency ${currentTotal.toStringAsFixed(2)}',
                key: ValueKey(
                  '${isPortrait ? "portrait_" : ""}$selectedView$selectedCurrency$currentTotal',
                ),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currentTotal > monthlyBudget
                              ? Colors.red
                              : null,
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
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        currentTotal > monthlyBudget
                            ? Colors.red
                            : theme.colorScheme.primary,
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                currentQuote,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.secondary,
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
