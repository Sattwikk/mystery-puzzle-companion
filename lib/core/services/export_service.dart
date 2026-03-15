import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Exports app data to JSON file (graduate: file system operations; bonus: data export).
class ExportService {
  /// Export missions and sessions to a JSON file in app documents directory.
  /// Returns the file path on success, or null on error.
  static Future<String?> exportToJson({
    required List<Map<String, dynamic>> missions,
    required List<Map<String, dynamic>> sessions,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${dir.path}/mystery_puzzle_export_$timestamp.json');
      final data = {
        'exported_at': DateTime.now().toIso8601String(),
        'missions': missions,
        'sessions': sessions,
      };
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
