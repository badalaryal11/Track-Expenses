import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About My Expense')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App Logo or Icon Header
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'My Expense',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'About the App',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'My Expense is a comprehensive personal finance tracking application designed to help you stay on top of your spending. With powerful visualization and management tools, you can seamlessly track where every penny goes.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          Text(
            'Key Features',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          _FeatureTile(
            icon: Icons.bar_chart,
            title: 'Visual Insights',
            description:
                'Track spending visually with daily, weekly, and monthly bar charts and category breakdowns.',
          ),
          _FeatureTile(
            icon: Icons.currency_exchange,
            title: 'Multi-Currency Support',
            description:
                'Log expenses in any currency and automatically convert totals using live exchange rates.',
          ),
          _FeatureTile(
            icon: Icons.cloud_sync,
            title: 'Google Drive Cloud Backup',
            description:
                'Securely backup and restore your financial data using your Google account.',
          ),
          _FeatureTile(
            icon: Icons.security,
            title: 'PIN Lock Security',
            description:
                'Protect your sensitive financial data with a custom 4-digit PIN lock.',
          ),
          _FeatureTile(
            icon: Icons.account_balance,
            title: 'Multi-Account Tracking',
            description:
                'Separate expenses by source (Cash, Bank Account, or Credit Card).',
          ),
          _FeatureTile(
            icon: Icons.category,
            title: 'Custom Categories',
            description:
                'Create and manage your own personalized expense categories with custom icons and colors.',
          ),
          _FeatureTile(
            icon: Icons.download,
            title: 'Export to CSV',
            description:
                'Easily export your transaction history to a spreadsheet for deeper analysis.',
          ),
          _FeatureTile(
            icon: Icons.track_changes,
            title: 'Budget Planning',
            description:
                'Set a monthly budget to compare against your actual spending and stay on target.',
          ),
          _FeatureTile(
            icon: Icons.dark_mode,
            title: 'Dark & Light Themes',
            description:
                'Seamlessly switch between beautiful dark and light themes or follow your system default.',
          ),

          const SizedBox(height: 32),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
