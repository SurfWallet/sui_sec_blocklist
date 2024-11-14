import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:sui_sec_blocklist/sui_sec_blocklist.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'network.dart';

Stream<Widget> scanPackage() async* {
  const network = Network.mainnet;
  final suiScan = SuiScan(network: network);
  const packages = [
    '0xd89d1288e1d0a69cc7e5a30625c238e2310e4c23221557b819174f8c14b31ef8',
    "0x154774ad8a1038ad492534f9d2c4457e3efdf43083a789bac7fb6c6976777977",
    "0x40d77dc33c27eeb6d80676c590b392051abd19086b2b37910b298a97538e0950",
  ];
  var spans = <TextSpan>[
    TextSpan(
      text: 'scanPackage:\n',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
    ),
  ];
  yield Text.rich(TextSpan(children: [...spans]));
  final blocklist = SuiSecBlocklist();

  for (final list in packages.slices(5)) {
    final actions = await blocklist.scanPackage(list);
    spans = [
      ...spans,
      ...List.generate(actions.length, (index) {
        final action = actions[index];
        final p = list[index];
        return TextSpan(
          text: "${action == Action.block ? '' : 'NOT-'}BLOCK package ",
          children: [
            TextSpan(
              text: p,
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchUrlString(suiScan.getObjectIdUrl(p)),
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
