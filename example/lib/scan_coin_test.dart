import 'package:sui_sec_blocklist/sui_sec_blocklist.dart';

import 'network.dart';
import 'sui_client.dart';

void main() async {
  const address =
      "0xdbc960ad75905c118c664329af8ddc6624452075c360de1d7e7a9a948d1732ef";
  const network = Network.mainnet;
  const client = SuiClient(network: network);
  final suiScan = SuiScan(network: network);
  final blocklist = SuiSecBlocklist();

  final ownBalances = await client.getAllBalances(address);
  var find = false;
  for (final coinBalance in ownBalances) {
    final coinType = coinBalance.coinType;
    final action = await blocklist.scanCoin(coinType);
    if (action == Action.block) {
      find = true;
      print("BLOCK Coin ${[
        'coinType=$coinType',
        suiScan.getObjectIdUrl(coinType),
      ].join('\n')}");
    }
  }
  assert(find);
}
