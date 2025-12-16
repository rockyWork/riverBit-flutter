import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/metamask_provider.dart';
import '../components/image_carousel.dart';
import '../components/wallet/wallet_info.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _refreshKey = 0;
  int? _lastChainId;
  String? _lastAddress;

  @override
  void initState() {
    super.initState();
  }

  void _refreshBalances() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetaMaskProvider>();
    
    // 当链ID或地址变化时自动刷新余额
    if (_lastChainId != provider.currentChain || _lastAddress != provider.currentAddress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshBalances();
        }
      });
      _lastChainId = provider.currentChain;
      _lastAddress = provider.currentAddress;
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 轮播图
            const ImageCarousel(),
            // 钱包信息（包含网络信息、账户地址、代币余额）
            WalletInfo(refreshKey: _refreshKey),
          ],
        ),
      ),
    );
  }
}
