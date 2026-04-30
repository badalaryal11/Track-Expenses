import 'dart:convert';
import 'dart:io';
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
    scopes: [drive.DriveApi.driveAppdataScope], // Use appData folder to hide backups from user's main drive
  );

  static const String _lastBackupKey = 'last_google_drive_backup';

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (error) {
      print("Google Sign In Error: $error");
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
      final account = await _googleSignIn.signInSilently() ?? await signIn();
      if (account == null) return false;

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return false;

      final driveApi = drive.DriveApi(httpClient);

      // Create a JSON backup of the expenses
      final backupFile = await _createLocalBackupFile();
      if (backupFile == null) return false;

      // Check if backup already exists
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
        // Update existing file
        await driveApi.files.update(driveFile, existingFileId, uploadMedia: media);
      } else {
        // Create new file
        driveFile.parents = ['appDataFolder'];
        await driveApi.files.create(driveFile, uploadMedia: media);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());

      return true;
    } catch (e) {
      print("Backup failed: $e");
      return false;
    }
  }

  Future<bool> restoreData() async {
    try {
      final account = await _googleSignIn.signInSilently() ?? await signIn();
      if (account == null) return false;

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return false;

      final driveApi = drive.DriveApi(httpClient);

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = 'expenses_backup.json'",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        print("No backup found.");
        return false;
      }

      final fileId = fileList.files!.first.id!;
      
      final drive.Media file = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await file.stream.listen((data) {
        dataStore.insertAll(dataStore.length, data);
      }).asFuture();

      final jsonString = utf8.decode(dataStore);
      await _restoreFromLocalJson(jsonString);

      return true;
    } catch (e) {
      print("Restore failed: $e");
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
      print("Error creating local backup file: $e");
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
      print("Error restoring from JSON: $e");
    }
  }
}
