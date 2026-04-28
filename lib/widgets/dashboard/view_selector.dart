import 'package:flutter/material.dart';
import 'package:track_expenses/constants/app_constants.dart';

class ViewSelector extends StatelessWidget {
  final String selectedView;
  final ValueChanged<String> onViewChanged;

  const ViewSelector({
    super.key,
    required this.selectedView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: AppConstants.dashboardViews.map((view) {
          final isSelected = selectedView == view;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onViewChanged(view),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(
                  view,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
