import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityGate extends StatefulWidget {
  const ConnectivityGate({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool? _hasConnection;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnection);
  }

  Future<void> _checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnection(result);
  }

  void _updateConnection(List<ConnectivityResult> results) {
    if (!mounted) return;
    setState(() => _hasConnection = results.any((result) => result != ConnectivityResult.none));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasConnection != false) return widget.child;

    return Scaffold(
      backgroundColor: const Color(0xfff7f8fa),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: const BoxDecoration(color: Color(0xffffe8ec), shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded, color: Color(0xffcf2929), size: 38),
              ),
              const SizedBox(height: 22),
              const Text('No internet connection', style: TextStyle(color: Color(0xff13223c), fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 9),
              const Text('Check your Wi-Fi or mobile data, then try again.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff62738d), fontSize: 15, height: 1.4)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _checkConnection,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xffcf2929)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
