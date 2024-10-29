import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:sui_sec_blocklist/sui_sec_blocklist.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'network.dart';
import 'sui_client.dart';

Stream<Widget> scanCoin() async* {
  const address =
      "0xdbc960ad75905c118c664329af8ddc6624452075c360de1d7e7a9a948d1732ef";
  const network = Network.mainnet;
  const client = SuiClient(network: network);
  final suiScan = SuiScan(network: network);
  final blocklist = SuiSecBlocklist();

  var spans = <TextSpan>[
    TextSpan(
      text: 'scanCoin:\n',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
    ),
    TextSpan(
      text: 'address: $address\n',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.underline,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () => launchUrlString(suiScan.getSuiAddressUrl(address)),
    ),
  ];
  yield Text.rich(TextSpan(children: spans));

  final ownBalances = await client.getAllBalances(address);

  for (final coinBalance in ownBalances) {
    final coinType = coinBalance.coinType;
    final action = await blocklist.scanCoin(coinType);
    spans = [
      ...spans,
      TextSpan(
        text: "${action == Action.block ? '' : 'NOT-'}BLOCK Coin ",
        children: [
          TextSpan(
            text: coinType,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrlString(suiScan.getObjectIdUrl(coinType)),
            style: TextStyle(decoration: TextDecoration.underline),
          ),
          TextSpan(text: '\n' * 2),
        ],
        style: TextStyle(
            color: action == Action.block ? Colors.red : Colors.green),
      )
    ];

    yield Text.rich(TextSpan(children: spans));
  }
}
