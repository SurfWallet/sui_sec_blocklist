import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

// import 'package:web/web.dart' as web;

import '../types.dart';

/// Web localStorage cache.
class LocalStorage implements BlocklistStorage {
  String _getName(BlocklistStorageKey key) {
    return '${BlocklistStorageKey.coinBlocklist.key}.json';
  }

  /// Get the blocklist of [key] from Web localStorage.
  @override
  FutureOr<AllowBlocklist?> getItem(BlocklistStorageKey key) {
    final fileName = _getName(key);
    return Future(() {
      final str = html.window.localStorage.entries
          .firstWhereOrNull(
            (value) => value.key == fileName,
          )
          ?.value;
      if (str == null || str.isEmpty) return null;
      return AllowBlocklist.fromJson(jsonDecode(str));
    }).catchError((e) => null);
  }

  /// Storage the blocklist of [key] to Web localStorage.
  /// [key] blocklist type
  /// [data] blocklist data
  @override
  void setItem(BlocklistStorageKey key, AllowBlocklist? data) {
    html.window.localStorage.update(
      _getName(key),
      (value) => data != null ? jsonEncode(data.toJson()) : '',
      ifAbsent: () => data != null ? jsonEncode(data.toJson()) : '',
    );
  }
}

// //package:web
// /// Web localStorage cache.
// class LocalStorage implements BlocklistStorage {
//   /// Get the blocklist of [key] from Web localStorage.
//   @override
//   FutureOr<AllowBlocklist?> getItem(BlocklistStorageKey key) {
//     return Future(() {
//       final str = html.window.localStorage.getItem(key.key);
//       if (str == null || str.isEmpty) return null;
//       return AllowBlocklist.fromJson(jsonDecode(str));
//     }).catchError((e) => null);
//   }
//
//   /// Storage the blocklist of [key] to Web localStorage.
//   /// [key] blocklist type
//   /// [data] blocklist data
//   @override
//   void setItem(BlocklistStorageKey key, AllowBlocklist? data) {
//     web.window.localStorage.setItem(key.key, data != null ? jsonEncode(data.toJson()) : '');
//   }
// }

extension FirstWhereExt<T> on Iterable<T> {
  /// The first element satisfying [where], or `null` if there are none.
  T? firstWhereOrNull(bool Function(T element) where) {
    for (final e in this) {
      if (where(e)) {
        return e;
      }
    }
    return null;
  }
}
