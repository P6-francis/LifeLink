import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'messages_header_button.dart';

class LifeLinkHeader extends StatelessWidget {
  const LifeLinkHeader({
    super.key,
    required this.title,
    required this.onMessagesPressed,
  });

  final Widget title;
  final VoidCallback onMessagesPressed;

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    color: const Color(0xffcf2929),
    child: Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: SvgPicture.asset('assets/lifelink_logo.svg'),
        ),
        const SizedBox(width: 10),
        Expanded(child: title),
        MessagesHeaderButton(onPressed: onMessagesPressed),
      ],
    ),
  );
}

Text lifeLinkHeaderTitle(String value) => Text(
  value,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  ),
);
