import 'package:flutter/material.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  static const _red = Color(0xffcf2929);
  final _patient = TextEditingController();
  final _hospital = TextEditingController();
  final _city = TextEditingController();
  final _contact = TextEditingController();
  String _group = 'A+';
  String _urgency = 'Normal';

  @override
  void dispose() {
    _patient.dispose();
    _hospital.dispose();
    _city.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _postRequest() {
    if ([_patient, _hospital, _city, _contact].any((controller) => controller.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all required fields.')));
      return;
    }
    showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.check_circle, color: Color(0xff2e9b65), size: 48),
      title: const Text('Request posted'),
      content: Text('We are notifying compatible $_group donors near ${_hospital.text}.'),
      actions: [TextButton(onPressed: () { Navigator.of(dialogContext).pop(); Navigator.of(context).pop(); }, child: const Text('Done'))],
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff7f8fa),
        appBar: AppBar(
          backgroundColor: _red,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 4,
          title: const Text('Create Request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 22), children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 19),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 5, offset: Offset(0, 2))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Patient Name *'),
              const SizedBox(height: 7),
              _input(_patient, 'Enter patient name'),
              const SizedBox(height: 17),
              _label('Hospital *'),
              const SizedBox(height: 7),
              _input(_hospital, 'Enter hospital name'),
              const SizedBox(height: 17),
              _label('City *'),
              const SizedBox(height: 7),
              _input(_city, 'Auto-filled from map or enter manually'),
              const SizedBox(height: 17),
              _label('Blood Type Needed *'),
              const SizedBox(height: 7),
              _select(value: _group, values: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], onChanged: (value) => setState(() => _group = value!)),
              const SizedBox(height: 17),
              _label('Urgency'),
              const SizedBox(height: 7),
              _select(value: _urgency, values: const ['Normal', 'Urgent'], onChanged: (value) => setState(() => _urgency = value!)),
              const SizedBox(height: 7),
              const Text('Target response time: this request should be accepted\nwithin 180 minutes.', style: TextStyle(color: Color(0xff8a99b0), fontSize: 12, height: 1.35)),
              const SizedBox(height: 17),
              _label('Contact Number *'),
              const SizedBox(height: 7),
              _input(_contact, 'e.g. 09123456789', keyboardType: TextInputType.phone),
              const SizedBox(height: 17),
              _label('Location *'),
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
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Create Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
