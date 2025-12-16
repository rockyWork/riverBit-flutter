import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class TradingViewChart extends StatefulWidget {
  final String symbol;
  final double height;

  const TradingViewChart({
    super.key,
    required this.symbol,
    this.height = 500,
  });

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  late String _iframeId;
  html.IFrameElement? _iframeElement;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _iframeId = 'tradingview_${DateTime.now().millisecondsSinceEpoch}';
    _createIframe();
  }

  @override
  void didUpdateWidget(TradingViewChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol && _iframeElement != null) {
      _updateIframe();
    }
  }

  void _createIframe() {
    if (!_isRegistered) {
      _iframeElement = html.IFrameElement()
        ..id = _iframeId
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '${widget.height}px'
        ..allowFullscreen = true
        ..src = _getTradingViewUrl(widget.symbol);

      // 注册 iframe 到 Flutter Web
      ui_web.platformViewRegistry.registerViewFactory(
        _iframeId,
        (int viewId) => _iframeElement!,
      );
      _isRegistered = true;
    }
  }

  void _updateIframe() {
    if (_iframeElement != null) {
      _iframeElement!.src = _getTradingViewUrl(widget.symbol);
    }
  }

  String _getTradingViewUrl(String symbol) {
    // 使用 TradingView 的轻量级图表库
    // 注意：某些交易所可能需要特定的 symbol 格式，如 BINANCE:BTCUSDT
    // 对于通用交易对，直接使用 symbol，TradingView 会自动匹配
    // 使用深色主题 (theme=dark)
    final encodedSymbol = Uri.encodeComponent(symbol);
    return 'https://www.tradingview.com/widgetembed/?symbol=$encodedSymbol&interval=D&hidesidetoolbar=0&symboledit=1&saveimage=0&toolbarbg=131722&studies=%5B%5D&theme=dark&style=1&timezone=Asia%2FShanghai&studies_overrides=%7B%7D&overrides=%7B%7D&enabled_features=%5B%5D&disabled_features=%5B%5D&locale=zh_CN&utm_source=www.tradingview.com&utm_medium=widget&utm_campaign=chart&utm_term=$encodedSymbol';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _isRegistered
            ? HtmlElementView(viewType: _iframeId)
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _iframeElement = null;
    super.dispose();
  }
}

