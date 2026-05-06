import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_expenses/models/expense.dart';

class GoogleDriveBackupService {
  static final GoogleDriveBackupService instance = GoogleDriveBackupService._privateConstructor();
  GoogleDriveBackupService._privateConstructor();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
    serverClientId: '690869062322-bfiudn6r5nq5bd3j64uah7sieqhbh6fi.apps.googleusercontent.com',
  );

  static const String _lastBackupKey = 'last_google_drive_backup';

  String? _lastError;
  String? get lastError => _lastError;

  Future<GoogleSignInAccount?> signIn() async {
    _lastError = null;
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint("[Google Sign In] User cancelled sign-in.");
        _lastError = "Sign-in was cancelled by the user.";
      }
      return account;
    } catch (error) {
      debugPrint("[Google Sign In] ERROR: $error");
      _lastError = error.toString();
      // If you get "Developer Error", it's usually a SHA-1 mismatch or scope issue in Google Cloud Console.
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<String?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastBackupKey);
  }

  Future<bool> backupData() async {
    try {
      debugPrint("[Backup] Starting backup...");
      
      var account = await _googleSignIn.signInSilently();
      if (account == null) {
        debugPrint("[Backup] Silent sign-in failed, trying interactive...");
        await _googleSignIn.disconnect().catchError((_) => null);
        account = await signIn();
      }
      
      if (account == null) {
        String errorMsg = _lastError ?? "Unknown sign-in error.";
        if (errorMsg.contains("7:")) {
          errorMsg = "Network error. Please check your internet connection.";
        } else if (errorMsg.contains("10:")) {
          errorMsg = "Developer Error (10): This usually means the SHA-1 fingerprint is not registered in Google Cloud Console or there's a package name mismatch.";
        } else if (errorMsg.contains("12500")) {
          errorMsg = "Sign-in failed (12500): The user is not authorized or the Google Cloud project is not configured correctly.";
        }
        throw Exception("Sign-in failed: $errorMsg\n\nPlease ensure you are a test user in Google Cloud Console and your SHA-1 is correctly registered.");
      }
      
      debugPrint("[Backup] Signed in as: ${account.email}");

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        throw Exception("Failed to get authenticated HTTP client.");
      }

      final driveApi = drive.DriveApi(httpClient);

      final backupFile = await _createLocalBackupFile();
      if (backupFile == null) {
        throw Exception("Failed to create local backup file.");
      }

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = 'expenses_backup.json'",
      );

      String? existingFileId;
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        existingFileId = fileList.files!.first.id;
      }

      final media = drive.Media(backupFile.openRead(), backupFile.lengthSync());
      final driveFile = drive.File()..name = 'expenses_backup.json';

      if (existingFileId != null) {
        await driveApi.files.update(driveFile, existingFileId, uploadMedia: media);
      } else {
        driveFile.parents = ['appDataFolder'];
        await driveApi.files.create(driveFile, uploadMedia: media);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());

      return true;
    } catch (e) {
      debugPrint("[Backup] FAILED: $e");
      rethrow; // Rethrow to show in UI
    }
  }

  Future<bool> restoreData() async {
    try {
      debugPrint("[Restore] Starting restore...");
      
      var account = await _googleSignIn.signInSilently();
      if (account == null) {
        debugPrint("[Restore] Silent sign-in failed, trying interactive...");
        await _googleSignIn.disconnect().catchError((_) => null);
        account = await signIn();
      }
      if (account == null) {
        String errorMsg = _lastError ?? "Unknown sign-in error.";
        if (errorMsg.contains("10:")) {
          errorMsg = "Developer Error (10): SHA-1 mismatch or package name mismatch.";
        }
        debugPrint("[Restore] Sign-in failed: $errorMsg");
        // We return false here instead of throwing because restore is often optional/manual
        return false;
      }
      debugPrint("[Restore] Signed in as: ${account.email}");

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        debugPrint("[Restore] Failed to get authenticated HTTP client.");
        return false;
      }

      final driveApi = drive.DriveApi(httpClient);

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = 'expenses_backup.json'",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint("[Restore] No backup found on Google Drive.");
        return false;
      }

      final fileId = fileList.files!.first.id!;
      debugPrint("[Restore] Found backup file: $fileId");
      
      final drive.Media file = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await file.stream.listen((data) {
        dataStore.insertAll(dataStore.length, data);
      }).asFuture();

      final jsonString = utf8.decode(dataStore);
      debugPrint("[Restore] Downloaded ${dataStore.length} bytes. Restoring...");
      await _restoreFromLocalJson(jsonString);

      debugPrint("[Restore] Restore completed successfully!");
      return true;
    } catch (e, stackTrace) {
      debugPrint("[Restore] FAILED: $e");
      debugPrint("[Restore] Stack trace: $stackTrace");
      return false;
    }
  }

  Future<File?> _createLocalBackupFile() async {
    try {
      final box = Hive.box('expenses');
      final expensesList = box.values.toList();
      
      // Convert Hive objects to Map manually or assuming they have a toJson method
      // Since Expense is a HiveObject, we construct a map:
      final List<Map<String, dynamic>> jsonData = expensesList.map((e) {
        return {
          'id': e.id,
          'title': e.title,
          'amount': e.amount,
          'date': e.date.toIso8601String(),
          'category': e.category,
          'currency': e.currency,
          'isRecurring': e.isRecurring,
          'recurrenceInterval': e.recurrenceInterval,
          'nextRecurrenceDate': e.nextRecurrenceDate?.toIso8601String(),
          'account': e.account,
          'notes': e.notes,
        };
      }).toList();

      final jsonString = json.encode(jsonData);

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/expenses_backup.json');
      return await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint("Error creating local backup file: $e");
      return null;
    }
  }

  Future<void> _restoreFromLocalJson(String jsonString) async {
    try {
      final List<dynamic> decodedList = json.decode(jsonString);
      final box = Hive.box('expenses');
      
      await box.clear(); // Important: Clear existing data before restoring

      for (var item in decodedList) {
        final expense = Expense(
          id: item['id'],
          title: item['title'],
          amount: (item['amount'] as num).toDouble(),
          date: DateTime.parse(item['date']),
          category: item['category'],
          currency: item['currency'] ?? 'NPR',
          isRecurring: item['isRecurring'] ?? false,
          recurrenceInterval: item['recurrenceInterval'] ?? 'None',
          nextRecurrenceDate: item['nextRecurrenceDate'] != null ? DateTime.parse(item['nextRecurrenceDate']) : null,
          account: item['account'] ?? 'Cash',
          notes: item['notes'],
        );
        await box.add(expense);
      }
    } catch (e) {
      debugPrint("Error restoring from JSON: $e");
    }
  }
}
