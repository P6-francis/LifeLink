import 'package:flutter/material.dart';

import 'messages_screen.dart';

class ActiveRequestsScreen extends StatefulWidget {
  const ActiveRequestsScreen({super.key});
  @override State<ActiveRequestsScreen> createState() => _ActiveRequestsScreenState();
}

class _ActiveRequestsScreenState extends State<ActiveRequestsScreen> {
  static const _red = Color(0xffcf2929);
  final _requests = const [
    _RequestData('Maria Santos', 'A+', 'Bacnotan', 'Bacnotan District Hospital', 'Urgent', '34', '09171234567'),
    _RequestData('Juan Dela Cruz', 'O-', 'San Fernando', 'LMMC, San Fernando', 'Critical', '42', '09181234567'),
    _RequestData('Ana Reyes', 'B+', 'Naguilian', 'Naguilian Rural Hospital', 'Normal', '29', '09191234567'),
    _RequestData('Pedro Lim', 'AB+', 'Bauang', 'Bauang District Hospital', 'Urgent', '51', '09201234567'),
    _RequestData('Rosa Mendoza', 'O+', 'Agoo', 'Agoo Community Hospital', 'Normal', '38', '09211234567'),
  ];
  int? _selected;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff7f8fa),
        appBar: AppBar(backgroundColor: _red, foregroundColor: Colors.white, elevation: 0, titleSpacing: 4, title: const Text('Active Requests', style: TextStyle(fontWeight: FontWeight.w700))),
        body: ListView(padding: const EdgeInsets.fromLTRB(13, 12, 13, 22), children: [
          _mapPreview(),
          const SizedBox(height: 10),
          if (_selected != null) ...[_selectedRequest(context), const SizedBox(height: 10)],
          const Text('TAP A PIN OR SELECT BELOW', style: TextStyle(color: Color(0xff8b9ab2), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .7)),
          const SizedBox(height: 8),
          for (var index = 0; index < _requests.length; index++) ...[_RequestTile(data: _requests[index], selected: index == _selected, onTap: () => setState(() => _selected = index)), if (index < _requests.length - 1) const SizedBox(height: 8)],
        ]),
      );

  Widget _selectedRequest(BuildContext context) { final request = _requests[_selected!]; return Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xffc81722), borderRadius: BorderRadius.circular(11)), child: Text(request.bloodType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(request.name, style: const TextStyle(color: Color(0xff13223c), fontSize: 16, fontWeight: FontWeight.w700)), Text('Age: ${request.age}', style: const TextStyle(color: Color(0xff71819a), fontSize: 12))])), _Pill(request.urgency, const Color(0xffffe8ec), const Color(0xffd9212a))]),
    const SizedBox(height: 8), Text('📍 ${request.city}\n🏥 ${request.hospital}\n📞 ${request.phone}', style: const TextStyle(color: Color(0xff71819a), fontSize: 12, height: 1.35)), const SizedBox(height: 10), Row(children: [Expanded(child: SizedBox(height: 40, child: FilledButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(name: request.name))), style: FilledButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))), child: const Text('Respond to Request', style: TextStyle(fontWeight: FontWeight.w700))))), const SizedBox(width: 7), SizedBox(width: 40, height: 40, child: FilledButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(name: request.name))), style: FilledButton.styleFrom(backgroundColor: const Color(0xffffe8ec), foregroundColor: _red, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))), child: const Icon(Icons.chat_bubble, size: 18)))])
  ])); }

  Widget _mapPreview() => Container(
        height: 185,
        decoration: BoxDecoration(color: const Color(0xffdcebcf), borderRadius: BorderRadius.circular(14)),
        child: Stack(children: [
          CustomPaint(size: const Size(double.infinity, 185), painter: _MapRoadsPainter()),
          const Positioned(top: 9, right: 9, child: _CountBadge()),
          const _MapPin(left: 67, top: 35, type: 'A+', color: _red),
          const _MapPin(left: 36, top: 71, type: 'O+', color: Color(0xff22853a)),
          const _MapPin(left: 101, top: 92, type: 'B+', color: Color(0xff22853a)),
          const _MapPin(left: 152, top: 65, type: 'O-', color: _red),
          const _MapPin(left: 198, top: 23, type: 'AB+', color: _red),
          const Positioned(left: 9, bottom: 9, child: Row(children: [_Legend('Critical', _red), SizedBox(width: 5), _Legend('Urgent', Color(0xffdf3030)), SizedBox(width: 5), _Legend('Normal', Color(0xff22853a))])),
        ]),
      );
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.data, required this.selected, required this.onTap});
  final _RequestData data; final bool selected; final VoidCallback onTap;
  bool get critical => data.urgency == 'Critical';
  bool get normal => data.urgency == 'Normal';
  @override Widget build(BuildContext context) => Material(color: Colors.white, borderRadius: BorderRadius.circular(15), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10), decoration: BoxDecoration(border: selected ? Border.all(color: const Color(0xffcf2929)) : null, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))]), child: Row(children: [
    Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: normal ? const Color(0xff21863a) : const Color(0xffc81722), borderRadius: BorderRadius.circular(9)), child: Text(data.bloodType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data.name, style: const TextStyle(color: Color(0xff13223c), fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('⚑  ${data.city}  ·  ▣  ${data.hospital}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff8390a6), fontSize: 11))])), const SizedBox(width: 5), _Pill(data.urgency, critical ? const Color(0xffffe8ec) : normal ? const Color(0xffe7f5e8) : const Color(0xffffe8ec), critical ? const Color(0xffd9212a) : normal ? const Color(0xff20913a) : const Color(0xffd9212a)),
  ]))));
}

