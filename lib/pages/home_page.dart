import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/metamask_provider.dart';
import '../components/image_carousel.dart';

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
            if (provider.isConnected) ...[
              // 网络信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '网络信息',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('当前网络: ${provider.currentChain == MetaMaskProvider.arbitrumSepoliaChainId ? 'Arbitrum Sepolia' : '其他网络'}'),
                      Text('链ID: ${provider.currentChain ?? '未知'}'),
                      const SizedBox(height: 12),
                      if (provider.currentChain != MetaMaskProvider.arbitrumSepoliaChainId)
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await provider.switchToArbitrumSepolia();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已切换到 Arbitrum Sepolia 网络')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('切换网络失败: $e')),
                              );
                            }
                          },
                          child: const Text('切换到 Arbitrum Sepolia'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 账户地址
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '账户地址',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        provider.currentAddress ?? '',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 代币余额
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '代币余额',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshBalances,
                    tooltip: '刷新余额',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ETH 余额
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ETH',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      FutureBuilder<BigInt?>(
                        future: provider.getBalance(),
                        key: ValueKey('eth_${provider.currentChain}_${provider.currentAddress}_$_refreshKey'),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text('错误: ${snapshot.error}');
                          }
                          final balance = snapshot.data;
                          final formatted = provider.formatBalance(balance, 18);
                          return Text(
                            formatted,
                            style: const TextStyle(fontSize: 16),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // USDC 余额
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'USDC',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      FutureBuilder<BigInt?>(
                        future: provider.getUsdcBalance(),
                        key: ValueKey('usdc_${provider.currentChain}_${provider.currentAddress}_$_refreshKey'),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text('错误: ${snapshot.error}');
                          }
                          final balance = snapshot.data;
                          final formatted = provider.formatBalance(balance, 6); // USDC 有 6 位小数
                          return Text(
                            formatted,
                            style: const TextStyle(fontSize: 16),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // USDT 余额
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'USDT',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      FutureBuilder<BigInt?>(
                        future: provider.getUsdtBalance(),
                        key: ValueKey('usdt_${provider.currentChain}_${provider.currentAddress}_$_refreshKey'),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text('错误: ${snapshot.error}');
                          }
                          final balance = snapshot.data;
                          final formatted = provider.formatBalance(balance, 6); // USDT 有 6 位小数
                          return Text(
                            formatted,
                            style: const TextStyle(fontSize: 16),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('请连接钱包以查看余额'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
