import 'dart:async';
import 'dart:io';

import 'package:sui_sec_blocklist/src/storage/in_memory_storage.dart';

import 'types.dart';
import 'utils.dart' as utils;
import 'utils.dart';

class SuiSecBlocklist {
  SuiSecBlocklist({
    BlocklistStorage? storage,
    this.reportError,
    this.debugLog = false,
  }) : storage = storage ?? InMemoryStorage();

  final bool debugLog;
  final BlocklistStorage storage;
  final ErrorCallback? reportError;

  void logger(String message) {
    if (debugLog) {
      stdout.writeln(message);
    }
  }

  Future<void> fetchDomainList() {
    return _fetchAllowBlocklist(BlocklistStorageKey.domainBlocklist);
  }

  Future<Action> scanDomain(String url) {
    return _scan(url, BlocklistStorageKey.domainBlocklist);
  }

  Future<void> fetchPackageList() {
    return _fetchAllowBlocklist(BlocklistStorageKey.packageBlocklist);
  }

  Future<Action> scanPackage(String address) {
    return _scan(address, BlocklistStorageKey.packageBlocklist);
  }

  Future<void> fetchObjectList() {
    return _fetchAllowBlocklist(BlocklistStorageKey.objectBlocklist);
  }

  Future<Action> scanObject(String object) {
    return _scan(object, BlocklistStorageKey.objectBlocklist);
  }

  Future<void> fetchCoinList() {
    return _fetchAllowBlocklist(BlocklistStorageKey.coinBlocklist);
  }

  Future<Action> scanCoin(String coin) {
    return _scan(coin, BlocklistStorageKey.coinBlocklist);
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
      reportError?.call(Exception("Failed to fetch blocklist"));
      return;
    }

    await storage.setItem(key, blocklist);
    logger("_fetchAllowBlocklist($key) success $blocklist");
  }

  Future<AllowBlocklist?> getUserAllowDomainLocally() async {
    final allowBlocklist =
        await storage.getItem(BlocklistStorageKey.userAllowlist);
    return allowBlocklist;
  }

  Future<void> allowDomainLocally(String domain) async {
    var allowBlocklist = await getUserAllowDomainLocally();
    var allowlist = allowBlocklist?.allowlist ?? <String>[];
    allowlist = [...allowlist, domain];
    allowBlocklist = AllowBlocklist(
      allowlist: [...allowlist, domain],
      blocklist: allowBlocklist?.blocklist ?? [],
    );
    await storage.setItem(BlocklistStorageKey.userAllowlist, allowBlocklist);
    logger("allowDomainLocally success");
  }

  Future<Action> _scan(String value, BlocklistStorageKey key) async {
    logger("scan($key) start");
    var storedBlocklist = await storage.getItem(key);

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

      storedBlocklist = await storage.getItem(key);
      logger("scan($key) fetch 2 $storedBlocklist");
    }

    if (storedBlocklist == null) {
      logger("scan($key) error $storedBlocklist");
      reportError?.call(Exception("Failed to fetch blocklist"));
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
