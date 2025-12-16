import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class MarketDataTabs extends StatefulWidget {
  const MarketDataTabs({super.key});

  @override
  State<MarketDataTabs> createState() => _MarketDataTabsState();
}

class _MarketDataTabsState extends State<MarketDataTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _updateTimer;

  // Mock 数据
  List<OrderBookItem> _buyOrders = [];
  List<OrderBookItem> _sellOrders = [];
  List<TradeItem> _trades = [];

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeMockData();
    _startAutoUpdate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _initializeMockData() {
    // 初始化订单簿数据
    _buyOrders = List.generate(10, (index) {
      final price = 86000.0 - (index * 50.0);
      final amount = 0.01 + _random.nextDouble() * 0.1;
      return OrderBookItem(
        price: price,
        amount: amount,
        total: (index == 0 ? amount : _buyOrders[index - 1].total + amount),
      );
    });

    _sellOrders = List.generate(10, (index) {
      final price = 86500.0 + (index * 50.0);
      final amount = 0.01 + _random.nextDouble() * 0.1;
      return OrderBookItem(
        price: price,
        amount: amount,
        total: (index == 0 ? amount : _sellOrders[index - 1].total + amount),
      );
    });

    // 初始化交易记录
    _trades = List.generate(20, (index) {
      final isLong = _random.nextBool();
      final price = 86000.0 + _random.nextDouble() * 500.0;
      final amount = 0.001 + _random.nextDouble() * 0.1;
      return TradeItem(
        time: DateTime.now().subtract(Duration(seconds: index * 3)),
        direction: isLong ? TradeDirection.long : TradeDirection.short,
        price: price,
        amount: amount,
      );
    });
  }

  void _startAutoUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _updateMockData();
      }
    });
  }

  void _updateMockData() {
    setState(() {
      // 更新订单簿 - 随机调整价格和数量
      _buyOrders = _buyOrders.map((order) {
        final priceChange = (_random.nextDouble() - 0.5) * 10;
        final amountChange = (_random.nextDouble() - 0.5) * 0.01;
        return OrderBookItem(
          price: (order.price + priceChange).clamp(85000.0, 87000.0),
          amount: (order.amount + amountChange).clamp(0.001, 0.2),
          total: order.total,
        );
      }).toList();

      _sellOrders = _sellOrders.map((order) {
        final priceChange = (_random.nextDouble() - 0.5) * 10;
        final amountChange = (_random.nextDouble() - 0.5) * 0.01;
        return OrderBookItem(
          price: (order.price + priceChange).clamp(86500.0, 88000.0),
          amount: (order.amount + amountChange).clamp(0.001, 0.2),
          total: order.total,
        );
      }).toList();

      // 添加新的交易记录
      final isLong = _random.nextBool();
      final currentPrice = _buyOrders.isNotEmpty && _sellOrders.isNotEmpty
          ? (_buyOrders.first.price + _sellOrders.first.price) / 2
          : 86500.0;
      final price = currentPrice + (_random.nextDouble() - 0.5) * 100;
      final amount = 0.001 + _random.nextDouble() * 0.1;

      _trades.insert(
        0,
        TradeItem(
          time: DateTime.now(),
          direction: isLong ? TradeDirection.long : TradeDirection.short,
          price: price,
          amount: amount,
        ),
      );

      // 保持最多 50 条交易记录
      if (_trades.length > 50) {
        _trades.removeRange(50, _trades.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Order Book'),
            Tab(text: 'Trades'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrderBook(),
              _buildTrades(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderBook() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          // 买单
          Expanded(
            child: Column(
              children: [
                _buildOrderBookHeader('Buy'),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _buyOrders.length,
                    itemBuilder: (context, index) {
                      final order = _buyOrders[index];
                      return _buildOrderBookRow(
                        order,
                        isBuy: true,
                        maxTotal: _buyOrders.last.total,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 中间分隔线
          Container(
            width: 1,
            color: Colors.grey.shade300,
          ),
          // 卖单
          Expanded(
            child: Column(
              children: [
                _buildOrderBookHeader('Sell'),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sellOrders.length,
                    itemBuilder: (context, index) {
                      final order = _sellOrders[index];
                      return _buildOrderBookRow(
                        order,
                        isBuy: false,
                        maxTotal: _sellOrders.last.total,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBookHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Price',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Amount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBookRow(OrderBookItem order, {required bool isBuy, required double maxTotal}) {
    final color = isBuy ? Colors.green : Colors.red;
    final opacity = order.total / maxTotal * 0.3;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              order.price.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              order.amount.toStringAsFixed(6),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              order.total.toStringAsFixed(6),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrades() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // 表头
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Filled Time',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Direction',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Price',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Amount (BTC)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 交易列表
          Expanded(
            child: ListView.builder(
              itemCount: _trades.length,
              itemBuilder: (context, index) {
                final trade = _trades[index];
                return _buildTradeRow(trade);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeRow(TradeItem trade) {
    final isLong = trade.direction == TradeDirection.long;
    final color = isLong ? Colors.green : Colors.red;
    final directionText = isLong ? 'Long' : 'Short';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '${trade.time.hour.toString().padLeft(2, '0')}:${trade.time.minute.toString().padLeft(2, '0')}:${trade.time.second.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              directionText,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              trade.price.toStringAsFixed(2),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              trade.amount.toStringAsFixed(6),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// 订单簿数据模型
class OrderBookItem {
  final double price;
  final double amount;
  final double total;

  OrderBookItem({
    required this.price,
    required this.amount,
    required this.total,
  });
}

// 交易记录数据模型
class TradeItem {
  final DateTime time;
  final TradeDirection direction;
  final double price;
  final double amount;

  TradeItem({
    required this.time,
    required this.direction,
    required this.price,
    required this.amount,
  });
}

enum TradeDirection {
  long,
  short,
}

