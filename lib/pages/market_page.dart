import 'package:flutter/material.dart';
import '../components/trading_view_chart.dart';
import '../components/orderbook_trade_tabs.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  // 预定义的交易对列表
  final List<TradingPair> _tradingPairs = [
    const TradingPair(symbol: 'BTCUSD', displayName: 'BTC/USD'),
    const TradingPair(symbol: 'ETHUSD', displayName: 'ETH/USD'),
    const TradingPair(symbol: 'BNBUSD', displayName: 'BNB/USD'),
    const TradingPair(symbol: 'SOLUSD', displayName: 'SOL/USD'),
    const TradingPair(symbol: 'ADAUSD', displayName: 'ADA/USD'),
    const TradingPair(symbol: 'XRPUSD', displayName: 'XRP/USD'),
    const TradingPair(symbol: 'DOGEUSD', displayName: 'DOGE/USD'),
    const TradingPair(symbol: 'DOTUSD', displayName: 'DOT/USD'),
  ];

  TradingPair _selectedPair = const TradingPair(symbol: 'BTCUSD', displayName: 'BTC/USD');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
      ),
      body: Column(
        children: [
          // 交易对选择器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  '交易对:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<TradingPair>(
                    value: _selectedPair,
                    isExpanded: true,
                    underline: Container(),
                    isDense: true,
                    items: _tradingPairs.map((pair) {
                      return DropdownMenuItem<TradingPair>(
                        value: pair,
                        child: Text(
                          pair.displayName,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (TradingPair? newPair) {
                      if (newPair != null) {
                        setState(() {
                          _selectedPair = newPair;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // TradingView 图表（大约占剩余空间的 2/3）
          Flexible(
            flex: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return TradingViewChart(
                  symbol: _selectedPair.symbol,
                  height: constraints.maxHeight,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // OrderBook / Trade（大约占剩余空间的 1/3）
          Flexible(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OrderBookTradeTabs(symbol: _selectedPair.symbol),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// 交易对数据模型
class TradingPair {
  final String symbol;
  final String displayName;

  const TradingPair({
    required this.symbol,
    required this.displayName,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TradingPair &&
        other.symbol == symbol &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => symbol.hashCode ^ displayName.hashCode;
}

