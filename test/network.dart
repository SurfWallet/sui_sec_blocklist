enum Network {
  mainnet('mainnet'),
  testnet('testnet'),
  devnet('devnet'),
  ;

  const Network(this.name);

  final String name;

  String get rpc {
    return switch (this) {
      mainnet => 'https://fullnode.mainnet.sui.io:443',
      testnet => 'https://fullnode.testnet.sui.io:443',
      devnet => 'https://fullnode.devnet.sui.io:443',
    };
  }
}

class SuiScan extends Explorer {
  const SuiScan({required super.network}) : super(host: 'https://suiscan.xyz');

  @override
  String getObjectIdUrl(String objectId) {
    final uri =
        Uri.parse('$host/${network.name.toLowerCase()}/object/$objectId');
    return uri.toString();
  }

  @override
  String getSuiAddressUrl(String address) {
    final uri =
        Uri.parse('$host/${network.name.toLowerCase()}/account/$address');
    return uri.toString();
  }

  @override
  String getTxUrl(String txBlock) {
    final uri = Uri.parse('$host/${network.name.toLowerCase()}/tx/$txBlock');
    return uri.toString();
  }

  @override
  String getCoinUrl(String coinType) {
    final uri = Uri.parse('$host/${network.name.toLowerCase()}/coin/$coinType');
    return uri.toString();
  }
}

class SuiVision extends Explorer {
  factory SuiVision({required Network network}) {
    return switch (network) {
      Network.mainnet => SuiVision.mainnet(),
      Network.testnet => SuiVision.testnet(),
      Network.devnet => SuiVision.devnet(),
    };
  }

  const SuiVision.mainnet()
      : super(host: 'https://suivision.xyz', network: Network.mainnet);

  const SuiVision.testnet()
      : super(host: 'https://testnet.suivision.xyz', network: Network.testnet);

  const SuiVision.devnet()
      : super(host: 'https://devnet.suivision.xyz', network: Network.devnet);

  @override
  String getObjectIdUrl(String objectId) {
    final uri = Uri.parse('$host/object/$objectId');
    return uri.toString();
  }

  @override
  String getSuiAddressUrl(String address) {
    final uri = Uri.parse('$host/account/$address');
    return uri.toString();
  }

  @override
  String getTxUrl(String txBlock) {
    final uri = Uri.parse('$host/txblock/$txBlock');
    return uri.toString();
  }

  @override
  String getCoinUrl(String coinType) {
    final uri = Uri.parse('$host/coin/$coinType');
    return uri.toString();
  }
}

abstract class Explorer {
  const Explorer({required this.host, required this.network});

  final Network network;
  final String host;

  String getTxUrl(String txBlock);

  String getSuiAddressUrl(String address);

  String getObjectIdUrl(String objectId);

  String getCoinUrl(String coinType);
}
