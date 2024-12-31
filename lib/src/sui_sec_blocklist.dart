import 'dart:async';
import 'dart:isolate';

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
  Future<DomainBlocklist?> fetchDomainList() {
    return _fetchAllowBlocklist(BlocklistStorageKey.domainBlocklist);
  }

  /// scan domain, if return [Action.block], the [urls] is in blocklist.
  /// * [urls] scan the domain.
  Future<List<Action>> scanDomain(List<String> urls, {bool autoFetch = true}) {
    return _scan(
      urls,
      BlocklistStorageKey.domainBlocklist,
      autoFetch: autoFetch,
    );
  }

  /// fetch package whitelist and blacklist.
  Future<DomainBlocklist?> fetchPackageList() {
    return _fetchAllowBlocklist(BlocklistStorageKey.packageBlocklist);
  }

  /// scan package address, if return [Action.block], the package [addresses] is in blocklist.
  /// * [addresses] the package addresses.
  Future<List<Action>> scanPackage(List<String> addresses,
      {bool autoFetch = true}) {
    return _scan(
      addresses,
      BlocklistStorageKey.packageBlocklist,
      autoFetch: autoFetch,
    );
  }

  /// fetch object whitelist and blacklist.
  Future<DomainBlocklist?> fetchObjectList() {
    return _fetchAllowBlocklist(BlocklistStorageKey.objectBlocklist);
  }

  /// scan object type, if return [Action.block], the [objectTypes] is in blocklist.
  /// * [objectTypes] the object type.
  Future<List<Action>> scanObject(List<String> objectTypes,
      {bool autoFetch = true}) {
    return _scan(
      objectTypes,
      BlocklistStorageKey.objectBlocklist,
      autoFetch: autoFetch,
    );
  }

  /// fetch coinType whitelist and blacklist.
  Future<DomainBlocklist?> fetchCoinList() {
    return _fetchAllowBlocklist(BlocklistStorageKey.coinBlocklist);
  }

  /// scan coin type, if return [Action.block], the [coinTypes] is in blocklist.
  /// * [coinTypes] the coin type
  Future<List<Action>> scanCoin(List<String> coinTypes,
      {bool autoFetch = true}) {
    return _scan(
      coinTypes,
      BlocklistStorageKey.coinBlocklist,
      autoFetch: autoFetch,
    );
  }

  Future<DomainBlocklist?> _fetchAllowBlocklist(BlocklistStorageKey key) async {
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
      return null;
    }
    await _storage.setItem(key, blocklist);
    logger("_fetchAllowBlocklist($key) success $blocklist");
    return blocklist;
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

  static final _fetchedKeys = <BlocklistStorageKey>{};

  Future<List<Action>> _scan(
    List<String> values,
    BlocklistStorageKey key, {
    bool autoFetch = true,
  }) async {
    if (values.isEmpty) return List.empty();
    logger("scan($key) start");
    var storedBlocklist = await _storage.getItem(key);

    logger("scan($key) fetch local storage $storedBlocklist");

    if ((storedBlocklist == null || !_fetchedKeys.contains(key)) && autoFetch) {
      final list = switch (key) {
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

      if (list != null) {
        _fetchedKeys.add(key);
      }

      storedBlocklist = await _storage.getItem(key);
      logger("scan($key) fetch $storedBlocklist");
    }

    if (storedBlocklist == null) {
      logger("scan($key) error $storedBlocklist");
      _reportError?.call(Exception("Failed to fetch blocklist"));
      final results =
          List.generate(values.length, (i) => Action.none, growable: false);
      if (!autoFetch && key == BlocklistStorageKey.domainBlocklist) {
        final userLocally = await getUserAllowDomainLocally();
        final blocklist = userLocally?.blocklist ?? <String>{};
        for (var i = 0; i < values.length; i++) {
          final value = values[i].trim();
          final hostname = Uri.tryParse(value)?.host;
          if (blocklist.contains(hostname)) {
            results[i] = Action.block;
          }
        }
      }
      return results;
    }
    final results = key == BlocklistStorageKey.userAllowlist
        ? List.generate(values.length, (i) => Action.none, growable: false)
        : await Isolate.run(() {
            return List.generate(values.length, (index) {
              final value = values[index].trim();
              final action = switch (key) {
                BlocklistStorageKey.domainBlocklist =>
                  utils.scanDomain(storedBlocklist!, value),
                BlocklistStorageKey.coinBlocklist =>
                  utils.scanCoin(storedBlocklist!.blocklist, value),
                BlocklistStorageKey.packageBlocklist =>
                  utils.scanPackage(storedBlocklist!.blocklist, value),
                BlocklistStorageKey.objectBlocklist =>
                  utils.scanObject(storedBlocklist!.blocklist, value),
                BlocklistStorageKey.userAllowlist => Action.none,
              };
              return action;
            });
          });

    //scan from UserAllowDomainLocally
    if (key == BlocklistStorageKey.domainBlocklist) {
      for (var i = 0; i < results.length; i++) {
        final action = results[i];
        if (action == Action.block) {
          final value = values[i];
          logger("scan($key) BLOCK");
          final userLocally = await getUserAllowDomainLocally();
          final allowlist = userLocally?.allowlist ?? [];
          final hostname = Uri.tryParse(value)?.host;
          if (allowlist.contains(hostname)) {
            logger("scan($key) allowlist $allowlist $hostname");
            results[i] = Action.none;
          }
        }
        logger("scan($key) action $action");
      }
    }

    return results;
  }
}
