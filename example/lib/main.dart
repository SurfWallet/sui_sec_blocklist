import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'scan_coin.dart';
import 'scan_domain.dart';
import 'scan_nft.dart';
import 'scan_package.dart';

void main() {
  runApp(MaterialApp(home: _HomePage()));
}

class _HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scam Demo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScanResultWidget(stream: scanCoin()),
                _ScanResultWidget(stream: scanPackage()),
                _ScanResultWidget(stream: scanDomain()),
                _ScanResultWidget(stream: scanNFT()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanResultWidget extends StatelessWidget {
  const _ScanResultWidget({required this.stream});

  final Stream<Widget> stream;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: SelectionArea(
        child: StreamBuilder(
          stream: stream,
          builder: (context, snapshot) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snapshot.data != null) snapshot.data!,
                if (snapshot.connectionState != ConnectionState.done)
                  const SizedBox.square(
                    dimension: 24,
                    child: CupertinoActivityIndicator(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
