import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'network.dart';

class SuiClient {
  const SuiClient({this.network = Network.mainnet});

  final Network network;

  String get rpc => network.rpc;

  Future<List<CoinBalance>> getAllBalances(String address) async {
    final response = await http.post(
      Uri.parse(rpc),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "suix_getAllBalances",
        "params": [
          address,
        ]
      }),
    );
    final map = jsonDecode(response.body) as Map;
    final list = (map['result'] as List).map((e) => CoinBalance(e)).toList();
    return list;
  }

  Future<List<SuiObjectData>> getOwnedObjects(String owner) async {
    final response = await http.post(
      Uri.parse(rpc),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "suix_getOwnedObjects",
        "params": [
          owner,
          {
            "options": {
              "showType": true,
              "showOwner": true,
              "showPreviousTransaction": true,
              "showDisplay": true,
              "showContent": true,
              "showBcs": false,
              "showStorageRebate": false
            }
          }
        ]
      }),
    );
    final map = jsonDecode(response.body) as Map;
    final dataList = map['result']['data'] as List;
    final list = dataList.map((e) => SuiObjectData(e['data'])).toList();
    return list;
  }
}

class CoinBalance extends MapView {
  const CoinBalance(super.map);

  String get coinType => this['coinType'];

  int get coinObjectCount => this['coinObjectCount'];

  BigInt get totalBalance => BigInt.parse('${this['totalBalance']}');
}

class SuiObjectData extends MapView {
  const SuiObjectData(super.map);

  String get objectId => this['objectId'];

  String? get objectType => this['type'];

  bool get isCoin => objectType?.startsWith('0x2::coin::Coin') == true;
}
