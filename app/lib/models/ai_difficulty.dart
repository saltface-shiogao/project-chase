/// 1人プレイ時のAIの判断力。
enum AiDifficulty { easy, normal, hard }

extension AiDifficultyLabel on AiDifficulty {
  String get label => switch (this) {
        AiDifficulty.easy => 'やさしい',
        AiDifficulty.normal => 'ふつう',
        AiDifficulty.hard => 'むずかしい',
      };
}
