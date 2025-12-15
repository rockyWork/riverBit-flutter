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
      notifyListeners();
    });
    web3 = Web3Provider(ethereum!);
    notifyListeners();
  }

  Future<void> connect() async {
    if (!isEnabled) return;
    try {
      final accs = await ethereum!.requestAccount();
      if (accs.isNotEmpty) {
        currentAddress = accs.first;
        final network = await web3!.getNetwork();
        currentChain = network.chainId;
      }
    } catch (_) {}
    notifyListeners();
  }

  void disconnect() {
    currentAddress = null;
    notifyListeners();
  }

  Future<BigInt?> getBalance() async {
    if (!isEnabled || !isConnected) return null;
    final signer = web3!.getSigner();
    final balance = await signer.getBalance();
    return balance;
  }

  Future<String?> sendEth(String to, BigInt amountWei) async {
    if (!isEnabled || !isConnected) return null;
    final tx = await web3!.getSigner().sendTransaction(
      TransactionRequest(
        to: to,
        value: amountWei,
      ),
    );
    return tx.hash;
  }
}
