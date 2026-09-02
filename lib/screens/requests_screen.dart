import 'package:flutter/material.dart';

import 'create_request_screen.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  static const _red = Color(0xffcf2929);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff7f8fa),
        body: Column(
          children: [
            Container(
              height: 61,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              color: _red,
              child: const Row(children: [
                CircleAvatar(radius: 18, backgroundColor: Color(0x33ffffff), child: Icon(Icons.water_drop, color: Color(0xffe97878), size: 24)),
                SizedBox(width: 14),
                Text('My Requests', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
              ]),
            ),
            Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(18, 19, 18, 24), children: [
              Row(children: [
                const Text('Blood Requests', style: TextStyle(color: Color(0xff10213c), fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                SizedBox(height: 40, child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
                  style: FilledButton.styleFrom(backgroundColor: _red, padding: const EdgeInsets.symmetric(horizontal: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('New Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                )),
              ]),
              const SizedBox(height: 14),
              const _MyRequestCard(name: 'Roberto C.', bloodType: 'A+', location: 'LMMC', urgency: 'Urgent', age: '2h ago', status: 'Active'),
              const SizedBox(height: 12),
              const _MyRequestCard(name: 'Elena M.', bloodType: 'O-', location: 'Ilocos Sur Provincial', urgency: 'Normal', age: '1d ago', status: 'Fulfilled'),
            ])),
          ],
        ),
      );
}

class _MyRequestCard extends StatelessWidget {
  const _MyRequestCard({required this.name, required this.bloodType, required this.location, required this.urgency, required this.age, required this.status});

  final String name, bloodType, location, urgency, age, status;
  bool get _isActive => status == 'Active';

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 5, offset: Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(name, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            _pill(bloodType, const Color(0xffffe8ec), const Color(0xffd9283b)),
            const Spacer(),
            _pill(status, _isActive ? const Color(0xffe7f5e8) : const Color(0xffffe8ea), _isActive ? const Color(0xff20913a) : const Color(0xffe03030)),
          ]),
          const SizedBox(height: 4),
          Text(location, style: const TextStyle(color: Color(0xff536580), fontSize: 14)),
          const SizedBox(height: 3),
          Text('Urgency: $urgency  ·  $age', style: const TextStyle(color: Color(0xff8a99b0), fontSize: 14)),
        ]),
      );

  Widget _pill(String label, Color background, Color foreground) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
        child: Text(label, style: TextStyle(color: foreground, fontSize: 13, fontWeight: FontWeight.w700)),
      );
}
