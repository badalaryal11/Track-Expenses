import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/constants/app_constants.dart';
import 'package:track_expenses/providers/expense_provider.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    IconData selectedIcon = AppConstants.availableIcons.first;
    Color selectedColor = AppConstants.availableColors.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Add Custom Category',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose an Icon',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.availableIcons.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => selectedIcon = icon);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor.withValues(alpha: 0.2)
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: selectedColor, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              icon,
                              size: 20,
                              color: isSelected ? selectedColor : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose a Color',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.availableColors.map((color) {
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => selectedColor = color);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Preview
                    Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                backgroundColor: selectedColor.withValues(alpha: 0.15),
                                child: Icon(selectedIcon, color: selectedColor),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Preview',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a category name')),
                                );
                                return;
                              }

                              final provider = Provider.of<ExpenseProvider>(context, listen: false);
                              final existing = provider.expenseCategories
                                  .map((c) => c.toLowerCase())
                                  .toList();
                              if (existing.contains(name.toLowerCase())) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('A category with this name already exists')),
                                );
                                return;
                              }

                              provider.addCustomCategory(name, selectedIcon, selectedColor);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('"$name" category added!')),
                              );
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Add Category'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCategory(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          'Are you sure you want to delete "$name"? Expenses already using this category will keep their label but won\'t have a matching icon/color.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ExpenseProvider>(context, listen: false)
                  .removeCustomCategory(name);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"$name" category removed')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final builtIn = AppConstants.categories;
          final custom = provider.allCategories
              .where((c) => !builtIn.any((b) => b.name == c.name))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Built-in categories
              Text(
                'Built-in Categories',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...builtIn.map((cat) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cat.color.withValues(alpha: 0.15),
                    child: Icon(cat.icon, color: cat.color),
                  ),
                  title: Text(cat.name),
                  trailing: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                ),
              )),

              const SizedBox(height: 24),

              // Custom categories
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Custom Categories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${custom.length} added',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (custom.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No custom categories yet',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to create your own category',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...custom.map((cat) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cat.color.withValues(alpha: 0.15),
                      child: Icon(cat.icon, color: cat.color),
                    ),
                    title: Text(cat.name),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                      onPressed: () => _confirmDeleteCategory(cat.name),
                    ),
                  ),
                )),
            ],
          );
        },
      ),
    );
  }
}
