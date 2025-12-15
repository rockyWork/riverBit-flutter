import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/metamask_provider.dart';
import 'pages/main_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MetaMaskProvider()..init(),
      child: MaterialApp(
        title: 'RiverBit Web3',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const MainShell(),
      ),
    );
  }
}
