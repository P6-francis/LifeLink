import 'package:flutter/material.dart';

class MessagesHeaderButton extends StatelessWidget {
  const MessagesHeaderButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: const BoxDecoration(
      color: Color(0x30ffffff),
      shape: BoxShape.circle,
    ),
    child: IconButton(
      onPressed: onPressed,
      tooltip: 'Messages',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      icon: const Icon(
        Icons.forum_rounded,
        color: Colors.white,
        size: 20,
      ),
    ),
  );
}
