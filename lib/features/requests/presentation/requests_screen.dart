import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'create_request_screen.dart';
import '../../../widgets/async_state_view.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {

  static const _red = Color(0xffcf2929);
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff7f8fa),
        body: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              color: _red,
              child: Row(children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: SvgPicture.asset('assets/lifelink_logo.svg'),
                ),
                const SizedBox(width: 14),
                const Text('My Requests', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ]),
            ),
            Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _myRequests(),
              builder: (context, snapshot) => ListView(padding: const EdgeInsets.fromLTRB(18, 19, 18, 24), children: [
                Row(children: [
                Text(_showHistory ? 'Request History' : 'Blood Requests', style: const TextStyle(color: Color(0xff10213c), fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: () => setState(() => _showHistory = !_showHistory), icon: Icon(_showHistory ? Icons.list_alt_outlined : Icons.history_outlined), tooltip: _showHistory ? 'Show active requests' : 'View request history', color: _red),
                SizedBox(height: 40, child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
                  style: FilledButton.styleFrom(backgroundColor: _red, padding: const EdgeInsets.symmetric(horizontal: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('New Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                )),
              ]),
                const SizedBox(height: 14),
                if (snapshot.hasError)
                  SizedBox(height: 360, child: AsyncStateView.error(error: snapshot.error))
                else if (!snapshot.hasData)
                  const SizedBox(height: 360, child: AsyncStateView.loading(label: 'Loading your requests...'))
                else if (_visibleRequests(snapshot.data!.docs).isEmpty)
                  SizedBox(height: 360, child: AsyncStateView.empty(title: _showHistory ? 'No request history yet' : 'No requests yet', message: _showHistory ? 'Cancelled or completed requests will appear here.' : 'Create a blood request when you need help from the community.', icon: Icons.water_drop_outlined))
                else
                  for (final request in _visibleRequests(snapshot.data!.docs)) ...[
                    _MyRequestCard(reference: request.reference, data: request.data()),
                    const SizedBox(height: 12),
                  ],
              ]),
            )),
          ],
        ),
      );

  Stream<QuerySnapshot<Map<String, dynamic>>> _myRequests() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    // These documents always live under the signed-in user's profile.  A
    // collection-group query is intended for finding requests across users,
    // and can fail when its group index or corresponding deployed rule is not
    // available.  Querying the known path is both narrower and reliable for
    // the "My Requests" screen.
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('requests')
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _visibleRequests(List<QueryDocumentSnapshot<Map<String, dynamic>>> requests) {
    final visible = requests.where((request) {
    final active = (request.data()['status'] as String? ?? 'Active') == 'Active';
    return _showHistory ? !active : active;
    }).toList();
    visible.sort((a, b) {
      final aTime = a.data()['createdAt'] as Timestamp?;
      final bTime = b.data()['createdAt'] as Timestamp?;
      return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(aTime?.millisecondsSinceEpoch ?? 0);
    });
    return visible;
  }
}

class _MyRequestCard extends StatefulWidget {
  const _MyRequestCard({required this.reference, required this.data});

  final DocumentReference<Map<String, dynamic>> reference;
  final Map<String, dynamic> data;

  @override
  State<_MyRequestCard> createState() => _MyRequestCardState();
}

class _MyRequestCardState extends State<_MyRequestCard> {
  Timer? _ageTimer;

  @override
  void initState() {
    super.initState();
    _ageTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ageTimer?.cancel();
    super.dispose();
  }

  String get requesterName {
    final profileName = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (profileName?.isNotEmpty == true) return profileName!;
    return (widget.data['requesterName'] as String?)?.trim().isNotEmpty == true
        ? (widget.data['requesterName'] as String).trim()
        : 'User';
  }
  String get bloodType => widget.data['bloodType'] as String? ?? 'Unknown';
  String get location => widget.data['hospital'] as String? ?? 'Unknown hospital';
  String get city => widget.data['city'] as String? ?? 'Unknown city';
  String get urgency => widget.data['urgency'] as String? ?? 'Normal';
  String get status => widget.data['status'] as String? ?? 'Active';
  bool get _isActive => status == 'Active';
  bool get _isCancelled => status == 'Cancelled';

