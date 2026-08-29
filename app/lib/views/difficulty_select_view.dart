import 'package:flutter/material.dart';

import '../models/app_theme.dart';
import '../models/ai_difficulty.dart';

/// AI難易度選択画面（1人プレイ専用）
///
/// 「1人で遊ぶ → 役割選択 → 難易度選択 → ゲーム開始」という
/// フローに合わせて、役割選択（RoleSelectView）の後に表示する。
/// 以前はModeSelectView（遊び方選択画面）にあった難易度選択UIを
/// そのままこの画面に移植したもので、見た目・選択肢の内容は変更していない。
///
/// ローカル2人対戦ではAIを使わないため、この画面は経由しない。
class DifficultySelectView extends StatefulWidget {
  final void Function(AiDifficulty difficulty) onSelectDifficulty;
  final AiDifficulty initialDifficulty;
  final VoidCallback? onBack;

  const DifficultySelectView({
    super.key,
    required this.onSelectDifficulty,
    this.initialDifficulty = AiDifficulty.normal,
    this.onBack,
  });

  @override
  State<DifficultySelectView> createState() => _DifficultySelectViewState();
}

class _DifficultySelectViewState extends State<DifficultySelectView> {
  late AiDifficulty _difficulty = widget.initialDifficulty;

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
              if (widget.onBack != null) ...[
                TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('役割選択に戻る'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.appBarBackground,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'AIの難易度を選んでください',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.inkColor,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 8,
                children: AiDifficulty.values
                    .map(
                      (value) => InkWell(
                        onTap: () => setState(() => _difficulty = value),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<AiDifficulty>(
                                value: value,
                                groupValue: _difficulty,
                                onChanged: (v) =>
                                    setState(() => _difficulty = v!),
                              ),
                              Text(
                                value.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _difficulty == value
                                      ? theme.appBarBackground
                                      : theme.inkColor,
                                  fontWeight: _difficulty == value
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => widget.onSelectDifficulty(_difficulty),
                icon: const Icon(Icons.play_arrow),
                label: const Text('この難易度でゲーム開始'),
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
            ],
          ),
        ),
      ),
    );
  }
}
