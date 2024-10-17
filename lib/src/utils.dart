// ignore_for_file: constant_identifier_names
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import 'types.dart';

const DEFAULT_BLOCKLIST_URL =
    "https://raw.githubusercontent.com/suiet/guardians/main/src/domain-list.json";
const DEFAULT_COIN_URL =
    "https://raw.githubusercontent.com/suiet/guardians/main/src/coin-list.json";
const DEFAULT_PACKAGE_URL =
    "https://raw.githubusercontent.com/suiet/guardians/main/src/package-list.json";
const DEFAULT_OBJECT_URL =
    "https://raw.githubusercontent.com/suiet/guardians/main/src/object-list.json";

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

Future<AllowBlocklist?> _fetchAllowBlocklist(
  String url, {
  ErrorCallback? reportError,
}) {
  return http.get(
    Uri.parse(url),
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
  ).then<AllowBlocklist?>((response) {
    if (response.notOk) {
      reportError?.call(HttpException(
          response.reasonPhrase ?? response.statusCode.toString()));
      return null;
    }
    final map = jsonDecode(response.body) as Map;
    return AllowBlocklist.fromJson(map);
  }).catchError((e, s) {
    reportError?.call(e, s);
    return null;
  });
}

Future<DomainBlocklist?> fetchDomainBlocklist({
  ErrorCallback? reportError,
}) {
  return _fetchAllowBlocklist(DEFAULT_BLOCKLIST_URL, reportError: reportError);
}

Action scanDomain(List<String> blocklist, String url) {
  final domain = Uri.parse(url).host.toLowerCase();
  final domainParts = domain.split(".");

  for (var i = 0; i < domainParts.length - 1; i++) {
    final domainToLookup = domainParts.sublist(i).join(".");
    if (blocklist.contains(domainToLookup)) {
      return Action.block;
    }
  }

  for (final key in _kDomainMap.keys) {
    if (domain.contains(key)) {
      if (domain != _kDomainMap[key]) {
        return Action.block;
      }
    }
  }
  return Action.none;
}

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

Future<PackageBlocklist?> fetchPackageBlocklist({
  ErrorCallback? reportError,
}) {
  return _fetchAllowBlocklist(DEFAULT_PACKAGE_URL, reportError: reportError);
}

Action scanPackage(List<String> packageList, String address) {
  return packageList.contains(address) ? Action.block : Action.none;
}

Future<ObjectBlocklist?> fetchObjectBlocklist({
  ErrorCallback? reportError,
}) {
  return _fetchAllowBlocklist(DEFAULT_OBJECT_URL, reportError: reportError);
}

Action scanObject(List<String> objectList, String object) {
  return objectList.any((e) {
    return e.contains(RegExp(object, caseSensitive: false)) ||
        object.contains(RegExp(e, caseSensitive: false));
    ;
  })
      ? Action.block
      : Action.none;
}

Future<CoinBlocklist?> fetchCoinBlocklist({
  ErrorCallback? reportError,
}) {
  return _fetchAllowBlocklist(DEFAULT_COIN_URL, reportError: reportError);
}

Action scanCoin(List<String> coinList, String coin) {
  return coinList.contains(coin) ? Action.block : Action.none;
}

extension on Response {
  bool get notOk => !ok;

  bool get ok => statusCode >= 200 && statusCode <= 299;
}
