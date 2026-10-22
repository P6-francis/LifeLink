import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AsyncStateView extends StatelessWidget {
  const AsyncStateView.loading({super.key, this.label = 'Loading...'})
    : title = null,
      message = null,
      icon = null,
      error = null;
  const AsyncStateView.empty({super.key, required this.title, required this.message, this.icon = Icons.inbox_outlined}) : label = null, error = null;
  const AsyncStateView.error({super.key, required this.error}) : title = null, message = null, icon = null, label = null;

  final String? label;
  final String? title;
  final String? message;
  final IconData? icon;
  final Object? error;

  bool get _isOffline {
    final code = error is FirebaseException ? (error as FirebaseException).code.toLowerCase() : '';
    final text = error?.toString().toLowerCase() ?? '';
    return code == 'unavailable' || code == 'network-request-failed' || text.contains('network') || text.contains('offline');
  }

  @override
  Widget build(BuildContext context) {
    if (label != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2.8, color: Color(0xffcf2929))), const SizedBox(height: 14), Text(label!, style: const TextStyle(color: Color(0xff71819a)))]));
    final offline = error != null && _isOffline;
    final stateIcon = error != null ? (offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded) : icon!;
    final stateTitle = error != null ? (offline ? 'You\'re offline' : 'Something went wrong') : title!;
    final stateMessage = error != null ? (offline ? 'Check your internet connection and try again.' : 'We couldn\'t load this right now. Please try again shortly.') : message!;
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 62, height: 62, decoration: BoxDecoration(color: const Color(0xffffeef0), borderRadius: BorderRadius.circular(20)), child: Icon(stateIcon, color: const Color(0xffcf2929), size: 31)), const SizedBox(height: 16), Text(stateTitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xff182235), fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 7), Text(stateMessage, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xff71819a), fontSize: 14, height: 1.4))])));
  }
}
