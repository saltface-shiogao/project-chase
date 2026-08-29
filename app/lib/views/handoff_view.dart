import 'package:flutter/material.dart';

import '../models/app_theme.dart';
import '../models/game_phase.dart';

/// ローカル2人対戦：ターン交代時の「受け渡し画面」。
///
/// 画面全体（盤面・ログを含む）をこのウィジェットで完全に置き換えることで、
/// 次のプレイヤー以外に非公開情報（犯人の車位置・移動履歴など）が
/// 見えてしまうことを防ぐ。
///
/// - phase == handoffToCriminal（警察→犯人の受け渡し）：
///   直前まで警察側が盤面を見ていたため、受け渡し中は誤操作防止のため
///   リセットボタン自体を表示しない（onReset を渡さないこと）。
/// - phase == handoffToPolice（犯人→警察の受け渡し）：
///   盤面は元々隠していない向きなので、リセットボタンは表示してよいが、
///   誤タップ防止のため確認ダイアログを挟む（onReset を渡すこと）。
class HandoffView extends StatelessWidget {
  final GamePhase phase;
  final VoidCallback onContinue;
  final VoidCallback? onReset;

  const HandoffView({
    super.key,
    required this.phase,
    required this.onContinue,
    this.onReset,
  });

  bool get _isToCriminal => phase == GamePhase.handoffToCriminal;

  @override
  Widget build(BuildContext context) {
    final String headline = _isToCriminal
        ? '警察プレイヤーの操作が終わりました。'
        : '犯人プレイヤーの操作が終わりました。';
    final String body = _isToCriminal
        ? '端末を犯人プレイヤーに渡してください。犯人プレイヤー以外の方は画面を見ないようにお願いします。'
        : '端末を警察プレイヤーに渡してください。';
    final String buttonLabel = _isToCriminal
        ? '犯人プレイヤーの準備ができたら続ける'
        : '警察プレイヤーの準備ができたら続ける';
    final IconData headlineIcon = _isToCriminal
        ? Icons.directions_car
        : Icons.local_police;
    final theme = AppTheme.boardGame();

    return Scaffold(
      backgroundColor: theme.appBarBackground,
      appBar: onReset != null
          ? AppBar(
              backgroundColor: theme.appBarBackground,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: theme.appBarForeground.withValues(alpha: 0.8),
                  ),
                  tooltip: 'リセット（役割選択に戻る）',
                  onPressed: () => _confirmReset(context),
                ),
              ],
            )
          : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                headlineIcon,
                color: theme.appBarForeground.withValues(alpha: 0.8),
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.appBarForeground,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.appBarForeground.withValues(alpha: 0.8),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward),
                label: Text(buttonLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.pendingSearchColor,
                  foregroundColor: theme.inkColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('リセットしますか？'),
        content: const Text('現在の対戦を終了し、役割選択画面に戻ります。この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onReset!();
            },
            child: const Text('リセットする', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
