import 'package:flutter/material.dart';

import '../inti/tema_aplikasi.dart';

class KartuStatistik extends StatelessWidget {
  const KartuStatistik({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.softColor = Colors.white,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color softColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WarnaAplikasi.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: WarnaAplikasi.muted,
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color == WarnaAplikasi.muted ? WarnaAplikasi.ink : color,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: WarnaAplikasi.muted),
            ),
          ],
        ],
      ),
    );
  }
}
