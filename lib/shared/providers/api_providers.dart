import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sqlite_helper.dart';

// Provider for SQLiteHelper (used for local data storage)
final sqliteHelperProvider = Provider<SQLiteHelper>((ref) {
  return SQLiteHelper();
});
