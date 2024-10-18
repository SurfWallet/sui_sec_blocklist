import '../types.dart';

/// Memory Storage cache
class InMemoryStorage implements BlocklistStorage {
  InMemoryStorage();

  final _storage = <BlocklistStorageKey, dynamic>{};

  /// Get the blocklist of [key] from memory cache.
  /// * [key] blocklist type
  @override
  AllowBlocklist? getItem(BlocklistStorageKey key) {
    return _storage[key];
  }

  /// Storage the blocklist of [key] to memory cache.
  /// * [key] blocklist type
  /// * [data] blocklist data
  @override
  void setItem(BlocklistStorageKey key, AllowBlocklist? data) {
    _storage[key] = data;
  }
}
