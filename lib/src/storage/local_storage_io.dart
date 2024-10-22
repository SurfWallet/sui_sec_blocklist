import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../types.dart';

/// Local File Storage cache.
class LocalStorage implements BlocklistStorage {
  Future<File> _getFile(BlocklistStorageKey key) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        context.join(dir.path, BlocklistStorageKey.coinBlocklist.key);
    return File(filePath);
  }

  /// Get the blocklist of [key] from local file.
  /// * [key] blocklist type
  @override
  Future<AllowBlocklist?> getItem(BlocklistStorageKey key) async {
    final file = await _getFile(key);
    if (!file.existsSync()) {
      return null;
    }
    final allowBlocklist = await Isolate.run(() {
      return file.readAsString().then<AllowBlocklist?>((str) {
        return str.isEmpty ? null : AllowBlocklist.fromJson(jsonDecode(str));
      });
    }).catchError((e, s) => null);
    return allowBlocklist;
  }

  /// Storage the blocklist of [key] to local file.
  /// * [key] blocklist type
  /// * [data] blocklist data
  @override
  Future<void> setItem(BlocklistStorageKey key, AllowBlocklist? data) async {
    final file = await _getFile(key);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    await Isolate.run(() {
      file.writeAsStringSync(
        data != null ? jsonEncode(data.toJson()) : '',
        flush: true,
      );
    }).catchError((e, s) => null);
  }
}
