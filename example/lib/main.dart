import 'scan_coin.dart' as scan_coin;
import 'scan_nft.dart' as scan_nft;
import 'scan_package.dart' as scan_package;

Future<void> main() async {
  await Future.wait([
    scan_coin.main(),
    scan_nft.main(),
    scan_package.main(),
  ]);
}
