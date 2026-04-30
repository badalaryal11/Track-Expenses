import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_expenses/constants/app_constants.dart';
import 'package:track_expenses/providers/expense_provider.dart';
import 'package:track_expenses/services/cloud_backup_service.dart';
import 'package:track_expenses/services/exchange_rate_service.dart';
import 'package:track_expenses/widgets/forms/custom_dropdown_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;

  Future<void> _performBackup() async {
    setState(() => _isBackingUp = true);
    final success = await GoogleDriveBackupService.instance.backupData();
    setState(() => _isBackingUp = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Backup successful!' : 'Backup failed.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _performRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
            'Restoring from Google Drive will replace all your current local expenses. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRestoring = true);
    final success = await GoogleDriveBackupService.instance.restoreData();
    setState(() => _isRestoring = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Restore successful! Refreshing data...' : 'Restore failed or no backup found.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        // Re-initialize provider to load new data
        Provider.of<ExpenseProvider>(context, listen: false).init();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final baseCurrency = provider.defaultCurrency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Currency Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomDropdownField(
                    label: 'Base Currency',
                    value: AppConstants.currencies.contains(baseCurrency) ? baseCurrency : 'Other',
                    items: AppConstants.currencies,
                    onChanged: (value) async {
                      if (value == 'Other') {
                        final customController = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Enter Custom Currency'),
                            content: TextField(
                              controller: customController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Currency Code',
                                hintText: 'e.g. AUD, JPY',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.currency_exchange),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () async {
                                  final newCurrency = customController.text.trim().toUpperCase();
                                  if (newCurrency.isNotEmpty) {
                                    Navigator.of(ctx).pop();
                                    await provider.setDefaultCurrency(newCurrency);
                                    await ExchangeRateService.instance.initialize(newCurrency);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Base currency set to $newCurrency and rates fetched!')),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                      } else if (value != null) {
                        await provider.setDefaultCurrency(value);
                        await ExchangeRateService.instance.initialize(value);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Base currency updated and rates fetched!')),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ExchangeRateService.instance.fetchLatestRates(forceRefresh: true);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Exchange rates refreshed successfully!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Exchange Rates'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cloud Backup (Google Drive)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_upload, color: Colors.blue),
                    title: const Text('Backup to Google Drive'),
                    subtitle: const Text('Save your expenses securely.'),
                    trailing: _isBackingUp ? const CircularProgressIndicator() : null,
                    onTap: _isBackingUp ? null : _performBackup,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cloud_download, color: Colors.green),
                    title: const Text('Restore from Google Drive'),
                    subtitle: const Text('Load your expenses from backup.'),
                    trailing: _isRestoring ? const CircularProgressIndicator() : null,
                    onTap: _isRestoring ? null : _performRestore,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
