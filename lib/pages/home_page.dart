import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/metamask_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetaMaskProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: () {
                if (!provider.isEnabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请使用支持 Web3 的浏览器或安装 MetaMask')),
                  );
                  return;
                }
                if (provider.isConnected) {
                  provider.disconnect();
                } else {
                  provider.connect();
                }
              },
              child: Text(provider.isConnected ? '断开链接' : '连接钱包'),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (provider.isConnected) ...[
              Text(provider.currentAddress ?? ''),
              const SizedBox(height: 12),
              FutureBuilder<BigInt?>(
                future: provider.getBalance(),
                builder: (context, snapshot) {
                  final text = snapshot.hasData ? '余额: ${snapshot.data} wei' : '余额: 加载中';
                  return Text(text);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
