import 'package:flutter/material.dart';

import '../inti/tema_aplikasi.dart';

class KeadaanKosong extends StatelessWidget {
  const KeadaanKosong({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 52 : 68,
              height: compact ? 52 : 68,
              decoration: const BoxDecoration(
                color: WarnaAplikasi.cream,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 26 : 32,
                color: WarnaAplikasi.primaryDark,
              ),
            ),
            SizedBox(height: compact ? 10 : 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w800,
                color: WarnaAplikasi.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: WarnaAplikasi.muted,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
