import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key, this.requestRef, this.initialData});

  final DocumentReference<Map<String, dynamic>>? requestRef;
  final Map<String, dynamic>? initialData;

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  static const _red = Color(0xffcf2929);
  final _hospital = TextEditingController();
  final _city = TextEditingController();
  final _contact = TextEditingController();
  String _group = 'A+';
  String _urgency = 'Normal';
  bool get _isEditing => widget.requestRef != null;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data == null) return;
    _hospital.text = data['hospital'] as String? ?? '';
    _city.text = data['city'] as String? ?? '';
    _contact.text = data['contactNumber'] as String? ?? '';
    _group = data['bloodType'] as String? ?? _group;
    _urgency = data['urgency'] as String? ?? _urgency;
  }

  @override
  void dispose() {
    _hospital.dispose();
    _city.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _postRequest() async {
    if ([_hospital, _city, _contact].any((controller) => controller.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all required fields.')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in before creating a request.')));
      return;
    }

    try {
      await user.reload();
      if (FirebaseAuth.instance.currentUser?.emailVerified != true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verify your email before creating a request.')));
        return;
      }

    } on FirebaseAuthException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Unable to verify your account. Please try again.')));
      return;
    }

    try {
      final profile = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userInformation = profile.data()?['userInformation'] as Map<String, dynamic>?;
      final requesterName = (userInformation?['fullName'] as String?)?.trim().isNotEmpty == true
          ? (userInformation?['fullName'] as String).trim()
          : (user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : 'Requester');
      final requestData = {
        'ownerId': user.uid,
        // A snapshot used by request cards and map pins. The profile remains the
        // source of truth, while this keeps the request readable offline.
        'requesterName': requesterName,
        'hospital': _hospital.text.trim(),
        'city': _city.text.trim(),
        'contactNumber': _contact.text.trim(),
        'bloodType': _group,
        'urgency': _urgency,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (_isEditing) {
        await widget.requestRef!.update(requestData);
      } else {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('requests').add({
          ...requestData,
          'status': 'Active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x260d1c33),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xffe4f7ed),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xff249b60),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isEditing ? 'Request updated' : 'Request posted',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff16233b),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isEditing
                      ? 'Your request details have been saved successfully.'
                      : 'We are notifying compatible $_group donors near ${_hospital.text.trim()}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff697991),
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Back to my requests',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to post the request.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff7f8fa),
        appBar: AppBar(
          backgroundColor: _red,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 4,
          title: Text(_isEditing ? 'Edit Request' : 'Create Request', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 22), children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 19),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 5, offset: Offset(0, 2))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Hospital '),
              const SizedBox(height: 7),
              _input(_hospital, 'Enter hospital name'),
              const SizedBox(height: 17),
              _label('City '),
              const SizedBox(height: 7),
              _input(_city, 'Auto-filled from map or enter manually'),
              const SizedBox(height: 17),
              _label('Blood Type Needed '),
              const SizedBox(height: 7),
              _select(value: _group, values: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], onChanged: (value) => setState(() => _group = value!)),
              const SizedBox(height: 17),
              _label('Urgency'),
              const SizedBox(height: 7),
              _select(value: _urgency, values: const ['Normal', 'Urgent'], onChanged: (value) => setState(() => _urgency = value!)),
              const SizedBox(height: 7),
              const Text('Target response time: this request should be accepted\nwithin 180 minutes.', style: TextStyle(color: Color(0xff8a99b0), fontSize: 12, height: 1.35)),
              const SizedBox(height: 17),
              _label('Contact Number '),
              const SizedBox(height: 7),
              _input(_contact, 'e.g. 09123456789', keyboardType: TextInputType.phone),
              const SizedBox(height: 17),
              _label('Location '),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xffdfe3e9)), borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('No location selected yet.', style: TextStyle(color: Color(0xff8a99b0), fontSize: 13)),
                  const SizedBox(height: 6),
                  const Text('Privacy: only your city is shown publicly until a\ndonor accepts this request.', style: TextStyle(color: _red, fontSize: 12, height: 1.35)),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, height: 42, child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Map location selection is not configured yet.'))),
                    style: OutlinedButton.styleFrom(foregroundColor: _red, side: const BorderSide(color: _red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text('Set Location on Map', style: TextStyle(fontWeight: FontWeight.w700)),
                  )),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 49, child: FilledButton.icon(
                onPressed: _postRequest,
                style: FilledButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: Icon(_isEditing ? Icons.save_outlined : Icons.add, size: 20),
                label: Text(_isEditing ? 'Save Changes' : 'Create Request', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              )),
            ]),
          ),
        ]),
      );

  Widget _label(String text) => Text(text, style: const TextStyle(color: Color(0xff13223c), fontSize: 15.5, fontWeight: FontWeight.w500));

  Widget _input(TextEditingController controller, String hint, {TextInputType? keyboardType}) => SizedBox(height: 42, child: TextField(
    controller: controller,
    keyboardType: keyboardType,
    style: const TextStyle(color: Color(0xff13223c), fontSize: 15),
    decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xff8a99b0), fontSize: 14.5), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xffdfe3e9)), borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _red), borderRadius: BorderRadius.circular(12))),
  ));

  Widget _select({required String value, required List<String> values, required ValueChanged<String?> onChanged}) => Container(
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(border: Border.all(color: const Color(0xffdfe3e9)), borderRadius: BorderRadius.circular(12)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, style: const TextStyle(color: Colors.black, fontSize: 15), items: values.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: onChanged)),
  );
}
