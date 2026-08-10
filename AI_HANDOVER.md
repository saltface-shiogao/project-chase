# AI_HANDOVER.md

> Project ChaseのAI・チャットルーム・担当AIが交代する際に、直前の作業状態から安全に再開するための引き継ぎ専用ファイル。
> 
> このファイルは正式な仕様書ではありません。既存のProject Chaseドキュメントを補完し、「今この瞬間の作業状態」を引き継ぐことを目的とします。

## 1. 引き継ぎ情報

- 最終更新日時：2026-08-10
- 最後に作業したAI：Gemini
- 作業環境：Windows 11 / VS Code / Flutter Web（Chrome）/ Git / Obsidian
- 現在の作業段階：Obsidian Git同期環境の構築完了・プロジェクト保全作業前
- 引き継ぎ状態：**正常動作確認済みのClaude分割版を基準候補として保全する段階（PC環境のGit準備完了）**

## 2. 現在の作業

### 現在取り組んでいるタスク
Project Chaseのコード破綻から復旧し、今後AIが交代しても安全に開発を継続できる運用を整える。

1. **[完了] PC側Git・Obsidian環境の構築**

- スマホとPCで別々に作成されていたGitHubリポジトリ（`01_siogao`）の一本化。
- PCでの `git clone` 実行とディレクトリ構成（二重フォルダ・ユーザー直下 `.git`）の修復。
- PCのObsidianコミュニティプラグイン「Obsidian Git」の自動同期設定（`Auto push`: 10分, `Auto pull`: 10分, `Pull on startup`: ON）。
2. **[次タスク] Project Chase正常動作版の保全とGitHub保存**

- 復旧確認済みのClaudeコード分割版（`ProjectChase_ClaudeRecovery\ProjectChase`）を基準版として、GitHubへ安全に保存・バックアップする。

### 現在の段階
**Obsidianの端末間（スマホ/PC）Git同期設定完了。次は `project-Chase` 正常動作確認済み状態をGitHubへ保存する段階。**

## 3. 直前に行った変更

### Obsidian & Git同期環境の修正・設定

- **PC側のGit環境修復**: ユーザーフォルダ直下に誤って作られていた `.git` を削除し、`C:\Users\exile\Documents\ObsidianVault\01_siogao` に正常に `git clone` を実施。
- **Obsidian Gitプラグイン設定**: PC側Obsidianで `Auto push interval` (10分)、`Auto pull interval` (10分)、`Pull updates on startup` (ON) を設定し、スマホとPCで最新メモが自動同期される環境を構築。

### コード分割・復旧の経緯（前セッションより引き継ぎ）

- 元の `lib/main.dart` が肥大化したため、Claudeがゲームロジックを変更せずにコード分割を実施。
- Claudeの利用制限に伴いGeminiが引き継いだが、意図しない変更（盤面崩れ・ヘリ動作不具合・ターン数狂い）が発生。
- 別検証環境（`ProjectChase_ClaudeRecovery\ProjectChase`）にてClaude分割版を配置し、`flutter run -d chrome` で正常動作を再確認。

## 4. 現在の状態

### 正常動作を確認済み（基準候補）
検証環境：

Plaintext

```
ProjectChase_ClaudeRecovery\ProjectChase
```

確認済み事項：

- ゲーム起動
- 5×5盤面
- 犯人／警察の役割選択
- ゲームが正常に復活していること

### PC作業環境の状態

- **Obsidian**: PCでのGit cloneおよびObsidian Git設定完了。リポジトリ `01_siogao` と正常に同期。
- **Git**: PC上の `git status` がクリーンであり、`origin/main` と同期完了。

### 未確認・留意事項

- 全11ラウンドを通した完全な動作および全敗勝条件
- iOS / Android 実機での動作
- Claude分割版と分割前正常版の完全な回帰テスト

## 5. 最後に正常だった状態
現在の基準候補：

Plaintext

```
ProjectChase_ClaudeRecovery\ProjectChase
```

**この状態を「正常動作確認済みの基準版候補」として扱う。**
GitHubへの保存が完了するまでは、不要なコード変更を加えない。

## 6. バックアップ / Git状態

### 現在のステータス

- **Obsidian環境**: GitHub（`01_siogao`）での同期・バックアップ環境確立済み。
- **Project Chaseコード**: 正常動作確認済みClaude版のGitHub保存は**未実施（次の最優先タスク）**。
- ローカルの復旧用コピー（`ProjectChase_ClaudeRecovery`）：あり。

## 7. 次にやること
優先順位：

### 最優先

1. **現在の正常動作確認済みClaude版（`ProjectChase_ClaudeRecovery`）の保全**
2. 既存のGitHubリポジトリ `project-Chase` の現在の構成・状態を確認する
3. 正常動作確認済みClaude版をGitHubへコミット＆プッシュ（保存）する
4. 復旧可能なセーブポイントを作る

### その後

1. AI切り替え時に `AI_HANDOVER.md` を更新する運用を継続する
2. 安全なセーブポイントを確保した後、通常の開発・機能拡張へ戻る

## 8. 次のAIが最初にすること
次のAIは、いきなりコードを変更しない。

1. `AI_HANDOVER.md` を読む
2. `AI_GUIDE.md` / `AI_PROJECT_MANAGER.md` / `CURRENT_STATUS.md` を確認する
3. 現在のコードの状態（`ProjectChase_ClaudeRecovery`）を確認する
4. GitHub / バックアップ状態を確認する
5. 作業目的と変更範囲を明確にする
6. 不明点があれば推測せず、ユーザーへ確認する
7. 必要なら変更案を先に提示し、承認を得てから変更する

## 9. 次のAIがやってはいけないこと

- 既存仕様を勝手に変更しない
- 指示された作業範囲を超えて変更しない
- 大幅なコード変更を一度に行わない
- 不明点を推測して実装しない
- 作業途中のコードを「完成版」と判断しない
- 正常動作確認済みの状態を、バックアップなしで上書きしない
- リファクタリングを理由にゲームの挙動・ルール・UIを変更しない

## 10. 変更時の安全ルール
Plaintext

```
① 現在の正常状態を確認
        ↓
② バックアップ / Gitコミットを確認
        ↓
③ 変更対象ファイルを確認
        ↓
④ 変更内容と目的を明確化
        ↓
⑤ 必要ならユーザー承認
        ↓
⑥ コード変更
        ↓
⑦ 動作確認
        ↓
⑧ 結果を記録
        ↓
⑨ AI_HANDOVER.mdを更新
```

## 11. 既存ドキュメントとの役割分担

- ゲーム仕様 → `SPECIFICATION.md`
- プロジェクト全体の状態 → `CURRENT_STATUS.md`
- 決定事項 → `DECISIONS.md`
- 作業履歴 → `DEVLOG.md`
- 変更履歴 → `CHANGELOG.md`
- タスク → `TASKS.md`
- 長期計画 → `ROADMAP.md`
- AIへの基本ガイド → `AI_GUIDE.md`
- AIによるプロジェクト管理方針 → `AI_PROJECT_MANAGER.md`
- **直前の作業状態・AI交代時の引き継ぎ → `AI_HANDOVER.md`**
