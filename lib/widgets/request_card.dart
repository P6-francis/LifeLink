import 'package:flutter/material.dart';

class BloodRequest {
  const BloodRequest({required this.name, required this.group, required this.hospital, required this.distance, this.urgent = false});

  final String name;
  final String group;
  final String hospital;
  final String distance;
  final bool urgent;
}

class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, this.onHelp});

  final BloodRequest request;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xffffe8ea),
                  child: Text(request.group, style: const TextStyle(color: Color(0xffd9283b), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(request.hospital, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                if (request.urgent) const Chip(label: Text('URGENT', style: TextStyle(fontSize: 10, color: Color(0xffc92134))), backgroundColor: Color(0xffffe7e9), side: BorderSide.none),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(request.distance, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                TextButton(onPressed: onHelp, child: const Text('I can help')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
