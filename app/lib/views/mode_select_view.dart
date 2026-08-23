import 'package:flutter/material.dart';

import '../models/app_theme.dart';

/// 遊び方選択画面（1人プレイ / ローカル2人対戦）
///
/// 役割選択画面（RoleSelectView）の「前」に表示する画面。
/// 以前はこの画面でAI難易度も同時に選ばせていたが、
/// 「1人で遊ぶ → 役割選択 → 難易度選択 → ゲーム開始」という
/// フローに変更したため、難易度選択はDifficultySelectView
/// （役割選択の後）に移動した。この画面では遊び方の選択のみ行う。
///
/// 1人プレイを選んだ場合は、これまで通り RoleSelectView
///（「警察役でプレイ（AIが犯人）」「犯人役でプレイ（AIが警察）」）へ進む想定。
/// 2人対戦を選んだ場合は、AIの説明を含まない別の文言の役割選択
///（次のステップで対応）へ進む想定。
enum PlayMode { singlePlayer, localTwoPlayer }

class ModeSelectView extends StatelessWidget {
  final void Function(PlayMode mode) onSelectMode;

  const ModeSelectView({super.key, required this.onSelectMode});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.boardGame();
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('シティチェイス'),
        backgroundColor: theme.appBarBackground,
        foregroundColor: theme.appBarForeground,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '遊び方を選んでください',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.inkColor,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => onSelectMode(PlayMode.singlePlayer),
                icon: const Icon(Icons.smart_toy),
                label: const Text('1人で遊ぶ（AI対戦）'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.appBarBackground,
                  foregroundColor: theme.appBarForeground,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => onSelectMode(PlayMode.localTwoPlayer),
                icon: const Icon(Icons.people_alt),
                label: const Text('2人で対戦する（同じ端末で交互プレイ）'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.moveCandidateColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
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
}
