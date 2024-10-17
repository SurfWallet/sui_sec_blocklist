import 'package:sui_sec_blocklist/sui_sec_blocklist.dart';
import 'package:test/test.dart';

import 'network.dart';
import 'sui_client.dart';

void main() {
  test('ScanNFT', () async {
    const address =
        "0xdbc960ad75905c118c664329af8ddc6624452075c360de1d7e7a9a948d1732ef";
    const network = Network.mainnet;
    const client = SuiClient(network: network);
    final suiScan = SuiScan(network: network);
    final blocklist = SuiSecBlocklist();
    final ownObjects = await client.getOwnedObjects(address);
    var find = false;
    for (final obj in ownObjects) {
      final objectId = obj.objectId;
      final objectType = obj.objectType;
      final action = await blocklist.scanObject(objectType ?? '');
      if (action == Action.block) {
        find = true;
        print("BLOCK NFT ${[
          'objectId=$objectId',
          'objectType=$objectType',
          suiScan.getObjectIdUrl(objectId),
        ].join('\n')}");
      } else {
        // print("NORMAL $objectId $objectType\n${suiScan.getObjectIdUrl(objectId)}");
      }
    }
    expect(find, true);
  });
}
