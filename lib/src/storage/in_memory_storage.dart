import '../types.dart';
import 'local_storage.dart';

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

/// Memory and local storage cache.
class MemoryAndLocalStorage extends LocalStorage {
  final memoryStorage = InMemoryStorage();

  /// Get the blocklist of [key] from memory cache or local storage.
  /// * [key] blocklist type
  @override
  Future<AllowBlocklist?> getItem(BlocklistStorageKey key) async {
    return memoryStorage.getItem(key) ?? await super.getItem(key);
  }

  /// Storage the blocklist of [key] to memory cache and local storage.
  /// * [key] blocklist type
  /// * [data] blocklist data
  @override
  Future<void> setItem(BlocklistStorageKey key, AllowBlocklist? data) {
    memoryStorage.setItem(key, data);
    return super.setItem(key, data);
  }
}
