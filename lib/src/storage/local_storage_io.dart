import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../types.dart';

/// Local File Storage cache.
class LocalStorage implements BlocklistStorage {
  File _getFile(BlocklistStorageKey key) {
    final file = File('${BlocklistStorageKey.coinBlocklist.key}.json');
    return file;
  }

  /// Get the blocklist of [key] from local file.
  /// * [key] blocklist type
  @override
  Future<AllowBlocklist?> getItem(BlocklistStorageKey key) async {
    final file = _getFile(key);
    if (file.existsSync()) return null;
    return file.readAsString().then<AllowBlocklist?>((str) {
      return str.isEmpty ? null : AllowBlocklist.fromJson(jsonDecode(str));
    }).catchError((e) => null);
  }

  /// Storage the blocklist of [key] to local file.
  /// * [key] blocklist type
  /// * [data] blocklist data
  @override
  Future<void> setItem(BlocklistStorageKey key, AllowBlocklist? data) {
    return _getFile(key).writeAsString(
        data != null ? jsonEncode(data.toJson()) : '',
        flush: true);
  }
}
