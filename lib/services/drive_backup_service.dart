import 'dart:convert';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exports the signed-in Supabase user's accessible PocketVault rows to Drive.
/// Drive access is limited to files created/opened by this app (drive.file).
class DriveBackupService {
  DriveBackupService._();
  static final DriveBackupService instance = DriveBackupService._();

  static const List<String> _scopes = <String>[
    drive.DriveApi.driveFileScope,
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);
  final SupabaseClient _supabase = Supabase.instance.client;

  static const List<String> _tables = <String>[
    'profiles',
    'members',
    'meals',
    'payments',
    'expenses',
  ];

  Future<drive.DriveApi> _getDriveApi() async {
    var account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw Exception(
          'Could not authorize Google Drive access. Please try again.');
    }
    return drive.DriveApi(client);
  }

  Future<String> createBackup() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Please login to PocketVault first.');

    final Map<String, dynamic> tableData = <String, dynamic>{};
    for (final table in _tables) {
      final rows = await _supabase.from(table).select();
      tableData[table] = rows;
    }

    final payload = <String, dynamic>{
      'app': 'PocketVault Mess Manager',
      'format_version': 1,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'supabase_user_id': user.id,
      'tables': tableData,
    };

    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    final timestamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = drive.File()
      ..name = 'PocketVault_Backup_$timestamp.json'
      ..mimeType = 'application/json';
    final media = drive.Media(
      Stream<List<int>>.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );

    final api = await _getDriveApi();
    final created = await api.files.create(file, uploadMedia: media);
    return created.name ?? 'PocketVault backup';
  }

  Future<String> restoreLatestBackup() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Please login to PocketVault first.');

    final api = await _getDriveApi();
    final listing = await api.files.list(
      q: "name contains 'PocketVault_Backup_' and trashed = false",
      orderBy: 'modifiedTime desc',
      pageSize: 1,
      spaces: 'drive',
      $fields: 'files(id,name,modifiedTime)',
    );

    final files = listing.files ?? <drive.File>[];
    if (files.isEmpty || files.first.id == null) {
      throw Exception(
          'No PocketVault backup was found in this Google Drive account.');
    }

    final result = await api.files.get(
      files.first.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );
    if (result is! drive.Media) {
      throw Exception('Could not download the backup file.');
    }

    final downloaded = <int>[];
    await for (final chunk in result.stream) {
      downloaded.addAll(chunk);
    }

    final decoded = jsonDecode(utf8.decode(downloaded));
    if (decoded is! Map<String, dynamic> ||
        decoded['app'] != 'PocketVault Mess Manager' ||
        decoded['format_version'] != 1 ||
        decoded['supabase_user_id'] != user.id ||
        decoded['tables'] is! Map) {
      throw Exception('This file is not a supported PocketVault backup.');
    }

    final tables = Map<String, dynamic>.from(decoded['tables'] as Map);
    for (final table in _tables) {
      final value = tables[table];
      if (value is List && value.isNotEmpty) {
        final rows = value
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
        await _supabase.from(table).upsert(rows);
      }
    }

    return files.first.name ?? 'PocketVault backup';
  }
}
