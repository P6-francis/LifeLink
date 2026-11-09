import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../app/lifelink_theme.dart';
import '../../messaging/presentation/messages_screen.dart';
import '../../../services/location_geocoding_service.dart';
import '../../../widgets/async_state_view.dart';
import '../../../widgets/profile_avatar.dart';

class ActiveRequestsScreen extends StatefulWidget {
  const ActiveRequestsScreen({super.key});

  @override
  State<ActiveRequestsScreen> createState() => _ActiveRequestsScreenState();
}

class _ActiveRequestsScreenState extends State<ActiveRequestsScreen> {
  static const _red = Color(0xffcf2929);
  String? _selectedId;
  final Map<String, LatLng?> _resolvedCityLocations = {};
  final Set<String> _citiesBeingResolved = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> get _activeRequests =>
      FirebaseFirestore.instance.collectionGroup('requests').snapshots();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: LifeLinkColors.canvas,
    appBar: AppBar(
      backgroundColor: LifeLinkColors.red,
      foregroundColor: Colors.white,
      titleSpacing: 4,
      title: const Text(
        'Active Requests',
        style: TextStyle(color: Colors.white),
      ),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _activeRequests,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          return AsyncStateView.error(error: error);
        }
        if (!snapshot.hasData)
          return const AsyncStateView.loading(
            label: 'Finding active requests...',
          );

        final requests =
            snapshot.data!.docs
                .map(_RequestData.fromDocument)
                .where((request) => request.status == 'Active')
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _resolveMissingLocations(requests);
        _RequestData? selected;
        for (final request in requests) {
          if (request.id == _selectedId) selected = request;
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 22),
          children: [
            _mapPreview(requests),
            const SizedBox(height: 10),
            if (selected != null) ...[
              _selectedRequest(context, selected),
              const SizedBox(height: 10),
            ],
            const Text(
              'TAP A PIN OR SELECT BELOW',
              style: TextStyle(
                color: Color(0xff8b9ab2),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(height: 8),
            if (requests.isEmpty)
              const SizedBox(
                height: 260,
                child: AsyncStateView.empty(
                  title: 'No active requests',
                  message:
                      'New blood requests will appear here as soon as they are posted.',
                  icon: Icons.volunteer_activism_outlined,
                ),
              )
            else
              for (final request in requests) ...[
                _RequestTile(
                  data: request,
                  selected: request.id == _selectedId,
                  onTap: () => setState(() => _selectedId = request.id),
                ),
                const SizedBox(height: 8),
              ],
          ],
        );
      },
    ),
  );

  Widget _selectedRequest(BuildContext context, _RequestData request) {
    return _selectedRequestCard(context, request);
  }

  Widget _selectedRequestCard(BuildContext context, _RequestData request) {
    final name = request.requesterName;
    final isOwner = request.ownerId == FirebaseAuth.instance.currentUser?.uid;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffe9edf2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0d15233d),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(
                name: name,
                imageUrl: request.requesterAvatarUrl,
                userId: request.ownerId,
                radius: 22,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff17233b),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text(
                          'Blood Type:',
                          style: TextStyle(
                            color: Color(0xff8491a5),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _bloodTypeBadge(request.bloodType),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xffedf0f4)),
          ),
          _detailRow(Icons.local_hospital_outlined, request.hospital),
          const SizedBox(height: 7),
          _detailRow(Icons.location_on_outlined, request.city),
          const SizedBox(height: 7),
          _detailRow(Icons.phone_outlined, request.phone),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: isOwner
                ? FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: const Text('This is your request'),
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: const Color(0xffeef1f5),
                      disabledForegroundColor: const Color(0xff7b8799),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: () => _acceptRequest(context, request, name),
                    style: FilledButton.styleFrom(
                      backgroundColor: _red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const Icon(
                      Icons.volunteer_activism_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      'Accept Request',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(
    BuildContext context,
    _RequestData request,
    String requesterName,
  ) async {
    final donor = FirebaseAuth.instance.currentUser;
    if (donor == null || donor.uid == request.ownerId) return;
    final donorName = donor.displayName?.trim().isNotEmpty == true
        ? donor.displayName!.trim()
        : 'LifeLink donor';
    try {
      await FirebaseFirestore.instance.doc(request.id).update({
        'status': 'Accepted',
        'acceptedDonorId': donor.uid,
        'acceptedDonorName': donorName,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Request accepted. You can now coordinate with the requester.',
          ),
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            name: requesterName,
            recipientId: request.ownerId,
            recipientAvatarUrl: request.requesterAvatarUrl,
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Unable to accept this request.'),
          ),
        );
    }
  }

  Widget _mapPreview(List<_RequestData> requests) => SizedBox(
    height: 220,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(12.8797, 121.7740),
              initialZoom: 5.7,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lifelink',
              ),
              MarkerLayer(
                markers: [
                  for (final request in requests)
                    if (_mapLocation(request) != null)
                      Marker(
                        point: _mapLocation(request)!,
                        width: 50,
                        height: 57,
                        child: _RequestMapMarker(
                          request: request,
                          onTap: () => setState(() => _selectedId = request.id),
                        ),
                      ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 9,
            left: 9,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: IconButton(
                tooltip: 'Open full-screen map',
                icon: const Icon(Icons.fullscreen, color: _red),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _FullScreenRequestMap(
                      requests: requests,
                      resolvedLocations: _resolvedCityLocations,
                      onRequestSelected: (request) =>
                          setState(() => _selectedId = request.id),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 9, right: 9, child: _CountBadge(requests.length)),
        ],
      ),
    ),
  );

  LatLng? _mapLocation(_RequestData request) =>
      request.location ?? _resolvedCityLocations[request.id];

  void _resolveMissingLocations(List<_RequestData> requests) {
    for (final request in requests) {
      if (request.location != null ||
          _resolvedCityLocations.containsKey(request.id) ||
          !_citiesBeingResolved.add(request.id))
        continue;
      LocationGeocodingService.findPhilippineCity(city: request.city).then((
        location,
      ) {
        if (!mounted) return;
        setState(() {
          _resolvedCityLocations[request.id] = location == null
              ? null
              : LatLng(location.latitude, location.longitude);
          _citiesBeingResolved.remove(request.id);
        });
      });
    }
  }
}

