import 'package:flutter/foundation.dart';
import 'package:flutter_web3/flutter_web3.dart';

class MetaMaskProvider extends ChangeNotifier {
  static const Set<int> allowedChainIds = {1, 11155111, 421614};

  String? currentAddress;
  int? currentChain;
  Web3Provider? web3;

  bool get isEnabled => ethereum != null;
  bool get isConnected => currentAddress != null;
  bool get isInOperatingChain =>
      currentChain != null && allowedChainIds.contains(currentChain);

  /// 确保 web3 provider 已初始化
  bool _ensureWeb3() {
    if (!isEnabled) return false;
    if (web3 == null) {
      try {
        web3 = Web3Provider(ethereum!);
      } catch (e) {
        debugPrint('初始化 web3 失败: $e');
        return false;
      }
    }
    return true;
  }

  Future<void> init() async {
    if (!isEnabled) {
      notifyListeners();
      return;
    }
    ethereum!.onAccountsChanged((accounts) {
      if (accounts.isNotEmpty) {
        currentAddress = accounts.first;
      } else {
        currentAddress = null;
      }
      notifyListeners();
    });
    ethereum!.onChainChanged((chainId) {
      currentChain = chainId;
      // 链切换后重新初始化 web3 provider
      web3 = Web3Provider(ethereum!);
      notifyListeners();
    });
    
    // 初始化时获取当前链ID
    try {
      final chainIdHex = await ethereum!.request<String>('eth_chainId');
      currentChain = int.parse(chainIdHex.replaceFirst('0x', ''), radix: 16);
    } catch (e) {
      debugPrint('获取初始链ID失败: $e');
    }
    _ensureWeb3();
    notifyListeners();
  }

  Future<void> connect() async {
    if (!isEnabled) return;
    _ensureWeb3();
    try {
      final accs = await ethereum!.requestAccount();
      if (accs.isNotEmpty) {
        currentAddress = accs.first;
        // 获取当前链ID
        try {
          final chainIdHex = await ethereum!.request<String>('eth_chainId');
          currentChain = int.parse(chainIdHex.replaceFirst('0x', ''), radix: 16);
        } catch (e) {
          // 备用方法：通过 web3 获取
          try {
            final network = await web3!.getNetwork();
            currentChain = network.chainId;
          } catch (e2) {
            debugPrint('获取网络信息失败: $e2');
          }
        }
        _ensureWeb3();
      }
    } catch (e) {
      debugPrint('连接钱包失败: $e');
    }
    notifyListeners();
  }

  void disconnect() {
    currentAddress = null;
    notifyListeners();
  }

  // Arbitrum Sepolia 网络配置
  static const int arbitrumSepoliaChainId = 421614;
  static const String arbitrumSepoliaRpcUrl = 'https://sepolia-rollup.arbitrum.io/rpc';
  
  // Arbitrum Sepolia 上的代币合约地址
  // 最新 USDC 合约（用户提供）
  static const String usdcAddress = '0xb9a2771032cdadb3583cff0034edb79c3196328f';
  static const String usdtAddress = '0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2';

  // 切换到 Arbitrum Sepolia 网络
  Future<void> switchToArbitrumSepolia() async {
    if (!isEnabled) return;
    _ensureWeb3();
    
    final chainIdHex = '0x${arbitrumSepoliaChainId.toRadixString(16)}';
    
    try {
      // 先尝试切换网络
      await ethereum!.request(
        'wallet_switchEthereumChain',
        [{'chainId': chainIdHex}],
      );
      
      // 切换成功后更新链ID
      currentChain = arbitrumSepoliaChainId;
      // 重新初始化 web3 provider 以确保使用新网络
      _ensureWeb3();
    } catch (switchError) {
      // 如果网络不存在（错误码 4902），尝试添加网络
      final errorString = switchError.toString();
      if (errorString.contains('4902') || errorString.contains('Chain not added')) {
        try {
          // 构建网络参数对象，确保格式正确
          final chainParams = {
            'chainId': chainIdHex,
            'chainName': 'Arbitrum Sepolia',
            'nativeCurrency': {
              'name': 'ETH',
              'symbol': 'ETH',
              'decimals': 18,
            },
            'rpcUrls': [arbitrumSepoliaRpcUrl],
            'blockExplorerUrls': ['https://sepolia.arbiscan.io/'],
          };
          
          await ethereum!.request(
            'wallet_addEthereumChain',
            [chainParams],
          );
          
          // 添加成功后更新链ID
          currentChain = arbitrumSepoliaChainId;
          // 重新初始化 web3 provider
          _ensureWeb3();
        } catch (addError) {
          debugPrint('添加网络失败: $addError');
          rethrow;
        }
      } else {
        debugPrint('切换网络失败: $switchError');
        rethrow;
      }
    }
    notifyListeners();
  }

