import '../types.dart';
import 'in_memory_storage.dart';
import 'local_storage_io.dart'
    if (dart.library.html) 'local_storage_web.dart'
    if (dart.library.js_interop) 'local_storage_web.dart'
    if (dart.library.web) 'local_storage_web.dart';

export 'local_storage_io.dart'
    if (dart.library.html) 'local_storage_web.dart'
    if (dart.library.js_interop) 'local_storage_web.dart'
    if (dart.library.web) 'local_storage_web.dart';

/// Memory and local storage cache.
class MemoryAndLocalStorage extends LocalStorage {
  final memoryStorage = InMemoryStorage();

  /// Get the blocklist of [key] from memory cache or local storage.
  /// * [key] blocklist type
  @override
  Future<AllowBlocklist?> getItem(BlocklistStorageKey key) async {
    var blocklist = memoryStorage.getItem(key);
    if (blocklist == null) {
      blocklist = await super.getItem(key);
      if (blocklist != null) {
        memoryStorage.setItem(key, blocklist);
      }
    }
    return blocklist;
  }

  /// Storage the blocklist of [key] to memory cache and local storage.
  /// * [key] blocklist type
  /// * [data] blocklist data
  @override
  Future<void> setItem(BlocklistStorageKey key, AllowBlocklist? data) async {
    memoryStorage.setItem(key, data);
    await Future(() => super.setItem(key, data));
  }
}
