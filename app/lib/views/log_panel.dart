import 'package:flutter/material.dart';

/// アクションログを直近数件、新しいものほど濃く表示するパネル
class LogPanel extends StatelessWidget {
  final List<String> logHistory;

  const LogPanel({super.key, required this.logHistory});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: logHistory.asMap().entries.map((entry) {
          int index = entry.key;
          String msg = entry.value;
          double opacity = index == 0 ? 1.0 : (1.0 - (index * 0.15)).clamp(0.35, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              msg,
              style: TextStyle(
                fontSize: index == 0 ? 15 : 13,
                fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87.withOpacity(opacity),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
