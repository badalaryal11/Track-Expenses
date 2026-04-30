import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  // Always fetch rates relative to USD to build a universal conversion table.
  static const String _baseUrl = 'https://open.er-api.com/v6/latest/USD';
  static const String _lastUpdateKey = 'exchange_rates_last_update';
  static const String _ratesKey = 'exchange_rates_data';

  // Singleton pattern
  ExchangeRateService._privateConstructor();
  static final ExchangeRateService instance = ExchangeRateService._privateConstructor();

  Map<String, double>? _cachedRates;

  Future<void> initialize(String ignoredBaseCurrency) async {
    // Base currency parameter is ignored because we always fetch against USD
    // which allows us to convert from ANY currency to ANY currency flawlessly.
    await _loadCachedRates();
    await fetchLatestRates();
  }

  Future<void> _loadCachedRates() async {
    final prefs = await SharedPreferences.getInstance();
    final ratesJson = prefs.getString(_ratesKey);
    if (ratesJson != null) {
      _cachedRates = Map<String, double>.from(json.decode(ratesJson));
    }
  }

  Future<void> fetchLatestRates({bool forceRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      
      if (!forceRefresh && lastUpdateStr != null && _cachedRates != null) {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        // Only refresh rates if they are older than 24 hours
        if (DateTime.now().difference(lastUpdate).inHours < 24) {
          return; // Cache is still fresh
        }
      }

      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, dynamic>.from(data['rates']);
        
        _cachedRates = rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
        
        // Save to cache
        await prefs.setString(_ratesKey, json.encode(_cachedRates));
        await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      }
    } catch (e) {
      debugPrint('Failed to fetch exchange rates: $e');
    }
  }

  double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    // If rates are not loaded, just return the amount to avoid breaking the UI
    if (_cachedRates == null) return amount;

    // Rate is defined as: 1 USD = rate[Currency]
    final fromRate = _cachedRates![fromCurrency];
    final toRate = _cachedRates![toCurrency];
    
    if (fromRate == null || toRate == null || fromRate == 0) return amount; // Fallback

    // Convert 'from' to 'USD', then 'USD' to 'to'
    return (amount / fromRate) * toRate;
  }
}
