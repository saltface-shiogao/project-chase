import 'package:flutter/material.dart';

/// アクションログを直近数件、新しいものほど濃く表示するパネル。
///
/// 表示件数・文字省略ロジックはこれまでと同じ。
/// width / height を外部から指定できるようにし、呼び出し側（画面レイアウト）が
/// 「盤面の左に縦長で配置する」「盤面の上に横長で配置する」など、
/// 配置方法を自由に決められるようにしている（このウィジェット自体は
/// レイアウト位置に関する前提を持たない＝ロジックと配置の分離）。
/// width / height を指定しない場合は、従来通りの横長・固定高さで表示する。
class LogPanel extends StatelessWidget {
  final List<String> logHistory;
  final double? width;
  final double? height;

  static const int maxEntries = 6;
  static const double _lineHeight = 24;
  static const double _verticalPadding = 16; // 上下 8px ずつ

  const LogPanel({
    super.key,
    required this.logHistory,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? (maxEntries * _lineHeight + _verticalPadding),
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
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                msg,
                // 折り返し表示にして全文が読めるようにする（省略しない）。
                // パネル自体の width / height は呼び出し側（game_page.dart）が
                // 固定値で渡しており、この変更後もゲーム中にサイズが変わることはない。
                softWrap: true,
                style: TextStyle(
                  fontSize: index == 0 ? 15 : 13,
                  fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black87.withOpacity(opacity),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
