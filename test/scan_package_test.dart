import 'package:sui_sec_blocklist/sui_sec_blocklist.dart';
import 'package:test/test.dart';

import 'network.dart';

void main() {
  test('ScanPackage', () async {
    const network = Network.mainnet;
    final suiScan = SuiScan(network: network);
    final blocklist = SuiSecBlocklist();
    const packages = [
      '0xd89d1288e1d0a69cc7e5a30625c238e2310e4c23221557b819174f8c14b31ef8',
      "0x154774ad8a1038ad492534f9d2c4457e3efdf43083a789bac7fb6c6976777977",
      "0x40d77dc33c27eeb6d80676c590b392051abd19086b2b37910b298a97538e0950",
    ];
    var find = false;
    for (final p in packages) {
      final action = await blocklist.scanPackage(p);
      if (action == Action.block) {
        find = true;
        print("BLOCK package ${[
          'package=$p',
          suiScan.getObjectIdUrl(p),
        ].join('\n')}");
      } else {}
    }
    expect(find, true);
  });
}
