import 'package:flutter/material.dart';

/// アクションログを直近数件、新しいものほど濃く表示するパネル。
///
/// 表示件数・文字省略ロジックはこれまでと同じ。
/// width / height を外部から指定できるようにし、呼び出し側（画面レイアウト）が
/// 「盤面の左に縦長で配置する」「盤面の上に横長で配置する」など、
/// 配置方法を自由に決められるようにしている（このウィジェット自体は
/// レイアウト位置に関する前提を持たない＝ロジックと配置の分離）。
/// width / height を指定しない場合は、従来通りの横長・固定高さで表示する。
///
/// [highlightMessage] を渡すと、枠の一番上に色帯の「注目エリア」を表示する。
/// 捜索結果など「アクションを起こした結果」だけをここに載せる想定で、
/// 移動・待機・案内文などは対象外（呼び出し側で選別する）。
/// [isGameOver] が true の間は、注目エリアの色を勝敗を知らせる強い色に変える。
class LogPanel extends StatelessWidget {
  final List<String> logHistory;
  final double? width;
  final double? height;
  final String? highlightMessage;
  final bool isGameOver;

  static const int maxEntries = 6;
  static const double _lineHeight = 24;
  static const double _verticalPadding = 16; // 上下 8px ずつ
  static const double _highlightHeight = 64;

  const LogPanel({
    super.key,
    required this.logHistory,
    this.width,
    this.height,
    this.highlightMessage,
    this.isGameOver = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height:
          height ??
          (maxEntries * _lineHeight +
              _verticalPadding +
              (highlightMessage != null ? _highlightHeight : 0)),
      // 配置を決める余白は親レイアウトで管理する。ここで余白を足すと、
      // 指定された幅・高さよりパネルが大きくなり、盤面との整列が崩れる。
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (highlightMessage != null)
            Container(
              height: _highlightHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isGameOver
                    ? const Color(0xFFB5533C) // brick（勝敗）
                    : const Color(0xFF2B3A55), // ink navy（捜索結果）
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFC9A227), width: 3),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  highlightMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE8DCC3),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        fontWeight: index == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: Colors.black87.withValues(alpha: opacity),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