class _RequestData { const _RequestData(this.name, this.bloodType, this.city, this.hospital, this.urgency, this.age, this.phone); final String name, bloodType, city, hospital, urgency, age, phone; }

class _MapPin extends StatelessWidget { const _MapPin({required this.left, required this.top, required this.type, required this.color}); final double left, top; final String type; final Color color; @override Widget build(BuildContext context) => Positioned(left: left, top: top, child: Column(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3)]), child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))), CustomPaint(size: const Size(10, 7), painter: _PointerPainter(color))])); }
class _CountBadge extends StatelessWidget { const _CountBadge(); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Text('• 5 active', style: TextStyle(color: Color(0xffd9212a), fontSize: 10, fontWeight: FontWeight.w700))); }
class _Legend extends StatelessWidget { const _Legend(this.text, this.color); final String text; final Color color; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(radius: 2.5, backgroundColor: color), const SizedBox(width: 3), Text(text, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700))])); }
class _MapRoadsPainter extends CustomPainter { @override void paint(Canvas canvas, Size size) { final road = Paint()..color = const Color(0xffc0d6b8)..strokeWidth = 5; canvas.drawLine(Offset(0, 51), Offset(size.width, 40), road); canvas.drawLine(Offset(0, 102), Offset(size.width, 81), road); canvas.drawLine(Offset(140, 0), Offset(164, size.height), road); canvas.drawLine(Offset(238, 0), Offset(255, size.height), road); final water = Paint()..color = const Color(0xffbcdbe0); canvas.drawOval(Rect.fromLTWH(7, 147, 90, 43), water); canvas.drawOval(Rect.fromLTWH(size.width - 82, 132, 105, 53), water); } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }
class _PointerPainter extends CustomPainter { const _PointerPainter(this.color); final Color color; @override void paint(Canvas canvas, Size size) { final path = Path()..moveTo(0, 0)..lineTo(size.width, 0)..lineTo(size.width / 2, size.height)..close(); canvas.drawPath(path, Paint()..color = color); } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }
class _Pill extends StatelessWidget { const _Pill(this.text, this.bg, this.fg); final String text; final Color bg, fg; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Text(text, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700))); }
