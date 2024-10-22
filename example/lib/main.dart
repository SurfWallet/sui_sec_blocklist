import 'package:flutter/material.dart' hide Action;

import 'scan_coin.dart';
import 'scan_nft.dart';
import 'scan_package.dart';

void main() {
  runApp(MaterialApp(home: _HomePage()));
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  @override
  void initState() {
    super.initState();
    scan();
  }

  void scan() async {
    await Future.wait([
      scanCoin(),
      scanNFT(),
      scanPackage(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
