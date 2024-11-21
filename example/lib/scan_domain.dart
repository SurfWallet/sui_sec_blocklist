import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:sui_sec_blocklist/sui_sec_blocklist.dart';
import 'package:url_launcher/url_launcher_string.dart';

Stream<Widget> scanDomain() async* {
  const domains = {
    "https://sui.io",
    "https://sui.io/",
    "deepbook.tech",
    "deepbook.tech/",
    "https://app.cetus.zone/swap",
    "https://a1.b2.deepbook.cetus.zone",
    "https://deepbook.cetus.zone/v2",
    "https://www.volo.fi",
    "https://volosui.com",
    "https://scam-cetus.zone/swap", //block
    "https://scam.scam-cetus.zone/swap", //block
    "https://scam1.scam2.scam-cetus.zone/swap", //block
    "https://scam-cetus.zone/", //block
    "scam-cetus.zone/", //block
    "https://500-airdrop.top", //block
    "https://500-airdrop.top/", //block
    "500-airdrop.top", //block
    "500-airdrop.top/", //block
  };
  final blocklist = SuiSecBlocklist();

  var spans = <TextSpan>[
    TextSpan(
      text: 'scanDomain:\n',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
    ),
  ];
  yield Text.rich(TextSpan(children: spans));
  for (final list in domains.slices(5)) {
    final actionList = await blocklist.scanDomain(list);
    spans = [
      ...spans,
      ...List.generate(actionList.length, (index) {
        final action = actionList[index];
        final domain = list[index];
        return TextSpan(
          text: "${action == Action.block ? '' : 'NOT-'}BLOCK domain ",
          children: [
            TextSpan(
              text: domain,
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchUrlString(
                    domain.startsWith(RegExp('http'))
                        ? domain
                        : 'https://$domain'),
              style: TextStyle(decoration: TextDecoration.underline),
            ),
            TextSpan(text: '\n' * 2),
          ],
          style: TextStyle(
              color: action == Action.block ? Colors.red : Colors.green),
        );
      })
    ];
    yield Text.rich(TextSpan(children: spans));
  }
}
