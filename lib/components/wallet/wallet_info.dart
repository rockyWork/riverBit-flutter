import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/metamask_provider.dart';

class WalletInfo extends StatelessWidget {
  final int refreshKey;

  const WalletInfo({
    super.key,
    required this.refreshKey,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetaMaskProvider>();

    if (!provider.isConnected) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('请连接钱包以查看余额'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已切换到 Arbitrum Sepolia 网络')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('切换网络失败: $e')),
                          );
                        }
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
        _TokenBalances(
          provider: provider,
          refreshKey: refreshKey,
        ),
      ],
    );
  }
}

class _TokenBalances extends StatefulWidget {
  final MetaMaskProvider provider;
  final int refreshKey;

  const _TokenBalances({
    required this.provider,
    required this.refreshKey,
  });

  @override
  State<_TokenBalances> createState() => _TokenBalancesState();
}

class _TokenBalancesState extends State<_TokenBalances> {
  int _localRefreshKey = 0;

  void _refreshBalances() {
    setState(() {
      _localRefreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _TokenBalanceCard(
          tokenName: 'ETH',
          balanceFuture: widget.provider.getBalance(),
          decimals: 18,
          refreshKey: 'eth_${widget.provider.currentChain}_${widget.provider.currentAddress}_${widget.refreshKey}_$_localRefreshKey',
        ),
        const SizedBox(height: 8),
        // USDC 余额
        _TokenBalanceCard(
          tokenName: 'USDC',
          balanceFuture: widget.provider.getUsdcBalance(),
          decimals: 6,
          refreshKey: 'usdc_${widget.provider.currentChain}_${widget.provider.currentAddress}_${widget.refreshKey}_$_localRefreshKey',
        ),
        const SizedBox(height: 8),
        // USDT 余额
        _TokenBalanceCard(
          tokenName: 'USDT',
          balanceFuture: widget.provider.getUsdtBalance(),
          decimals: 6,
          refreshKey: 'usdt_${widget.provider.currentChain}_${widget.provider.currentAddress}_${widget.refreshKey}_$_localRefreshKey',
        ),
      ],
    );
  }
}

class _TokenBalanceCard extends StatelessWidget {
  final String tokenName;
  final Future<BigInt?> balanceFuture;
  final int decimals;
  final String refreshKey;

  const _TokenBalanceCard({
    required this.tokenName,
    required this.balanceFuture,
    required this.decimals,
    required this.refreshKey,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetaMaskProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tokenName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            FutureBuilder<BigInt?>(
              future: balanceFuture,
              key: ValueKey(refreshKey),
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
                final formatted = provider.formatBalance(balance, decimals);
                return Text(
                  formatted,
                  style: const TextStyle(fontSize: 16),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

