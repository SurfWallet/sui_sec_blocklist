import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:sui_sec_blocklist/sui_sec_blocklist.dart';
import 'package:url_launcher/url_launcher_string.dart';

Stream<Widget> scanDomain() async* {
  const domains = {
    "https://sui.io",
    "deepbook.tech",
    "https://app.cetus.zone/swap",
    "https://a1.b2.deepbook.cetus.zone",
    "https://deepbook.cetus.zone/v2",
    "https://scam-cetus.zone/swap", //block
    "https://scam.scam-cetus.zone/swap", //block
    "https://scam1.scam2.scam-cetus.zone/swap", //block
    "https://500-airdrop.top", //block
  };
  final blocklist = SuiSecBlocklist();

  var spans = <TextSpan>[
    TextSpan(
      text: 'scanDomain:\n',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
    ),
  ];
  yield Text.rich(TextSpan(children: spans));
  for (final d in domains) {
    final action = await blocklist.scanDomain(d);
    spans = [
      ...spans,
      TextSpan(
        text: "${action == Action.block ? '' : 'NOT-'}BLOCK domain ",
        children: [
          TextSpan(
            text: d,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrlString(
                  d.startsWith(RegExp('http')) ? d : 'https://$d'),
            style: TextStyle(decoration: TextDecoration.underline),
          ),
          TextSpan(text: '\n' * 2),
        ],
        style: TextStyle(
            color: action == Action.block ? Colors.red : Colors.green),
      ),
    ];
    yield Text.rich(TextSpan(children: spans));
  }
}
