import 'dart:async';

/// Scan result.
enum Action {
  /// the scan result is in blacklist.
  block,

  /// the scan result is not in blacklist.
  none,
}

///Whitelist and Blacklist.
class AllowBlocklist {
  const AllowBlocklist({
    this.allowlist = const [],
    this.blocklist = const [],
  });

  /// Converts a JSON [Map] to [AllowBlocklist].
  factory AllowBlocklist.fromJson(Map map) => AllowBlocklist(
        allowlist: (map['allowlist'] as List? ?? []).cast(),
        blocklist: (map['blocklist'] as List? ?? []).cast(),
      );

  /// Whitelist data.
  final List<String> allowlist;

  /// Blacklist data.
  final List<String> blocklist;

  /// Converts [AllowBlocklist] to a JSON [Map].
  Map<String, dynamic> toJson() => {
        'allowlist': allowlist,
        'blocklist': blocklist,
      };
}

/// Domain Whitelist and Blacklist.
typedef DomainBlocklist = AllowBlocklist;

/// Package Whitelist and Blacklist.
typedef PackageBlocklist = AllowBlocklist;

/// Object Whitelist and Blacklist.
typedef ObjectBlocklist = AllowBlocklist;

/// CoinType Whitelist and Blacklist.
typedef CoinBlocklist = AllowBlocklist;

/// Error for callbacks that are to report a [Error] or [Exception] and [StackTrace]
typedef ErrorCallback = void Function(dynamic error, [StackTrace?]);

/// Blocklist type
enum BlocklistStorageKey {
  domainBlocklist("DOMAIN_LIST"),
  userAllowlist("USER_ALLOWLIST"),
  packageBlocklist("PACKAGE_LIST"),
  objectBlocklist("OBJECT_LIST:"),
  coinBlocklist("COIN_LIST"),
  ;

  const BlocklistStorageKey(this.key);

  /// Storage key name.
  final String key;

  @override
  String toString() => name;
}

/// Memory Storage interface
abstract interface class BlocklistStorage<T> {
  /// Get the blocklist of [key]
  FutureOr<AllowBlocklist?> getItem(BlocklistStorageKey key);

  /// Storage the blocklist of [key]
  /// * [key] blocklist type
  /// * [data] blocklist data
  FutureOr<void> setItem(BlocklistStorageKey key, AllowBlocklist? data);
}
