import 'package:flutter/material.dart';

/// アクションログを直近数件、新しいものほど濃く表示するパネル。
/// パネルの高さは固定（各行1行に収まるよう省略表示）にすることで、
/// メッセージの長さによってゲーム盤面の位置がガタつくのを防いでいる。
class LogPanel extends StatelessWidget {
  final List<String> logHistory;

  static const int maxEntries = 6;
  static const double _lineHeight = 24;
  static const double _verticalPadding = 16; // 上下 8px ずつ

  const LogPanel({super.key, required this.logHistory});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: maxEntries * _lineHeight + _verticalPadding,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: logHistory.asMap().entries.map((entry) {
            int index = entry.key;
            String msg = entry.value;
            double opacity = index == 0
                ? 1.0
                : (1.0 - (index * 0.15)).clamp(0.35, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                msg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: index == 0 ? 15 : 13,
                  fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black87.withValues(alpha: opacity),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
