import 'package:flutter/material.dart';

import '../../core/constants.dart';

class SourceBadge extends StatelessWidget {
  final String source;

  const SourceBadge({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (source) {
      AppConstants.sourceManual => ('Manual', const Color(0xFF4CAF50)),
      AppConstants.sourceGeminiContext => ('AI+Context', const Color(0xFF2196F3)),
      'offline' => ('Offline', const Color(0xFF9E9E9E)),
      _ => ('AI', const Color(0xFF9C27B0)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
