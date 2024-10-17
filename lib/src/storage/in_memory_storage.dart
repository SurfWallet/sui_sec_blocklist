import '../types.dart';

class InMemoryStorage implements BlocklistStorage {
  InMemoryStorage();

  final _storage = <BlocklistStorageKey, dynamic>{};

  @override
  AllowBlocklist? getItem(BlocklistStorageKey key) {
    return _storage[key];
  }

  @override
  void setItem(BlocklistStorageKey key, AllowBlocklist? data) {
    _storage[key] = data;
  }
}