  String get age {
    final timestamp = widget.data['createdAt'];
    if (timestamp is! Timestamp) return 'Just now';
    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xffedf0f4)), boxShadow: const [BoxShadow(color: Color(0x0d15233d), blurRadius: 14, offset: Offset(0, 5))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xffffe7eb),
              child: Text(requesterName[0].toUpperCase(), style: const TextStyle(color: Color(0xffcf2929), fontWeight: FontWeight.w800, fontSize: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(requesterName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff17233b), fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Row(children: [
                const Text('Blood type', style: TextStyle(color: Color(0xff8491a5), fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                _pill(bloodType, const Color(0xffffe8ec), const Color(0xffd9283b)),
              ]),
              const SizedBox(height: 7),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 15, color: Color(0xff8a99b0)),
                const SizedBox(width: 4),
                Expanded(child: Text(city, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff8390a6), fontSize: 12.5, fontWeight: FontWeight.w500))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.local_hospital_outlined, size: 15, color: Color(0xff8a99b0)),
                const SizedBox(width: 4),
                Expanded(child: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff8390a6), fontSize: 12.5, fontWeight: FontWeight.w500))),
              ]),
            ])),
            const SizedBox(width: 8),
            _pill(
              _isActive ? urgency : status,
              _isCancelled ? const Color(0xffffe8ea) : const Color(0xffe7f5e8),
              _isCancelled ? const Color(0xffe03030) : const Color(0xff20913a),
            ),
          ]),
          if (_isActive) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xffedf0f4))),
            Row(children: [
              Expanded(child: SizedBox(height: 43, child: FilledButton.icon(
                onPressed: () => _markAsDone(context),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Mark done', style: TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xff219a45), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ))),
              const SizedBox(width: 8),
              _actionIcon(icon: Icons.edit_outlined, label: 'Edit request', color: const Color(0xffcf2929), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateRequestScreen(requestRef: widget.reference, initialData: widget.data)))),
              const SizedBox(width: 8),
              _actionIcon(icon: Icons.close_rounded, label: 'Cancel request', color: const Color(0xff7b8494), onTap: () => _cancel(context)),
            ]),
          ] else ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xffedf0f4))),
            SizedBox(
              width: double.infinity,
              height: 43,
              child: OutlinedButton.icon(
                onPressed: () => _delete(context),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete from history', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xffcf2929),
                  side: const BorderSide(color: Color(0xffffc9cf)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 3),
          Text('Urgency: $urgency  ·  $age', style: const TextStyle(color: Color(0xff8a99b0), fontSize: 14)),
        ]),
      );

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _confirmationDialog(
        context: dialogContext,
        icon: Icons.cancel_outlined,
        accent: const Color(0xffcf2929),
        title: 'Cancel this request?',
        message: 'This will stop matching donors. The request will remain in your history.',
        secondaryLabel: 'Keep request',
        primaryLabel: 'Cancel request',
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await widget.reference.update({'status': 'Cancelled', 'cancelledAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled and moved to history.')));
    } on FirebaseException catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Unable to cancel this request.')));
    }
  }

  Future<void> _markAsDone(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _confirmationDialog(
        context: dialogContext,
        icon: Icons.check_circle_outline_rounded,
        accent: const Color(0xff219a45),
        title: 'Mark request as done?',
        message: 'This request will be removed from active requests and saved in your history.',
        secondaryLabel: 'Not yet',
        primaryLabel: 'Mark as done',
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await widget.reference.update({
        'status': 'Completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request marked as done and moved to history.')));
    } on FirebaseException catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Unable to mark this request as done.')));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _confirmationDialog(
        context: dialogContext,
        icon: Icons.delete_outline_rounded,
        accent: const Color(0xffcf2929),
        title: 'Delete this request?',
        message: 'This will permanently remove it from your request history. This action cannot be undone.',
        secondaryLabel: 'Keep request',
        primaryLabel: 'Delete request',
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await widget.reference.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request deleted from history.')),
        );
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to delete this request.')),
        );
      }
    }
  }

  Widget _pill(String label, Color background, Color foreground) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
        child: Text(label, style: TextStyle(color: foreground, fontSize: 13, fontWeight: FontWeight.w700)),
      );

  Widget _actionIcon({required IconData icon, required String label, required Color color, required VoidCallback onTap}) => Material(
        color: const Color(0xfff7f8fa),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Tooltip(message: label, child: SizedBox(width: 43, height: 43, child: Icon(icon, size: 20, color: color))),
        ),
      );

  Widget _confirmationDialog({
    required BuildContext context,
    required IconData icon,
    required Color accent,
    required String title,
    required String message,
    required String secondaryLabel,
    required String primaryLabel,
  }) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(height: 5, color: accent),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: Color.lerp(accent, Colors.white, .88), borderRadius: BorderRadius.circular(16)),
                    child: Icon(icon, color: accent, size: 27),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(title, style: const TextStyle(color: Color(0xff17233b), fontSize: 19, fontWeight: FontWeight.w800, height: 1.15))),
                ]),
                const SizedBox(height: 18),
                Align(alignment: Alignment.centerLeft, child: Text(message, style: const TextStyle(color: Color(0xff68758a), fontSize: 14, height: 1.45))),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: Icon(icon, size: 19),
                    label: Text(primaryLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                    style: FilledButton.styleFrom(backgroundColor: accent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
                const SizedBox(height: 7),
                TextButton(onPressed: () => Navigator.pop(context, false), style: TextButton.styleFrom(foregroundColor: const Color(0xff718096), minimumSize: const Size(double.infinity, 42)), child: Text(secondaryLabel, style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
            ),
          ]),
        ),
      );
}
