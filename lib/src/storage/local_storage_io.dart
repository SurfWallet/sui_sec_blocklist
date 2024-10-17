import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../types.dart';

class LocalStorage implements BlocklistStorage {
  File _getFile(BlocklistStorageKey key) {
    final file = File('${BlocklistStorageKey.coinBlocklist.key}.json');
    return file;
  }

  @override
  Future<AllowBlocklist?> getItem(BlocklistStorageKey key) async {
    final file = _getFile(key);
    if (file.existsSync()) return null;
    return file.readAsString().then<AllowBlocklist?>((str) {
      return str.isEmpty ? null : AllowBlocklist.fromJson(jsonDecode(str));
    }).catchError((e) => null);
  }

  @override
  Future<void> setItem(BlocklistStorageKey key, AllowBlocklist? data) {
    return _getFile(key).writeAsString(
        data != null ? jsonEncode(data.toJson()) : '',
        flush: true);
  }
}
