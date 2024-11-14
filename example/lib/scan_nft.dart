import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:sui_sec_blocklist/sui_sec_blocklist.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'network.dart';
import 'sui_client.dart';

Stream<Widget> scanNFT() async* {
  const address =
      "0xdbc960ad75905c118c664329af8ddc6624452075c360de1d7e7a9a948d1732ef";
  const network = Network.mainnet;
  const client = SuiClient(network: network);
  final suiScan = SuiScan(network: network);
  final ownObjects = await client.getOwnedObjects(address);
  var spans = <TextSpan>[
    TextSpan(
      text: 'scanNFT:\n',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
    ),
  ];

  yield Text.rich(TextSpan(children: spans));
  final blocklist = SuiSecBlocklist();
  for (var objList in ownObjects.slices(5)) {
    objList = objList.where((o) => o.objectType != null).toList();
    final objectTypes = objList.map((e) => e.objectType!).toList();
    final actions = await blocklist.scanObject(objectTypes);

    spans = [
      ...spans,
      ...List.generate(actions.length, (index) {
        final action = actions[index];
        final objectId = objList[index].objectId;
        final objectType = objList[index].objectType;
        return TextSpan(
          text: "${action == Action.block ? '' : 'NOT-'}BLOCK NFT ",
          children: [
            if (objectType?.isNotEmpty ?? false)
              TextSpan(
                text: 'objectType=$objectType',
                recognizer: TapGestureRecognizer()
                  ..onTap = () =>
                      launchUrlString(suiScan.getObjectIdUrl(objectType ?? '')),
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            TextSpan(
              text: 'objectId=$objectId',
              recognizer: TapGestureRecognizer()
                ..onTap =
                    () => launchUrlString(suiScan.getObjectIdUrl(objectId)),
              style: TextStyle(decoration: TextDecoration.underline),
            ),
            TextSpan(text: '\n' * 2),
          ],
          style: TextStyle(
              color: action == Action.block ? Colors.red : Colors.green),
        );
      }),
    ];
    yield Text.rich(TextSpan(children: spans));
  }
}
