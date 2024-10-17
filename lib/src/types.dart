import 'dart:async';

enum Action {
  block,
  none,
}

class AllowBlocklist {
  const AllowBlocklist({
    this.allowlist = const [],
    this.blocklist = const [],
  });

  factory AllowBlocklist.fromJson(Map map) => AllowBlocklist(
        allowlist: (map['allowlist'] as List? ?? []).cast(),
        blocklist: (map['blocklist'] as List? ?? []).cast(),
      );
  final List<String> allowlist;
  final List<String> blocklist;

  Map<String, dynamic> toJson() => {
        'allowlist': allowlist,
        'blocklist': blocklist,
      };
}

typedef DomainBlocklist = AllowBlocklist;
typedef PackageBlocklist = AllowBlocklist;
typedef ObjectBlocklist = AllowBlocklist;
typedef CoinBlocklist = AllowBlocklist;

typedef ErrorCallback = void Function(dynamic error, [StackTrace?]);

enum BlocklistStorageKey {
  domainBlocklist("DOMAIN_LIST"),
  userAllowlist("USER_ALLOWLIST"),
  packageBlocklist("PACKAGE_LIST"),
  objectBlocklist("OBJECT_LIST:"),
  coinBlocklist("COIN_LIST"),
  ;

  const BlocklistStorageKey(this.key);

  final String key;

  @override
  String toString() => name;
}

abstract interface class BlocklistStorage<T> {
  FutureOr<AllowBlocklist?> getItem(BlocklistStorageKey key);

  FutureOr<void> setItem(BlocklistStorageKey key, AllowBlocklist? data);
}
