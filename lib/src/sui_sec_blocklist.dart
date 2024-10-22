import 'dart:async';

import 'package:sui_sec_blocklist/src/storage/in_memory_storage.dart';

import 'types.dart';
import 'utils.dart' as utils;
import 'utils.dart';

/// The sui security blocklist client. Guardians - Phishing Website Protection
class SuiSecBlocklist {
  /// * [storage] the blocklist cache storage. Default is [InMemoryStorage].
  /// * [reportError] is called with the error and possibly stack trace.
  /// * [debugLog] if set true, print fetch log.
  SuiSecBlocklist({
    BlocklistStorage? storage,
    void Function(dynamic, [StackTrace?])? reportError,
    bool debugLog = false,
  })  : _debugLog = debugLog,
        _reportError = reportError,
        _storage = storage ?? InMemoryStorage();

  final bool _debugLog;
  final BlocklistStorage _storage;
  final ErrorCallback? _reportError;

  /// Prints an log message to the console.
  /// * [message] log message.
  void logger(String message) {
    if (_debugLog) {
      print(message);
    }
  }

  /// fetch domain whitelist and blacklist.
  Future<void> fetchDomainList() {
    return _fetchAllowBlocklist(BlocklistStorageKey.domainBlocklist);
  }

  /// scan domain, if return [Action.block], the [url] is in blocklist.
  /// * [url] scan the domain.
  Future<Action> scanDomain(String url) {
    return _scan(url, BlocklistStorageKey.domainBlocklist);
  }

  /// fetch package whitelist and blacklist.
  Future<void> fetchPackageList() {
    return _fetchAllowBlocklist(BlocklistStorageKey.packageBlocklist);
  }

  /// scan package address, if return [Action.block], the package [address] is in blocklist.
  /// * [address] the package address.
  Future<Action> scanPackage(String address) {
    return _scan(address, BlocklistStorageKey.packageBlocklist);
  }

  /// fetch object whitelist and blacklist.
  Future<void> fetchObjectList() {
    return _fetchAllowBlocklist(BlocklistStorageKey.objectBlocklist);
  }

  /// scan object type, if return [Action.block], the [object] is in blocklist.
  /// * [object] the object type.
  Future<Action> scanObject(String object) {
    return _scan(object, BlocklistStorageKey.objectBlocklist);
  }

  /// fetch coinType whitelist and blacklist.
  Future<void> fetchCoinList() {
    return _fetchAllowBlocklist(BlocklistStorageKey.coinBlocklist);
  }

  /// scan coin type, if return [Action.block], the [coinType] is in blocklist.
  /// * [coinType] the coin type
  Future<Action> scanCoin(String coinType) {
    return _scan(coinType, BlocklistStorageKey.coinBlocklist);
  }

  Future<void> _fetchAllowBlocklist(BlocklistStorageKey key) async {
    logger("_fetchAllowBlocklist($key) start");
    final blocklist = switch (key) {
      BlocklistStorageKey.domainBlocklist => await utils.fetchDomainBlocklist(),
      BlocklistStorageKey.coinBlocklist => await utils.fetchCoinBlocklist(),
      BlocklistStorageKey.packageBlocklist =>
        await utils.fetchPackageBlocklist(),
      BlocklistStorageKey.objectBlocklist => await utils.fetchObjectBlocklist(),
      BlocklistStorageKey.userAllowlist => null,
    };

    logger("_fetchAllowBlocklist($key) fetched: $blocklist");

    if (blocklist == null) {
      logger("_fetchAllowBlocklist($key) fail 1 $blocklist");
      _reportError?.call(Exception("Failed to fetch blocklist"));
      return;
    }
    await _storage.setItem(key, blocklist);
    logger("_fetchAllowBlocklist($key) success $blocklist");
  }

  /// Get user locally custom whitelist and blacklist.
  Future<AllowBlocklist?> getUserAllowDomainLocally() async {
    final allowBlocklist =
        await _storage.getItem(BlocklistStorageKey.userAllowlist);
    return allowBlocklist;
  }

  /// User locally custom allow [domain].
  /// * [domain] custom allow the [domain].
  Future<void> allowDomainLocally(String domain) async {
    var allowBlocklist = await getUserAllowDomainLocally();
    var allowlist = allowBlocklist?.allowlist ?? <String>[];
    allowlist = [...allowlist, domain];
    allowBlocklist = AllowBlocklist(
      allowlist: [...allowlist, domain],
      blocklist: allowBlocklist?.blocklist ?? [],
    );
    await _storage.setItem(BlocklistStorageKey.userAllowlist, allowBlocklist);
    logger("allowDomainLocally success");
  }

  Future<Action> _scan(String value, BlocklistStorageKey key) async {
    logger("scan($key) start");
    var storedBlocklist = await _storage.getItem(key);

    logger("scan($key) fetch 1 $storedBlocklist");

    if (storedBlocklist == null) {
      final _ = switch (key) {
        BlocklistStorageKey.domainBlocklist =>
          await withRetry(() => fetchDomainList(), 3),
        BlocklistStorageKey.coinBlocklist =>
          await withRetry(() => fetchCoinList(), 3),
        BlocklistStorageKey.packageBlocklist =>
          await withRetry(() => fetchPackageList(), 3),
        BlocklistStorageKey.objectBlocklist =>
          await withRetry(() => fetchObjectList(), 3),
        BlocklistStorageKey.userAllowlist => null,
      };

      storedBlocklist = await _storage.getItem(key);
      logger("scan($key) fetch 2 $storedBlocklist");
    }

    if (storedBlocklist == null) {
      logger("scan($key) error $storedBlocklist");
      _reportError?.call(Exception("Failed to fetch blocklist"));
      return Action.none;
    }

    final action = switch (key) {
      BlocklistStorageKey.domainBlocklist =>
        utils.scanDomain(storedBlocklist.blocklist, value),
      BlocklistStorageKey.coinBlocklist =>
        utils.scanCoin(storedBlocklist.blocklist, value),
      BlocklistStorageKey.packageBlocklist =>
        utils.scanPackage(storedBlocklist.blocklist, value),
      BlocklistStorageKey.objectBlocklist =>
        utils.scanObject(storedBlocklist.blocklist, value),
      BlocklistStorageKey.userAllowlist => Action.none,
    };

    if (action == Action.block) {
      logger("scan($key) BLOCK");
      final allowlist =
          await getUserAllowDomainLocally().then((v) => v?.allowlist ?? []);
      final hostname = Uri.tryParse(value)?.host;
      if (allowlist.contains(hostname)) {
        logger("scan($key) allowlist $allowlist $hostname");
        return Action.none;
      }
    }

    logger("scan($key) action $action");

    return action;
  }
}
