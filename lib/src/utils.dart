import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import 'types.dart';

/// default domain blocklist json url
const _kDefaultBlocklistUrl = [
  "https://guardians.suiet.app/domain-list.json",
  "https://raw.githubusercontent.com/suiet/guardians/main/src/domain-list.json",
];

/// default coinType blocklist json url
const _kDefaultCoinUrl = [
  "https://guardians.suiet.app/coin-list.json",
  "https://raw.githubusercontent.com/suiet/guardians/main/src/coin-list.json",
];

/// default package blocklist json url
const _kDefaultPackageUrl = [
  "https://guardians.suiet.app/package-list.json",
  "https://raw.githubusercontent.com/suiet/guardians/main/src/package-list.json",
];

/// default object type blocklist json url
const _kDefaultObjectUrl = [
  "https://guardians.suiet.app/object-list.json",
  "https://raw.githubusercontent.com/suiet/guardians/main/src/object-list.json",
];

const _kDomainMap = {
  "cetus": "cetus.zone",
  "scallop": "scallop.io",
  "navi": "naviprotocol.io",
  "navx": "naviprotocol.io",
  "suilend": "suilend.fi",
  "bucket": "bucketprotocol.io",
  "turbos": "turbos.finance",
  "flowx": "flowx.finance",
  "kriya": "kriya.finance",
  "typus": "typus.finance",
  "aftermath": "aftermath.finance",
  "bluefin": "bluefin.io",
  "haedal": "haedal.xyz",
  "volo": "volosui.com",
  "alphafi": "alphafi.xyz",
  "deepbook": "deepbook.tech",
};

Future<AllowBlocklist?> _fetchAnyAllowBlocklist(
  Iterable<String> urls, {
  ErrorCallback? reportError,
}) async {
  for (final url in urls) {
    final allowBlocklist =
        await _fetchAllowBlocklist(url, reportError: reportError);
    if (allowBlocklist != null) {
      return allowBlocklist;
    }
  }
  return null;
}

Future<AllowBlocklist?> _fetchAllowBlocklist(
  String url, {
  ErrorCallback? reportError,
}) {
  return http.get(
    Uri.parse(url),
    headers: {'content-type': 'application/json'},
  ).then<AllowBlocklist?>((response) async {
    if (response.notOk) {
      reportError?.call(
          Exception(response.reasonPhrase ?? response.statusCode.toString()));
      return null;
    }
    final allowBlocklist = await Isolate.run(() {
      final map = const Utf8Decoder(allowMalformed: true)
          .fuse(const JsonDecoder())
          .convert(response.bodyBytes) as Map;
      return AllowBlocklist.fromJson(map);
    });
    return allowBlocklist;
  }).catchError((e, s) {
    reportError?.call(e, s);
    return null;
  });
}

/// Fetch domain whitelist and blacklist.
Future<DomainBlocklist?> fetchDomainBlocklist({
  ErrorCallback? reportError,
}) {
  return _fetchAnyAllowBlocklist(_kDefaultBlocklistUrl,
      reportError: reportError);
}

/// Scan the [url] in [blocklist].
Action scanDomain(List<String> blocklist, String url) {
  url = url.trim();
  final domain = url.startsWith(RegExp('http', caseSensitive: false))
      ? Uri.tryParse(url)?.host.toLowerCase() ??
          Uri.parse('https://$url').host.toLowerCase()
      : Uri.parse('https://$url').host.toLowerCase();
  final domainParts = domain.split(".");

  for (var i = 0; i < domainParts.length - 1; i++) {
    final domainToLookup = domainParts.sublist(i).join(".");
    if (blocklist.contains(domainToLookup)) {
      return Action.block;
    }
  }

  for (var whitelistDomain in _kDomainMap.values) {
    whitelistDomain = whitelistDomain.toLowerCase();
    final whitelistDomainParts = whitelistDomain.split(".");
    final slice = domainParts
        .sublist(max(0, domainParts.length - whitelistDomainParts.length));
    //https://deepbook.cetus.zone is NOT-BLOCK
    if (slice.join('.') == whitelistDomain) {
      return Action.none;
    }
  }

  for (final key in _kDomainMap.keys) {
    if (domain.contains(key)) {
      final whitelistDomain = _kDomainMap[key]!.toLowerCase();
      if (domainParts.length == whitelistDomain.split(".").length) {
        //scam-aaa.com
        return domain != whitelistDomain ? Action.block : Action.none;
      } else if (!domain.endsWith('.$whitelistDomain')) {
        //app.scam-aaa.com
        return Action.block;
      }
    }
  }
  return Action.none;
}

/// Retry [action] [times] if [action] throw error.
FutureOr<T> withRetry<T>(FutureOr<T> Function() action, [int times = 3]) async {
  try {
    return await action();
  } catch (e, _) {
    if (times <= 0) {
      rethrow;
    }
    return withRetry(action, times - 1);
  }
}

/// Fetch package whitelist and blacklist.
Future<PackageBlocklist?> fetchPackageBlocklist({
  ErrorCallback? reportError,
}) {
  return _fetchAnyAllowBlocklist(_kDefaultPackageUrl, reportError: reportError);
}

/// Scan the package [address] in [packageList].
Action scanPackage(List<String> packageList, String address) {
  return packageList.contains(address) ? Action.block : Action.none;
}

/// Fetch object whitelist and blacklist.
Future<ObjectBlocklist?> fetchObjectBlocklist({
  ErrorCallback? reportError,
}) {
  return _fetchAnyAllowBlocklist(_kDefaultObjectUrl, reportError: reportError);
}

/// Scan the [object] in [objectList].
Action scanObject(List<String> objectList, String object) {
  return objectList.contains(object) ? Action.block : Action.none;
}

/// Fetch coin whitelist and blacklist.
Future<CoinBlocklist?> fetchCoinBlocklist({
  ErrorCallback? reportError,
}) {
  return _fetchAnyAllowBlocklist(_kDefaultCoinUrl, reportError: reportError);
}

/// Scan the [coinType] in [coinList].
Action scanCoin(List<String> coinList, String coinType) {
  return coinList.contains(coinType) ? Action.block : Action.none;
}

extension on Response {
  bool get notOk => !ok;

  bool get ok => statusCode >= 200 && statusCode <= 299;
}