  Future<BigInt?> getBalance() async {
    if (!isEnabled || !isConnected || !_ensureWeb3()) {
      debugPrint('getBalance: 条件不满足 - isEnabled: $isEnabled, isConnected: $isConnected, web3: ${web3 != null}');
      return null;
    }
    try {
      final signer = web3!.getSigner();
      final balance = await signer.getBalance();
      debugPrint('ETH 余额: $balance wei');
      return balance;
    } catch (e) {
      debugPrint('获取 ETH 余额错误: $e');
      return null;
    }
  }

  // 获取 ERC20 代币余额
  Future<BigInt?> getTokenBalance(String contractAddress) async {
    if (!isEnabled || !isConnected || currentAddress == null || !_ensureWeb3()) {
      debugPrint('getTokenBalance: 条件不满足 - isEnabled: $isEnabled, isConnected: $isConnected, address: $currentAddress, web3: ${web3 != null}');
      return null;
    }
    try {
      debugPrint('获取代币余额 - 合约地址: $contractAddress, 账户地址: $currentAddress');
      
      // ERC20 balanceOf 函数的 ABI（flutter_web3 要求是 String 或 List<String>）
      const abi = '''
      [
        {
          "constant": true,
          "inputs": [{"name": "_owner", "type": "address"}],
          "name": "balanceOf",
          "outputs": [{"name": "balance", "type": "uint256"}],
          "type": "function"
        }
      ]
      ''';
      
      // 使用 provider 来读取合约数据（只读操作）
      final contract = Contract(contractAddress, abi, web3!);

      // 不指定泛型，先拿到原始返回值，避免 flutter_web3 内部断言类型失败
      final raw = await contract.call('balanceOf', [currentAddress]);
      debugPrint('代币原始返回 ($contractAddress): $raw  (${raw.runtimeType})');

      // 兼容多种返回形式：BigInt / String(hex 或十进制) / num / List / LegacyJavaScriptObject
      BigInt? parsed;
      if (raw is BigInt) {
        parsed = raw;
      } else if (raw is String) {
        // 可能是 0x 开头的 hex 字符串
        final hex = raw.startsWith('0x') ? raw.substring(2) : raw;
        parsed = BigInt.parse(hex, radix: 16);
      } else if (raw is num) {
        parsed = BigInt.from(raw);
      } else if (raw is List && raw.isNotEmpty) {
        final v = raw.first;
        if (v is BigInt) {
          parsed = v;
        } else if (v is String) {
          final hex = v.startsWith('0x') ? v.substring(2) : v;
          parsed = BigInt.parse(hex, radix: 16);
        } else if (v is num) {
          parsed = BigInt.from(v);
        }
      }

      // 兜底：某些情况下 raw 是 JS 对象（LegacyJavaScriptObject），toString() 直接是十进制字符串
      if (parsed == null && raw != null) {
        final s = raw.toString();
        final decimalReg = RegExp(r'^[0-9]+$');
        final hexReg = RegExp(r'^0x[0-9a-fA-F]+$');
        if (decimalReg.hasMatch(s)) {
          parsed = BigInt.parse(s);
        } else if (hexReg.hasMatch(s)) {
          parsed = BigInt.parse(s.substring(2), radix: 16);
        }
      }

      debugPrint('代币余额解析后 ($contractAddress): $parsed');
      return parsed;
    } catch (e, stackTrace) {
      debugPrint('获取代币余额错误 ($contractAddress): $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return null;
    }
  }

  // 获取 USDC 余额
  Future<BigInt?> getUsdcBalance() async {
    return getTokenBalance(usdcAddress);
  }

  // 获取 USDT 余额
  Future<BigInt?> getUsdtBalance() async {
    return getTokenBalance(usdcAddress);
  }

  // 格式化余额显示（wei 转可读格式）
  String formatBalance(BigInt? balance, int decimals) {
    if (balance == null) return '0';
    if (balance == BigInt.zero) return '0';
    
    final divisor = BigInt.from(10).pow(decimals);
    final wholePart = balance ~/ divisor;
    final fractionalPart = balance % divisor;
    
    if (fractionalPart == BigInt.zero) {
      return wholePart.toString();
    }
    
    final fractionalStr = fractionalPart.toString().padLeft(decimals, '0');
    final trimmedFractional = fractionalStr.replaceAll(RegExp(r'0+$'), '');
    
    return '$wholePart.${trimmedFractional.isEmpty ? '0' : trimmedFractional}';
  }

  Future<String?> sendEth(String to, BigInt amountWei) async {
    if (!isEnabled || !isConnected || !_ensureWeb3()) return null;
    final tx = await web3!.getSigner().sendTransaction(
      TransactionRequest(
        to: to,
        value: amountWei,
      ),
    );
    return tx.hash;
  }
}