class _FullScreenRequestMap extends StatelessWidget {
  const _FullScreenRequestMap({
    required this.requests,
    required this.resolvedLocations,
    required this.onRequestSelected,
  });

  final List<_RequestData> requests;
  final Map<String, LatLng?> resolvedLocations;
  final ValueChanged<_RequestData> onRequestSelected;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: LifeLinkColors.red,
      foregroundColor: Colors.white,
      title: const Text(
        'Active Requests Map',
        style: TextStyle(color: Colors.white),
      ),
    ),
    body: FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(12.8797, 121.7740),
        initialZoom: 5.7,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.lifelink',
        ),
        MarkerLayer(
          markers: [
            for (final request in requests)
              if (request.location != null ||
                  resolvedLocations[request.id] != null)
                Marker(
                  point: (request.location ?? resolvedLocations[request.id])!,
                  width: 50,
                  height: 57,
                  child: _RequestMapMarker(
                    request: request,
                    onTap: () {
                      onRequestSelected(request);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    ),
  );
}

class _RequestData {
  const _RequestData({
    required this.id,
    required this.ownerId,
    required this.requesterName,
    required this.bloodType,
    required this.city,
    required this.hospital,
    required this.phone,
    required this.status,
    required this.createdAt,
    this.requesterAvatarUrl,
    this.location,
  });
  factory _RequestData.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return _RequestData(
      id: document.reference.path,
      ownerId: data['ownerId'] as String? ?? '',
      requesterName: data['requesterName'] as String? ?? 'Requester',
      requesterAvatarUrl: (data['requesterAvatarUrl'] as String?)?.trim(),
      bloodType: data['bloodType'] as String? ?? 'Unknown',
      city: data['city'] as String? ?? 'Unknown city',
      hospital: data['hospital'] as String? ?? 'Unknown hospital',
      phone: data['contactNumber'] as String? ?? 'No contact number',
      status: data['status'] as String? ?? 'Active',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      location: _location(data),
    );
  }
  final String id,
      ownerId,
      requesterName,
      bloodType,
      city,
      hospital,
      phone,
      status;
  final String? requesterAvatarUrl;
  final DateTime createdAt;
  final LatLng? location;

  static LatLng? _location(Map<String, dynamic> data) {
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    if (latitude is num && longitude is num)
      return LatLng(latitude.toDouble(), longitude.toDouble());
    return null;
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.data,
    required this.selected,
    required this.onTap,
  });
  final _RequestData data;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: _cardDecoration(15, selected: selected),
          child: Row(
            children: [
              ProfileAvatar(
                name: data.requesterName,
                imageUrl: data.requesterAvatarUrl,
                userId: data.ownerId,
                radius: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.requesterName,
                      style: const TextStyle(
                        color: Color(0xff13223c),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Text(
                          'Blood type',
                          style: TextStyle(
                            color: Color(0xff8491a5),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 5),
                        _bloodTypeBadge(data.bloodType),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.city}  •  ${data.hospital}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff8390a6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(double radius, {bool selected = false}) =>
    BoxDecoration(
      color: Colors.white,
      border: selected ? Border.all(color: const Color(0xffcf2929)) : null,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    );
Widget _bloodTypeBadge(String bloodType) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: const Color(0xffcf2929)),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    bloodType,
    style: const TextStyle(
      color: Color(0xffcf2929),
      fontSize: 11,
      fontWeight: FontWeight.w800,
    ),
  ),
);
Widget _detailRow(IconData icon, String text) => Row(
  children: [
    Icon(icon, size: 16, color: const Color(0xff8a99b0)),
    const SizedBox(width: 7),
    Expanded(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xff687891),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ],
);
const _requestMarkerColor = Color(0xffcf2929);

class _RequestMapMarker extends StatelessWidget {
  const _RequestMapMarker({required this.request, required this.onTap});
  final _RequestData request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: _requestMarkerColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x25000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ProfileAvatar(
                name: request.requesterName,
                imageUrl: request.requesterAvatarUrl,
                userId: request.ownerId,
                radius: 18,
              ),
            ),
            Positioned(
              right: -8,
              bottom: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xffcf2929),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  request.bloodType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const CustomPaint(
          size: Size(10, 7),
          painter: _PointerPainter(_requestMarkerColor),
        ),
      ],
    ),
  );
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '• $count active',
      style: const TextStyle(
        color: Color(0xffd9212a),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
