import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../widgets/app_notice.dart';

class DonorMapScreen extends StatefulWidget {
  const DonorMapScreen({super.key});
  @override State<DonorMapScreen> createState() => _DonorMapScreenState();
}

class _DonorMapScreenState extends State<DonorMapScreen> {
  final _cityController = TextEditingController();
  int? _distanceKm = 1;
  String _bloodType = 'Any';
  bool _isBloodTypeMenuOpen = false;
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _searchError;
  List<_Donor> _donors = const [];

  int get _currentDistanceKm => _distanceKm ?? 1;

  @override void dispose() { _cityController.dispose(); super.dispose(); }
  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchError = null;
    });

    try {
      final city = _cityController.text.trim().toLowerCase();
      final snapshot = await FirebaseFirestore.instance
          .collection('donors')
          .where('isAvailable', isEqualTo: true)
          .get();
      final donors = snapshot.docs
          .map((document) => _Donor.fromDocument(document))
          .where(
            (donor) =>
                (_bloodType == 'Any' || donor.bloodType == _bloodType) &&
                (city.isEmpty || donor.city.toLowerCase().contains(city)),
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() => _donors = donors);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _searchError = error.message ?? 'Unable to load donors.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _changeDistance(int change) {
    setState(() => _distanceKm = (_currentDistanceKm + change).clamp(1, 500).toInt());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff7f8fa),
    appBar: AppBar(
      backgroundColor: const Color(0xffcf2929), foregroundColor: Colors.white, elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: SvgPicture.asset('assets/lifelink_logo.svg'),
      ),
      leadingWidth: 58,
      title: const Text('Find Donors', style: TextStyle(fontWeight: FontWeight.w700)),
    ),
    body: ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 24), children: [
      _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Find Donors', style: TextStyle(color: Color(0xffd02020), fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Browse available donors instantly. Smart ranking\nautomatically prioritizes best donor matches first.', style: TextStyle(color: Color(0xff52627c), fontSize: 13.5, height: 1.35)),
        const SizedBox(height: 20),
        Row(children: [const Text('Blood Type', style: TextStyle(color: Color(0xff13223c), fontSize: 16, fontWeight: FontWeight.w600)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xffcf2929), borderRadius: BorderRadius.circular(16)), child: const Text('Advanced Filters ENABLED', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)))]),
        const SizedBox(height: 12),
        _bloodTypeDropdown(),
        const SizedBox(height: 16), _label('City / Municipality'), const SizedBox(height: 7),
        _field(child: _plainTextField(controller: _cityController, hintText: 'e.g. Manila or Bacnotan')),
        const SizedBox(height: 16), _label('Distance Range (km)'), const SizedBox(height: 7),
        _field(child: Row(children: [Expanded(child: Text('$_currentDistanceKm', style: const TextStyle(color: Color(0xff342e2e), fontSize: 16))), Column(mainAxisSize: MainAxisSize.min, children: [_distanceButton(icon: Icons.keyboard_arrow_up, tooltip: 'Increase distance', onPressed: () => _changeDistance(1)), _distanceButton(icon: Icons.keyboard_arrow_down, tooltip: 'Decrease distance', onPressed: () => _changeDistance(-1))])])),
        const SizedBox(height: 14), Row(children: [Expanded(child: _outlineButton('Use My Location', Icons.my_location, () => showNotice(context, 'Using your current location.'))), const SizedBox(width: 10), Expanded(child: _outlineButton('Pin Search Area', Icons.location_on_outlined, () => showNotice(context, 'Tap the map to pin a search area.')))]),
        const SizedBox(height: 14), SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: _isSearching ? null : _search, style: FilledButton.styleFrom(backgroundColor: const Color(0xffcf2929), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))), child: _isSearching ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Search Donors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      ])),
      const SizedBox(height: 15), _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Text('Donor Map', style: TextStyle(color: Color(0xff263651), fontSize: 16, fontWeight: FontWeight.w700)), const Spacer(), TextButton(onPressed: () => showNotice(context, 'Opening Google Maps is not configured yet.'), child: const Text('Open in Google Maps', style: TextStyle(color: Color(0xffd02020), fontWeight: FontWeight.w600)))]),
        Container(height: 162, width: double.infinity, decoration: BoxDecoration(color: const Color(0xffe6f3f0), borderRadius: BorderRadius.circular(14)), child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: const Size(double.infinity, 162), painter: _GridPainter()),
          const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.location_on, color: Color(0xffcf2929), size: 26), Text('Map view', style: TextStyle(color: Color(0xff52627c)))]),
          const Positioned(left: 10, bottom: 9, child: Text('Donor exact pins are hidden for privacy until request acceptance.', style: TextStyle(color: Color(0xff8292ae), fontSize: 11))),
        ])),
      ])),
      if (_hasSearched) ...[
        const SizedBox(height: 15),
        _panel(child: _searchResults()),
      ],
    ]),
  );

  Widget _searchResults() {
    if (_searchError != null) {
      return Text(_searchError!, style: const TextStyle(color: Color(0xffcf2929)));
    }
    if (_donors.isEmpty) {
      return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('No matching donors', style: TextStyle(color: Color(0xff263651), fontSize: 16, fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text('Try another blood type or city. Available donors will appear here.', style: TextStyle(color: Color(0xff52627c), height: 1.35)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${_donors.length} matching donor${_donors.length == 1 ? '' : 's'}', style: const TextStyle(color: Color(0xff263651), fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      ..._donors.map((donor) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundColor: const Color(0xffffe8ec), child: Text(donor.bloodType, style: const TextStyle(color: Color(0xffcf2929), fontSize: 11, fontWeight: FontWeight.w800))),
        title: Text(donor.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(donor.city.isEmpty ? 'Location not provided' : donor.city),
      )),
    ]);
  }

  Widget _label(String text) => Text(text, style: const TextStyle(color: Color(0xff13223c), fontSize: 16, fontWeight: FontWeight.w600));
  Widget _bloodTypeDropdown() => Column(children: [
    _field(child: InkWell(onTap: () => setState(() => _isBloodTypeMenuOpen = !_isBloodTypeMenuOpen), child: Row(children: [Text(_bloodType, style: const TextStyle(color: Colors.black, fontSize: 16)), const Spacer(), Icon(_isBloodTypeMenuOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black, size: 21)]))),
    if (_isBloodTypeMenuOpen) _bloodTypeOptions(),
  ]);
  Widget _bloodTypeOptions() => Container(decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xffdfe3e9)), right: BorderSide(color: Color(0xffdfe3e9)))), child: Column(children: [for (final type in const ['Any', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']) _bloodTypeOption(type), Container(height: 18, decoration: const BoxDecoration(color: Color(0xffcf2929), borderRadius: BorderRadius.vertical(bottom: Radius.circular(10))))]));
  Widget _bloodTypeOption(String type) { final selected = type == _bloodType; return InkWell(onTap: () => setState(() { _bloodType = type; _isBloodTypeMenuOpen = false; }), child: Container(height: 30, width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 17), alignment: Alignment.centerLeft, color: selected ? const Color(0xff808080) : Colors.white, child: Text(type, style: TextStyle(color: selected ? Colors.white : Colors.black, fontSize: 16)))); }
  Widget _field({required Widget child}) => Container(height: 47, padding: const EdgeInsets.symmetric(horizontal: 13), alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: const Color(0xffdfe3e9)), borderRadius: BorderRadius.circular(13)), child: child);
  Widget _distanceButton({required IconData icon, required String tooltip, required VoidCallback onPressed}) => SizedBox(width: 34, height: 21, child: IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 34, height: 21), visualDensity: VisualDensity.compact, tooltip: tooltip, onPressed: onPressed, icon: Icon(icon, color: const Color(0xff8c8f94), size: 20)));
  Widget _plainTextField({required TextEditingController controller, String? hintText, TextInputType? keyboardType}) => TextField(controller: controller, keyboardType: keyboardType, style: const TextStyle(color: Color(0xff342e2e), fontSize: 16), decoration: InputDecoration(hintText: hintText, hintStyle: const TextStyle(color: Color(0xff777079), fontSize: 16), isDense: true, contentPadding: EdgeInsets.zero, filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, disabledBorder: InputBorder.none));
  Widget _panel({required Widget child}) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))]), child: child);
  Widget _outlineButton(String label, IconData icon, VoidCallback onPressed) => SizedBox(height: 43, child: OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 17), label: Text(label), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xffcf2929), side: const BorderSide(color: Color(0xffcf2929)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)))));
}

class _Donor {
  const _Donor({required this.name, required this.bloodType, required this.city});

  factory _Donor.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? const <String, dynamic>{};
    return _Donor(
      name: data['name'] as String? ?? 'LifeLink donor',
      bloodType: data['bloodType'] as String? ?? 'Unknown',
      city: data['city'] as String? ?? '',
    );
  }

  final String name;
  final String bloodType;
  final String city;
}

class _GridPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) { final paint = Paint()..color = const Color(0x22718b91)..strokeWidth = 1; for (double x = 0; x < size.width; x += 55) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint); } for (double y = 0; y < size.height; y += 33) { canvas.drawLine(Offset(0, y), Offset(size.width, y), paint); } }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
