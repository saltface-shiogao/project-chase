# AI_HANDOVER.md

> Project ChaseのAI・チャットルーム・担当AIが交代する際に、直前の作業状態から安全に再開するための引き継ぎ専用ファイル。
> 
> このファイルは正式な仕様書ではありません。既存のProject Chaseドキュメントを補完し、「今この瞬間の作業状態」を引き継ぐことを目的とします。

## 1. 引き継ぎ情報

- 最終更新日時：2026-08-10
- 最後に作業したAI：Gemini
- 作業環境：Windows 11 / VS Code / Flutter Web（Chrome）/ Git / Obsidian
- 現在の作業段階：**Project Chase正常動作版のGitHub保存完了・開発再開可能段階**
- 引き継ぎ状態：**正常動作確認済みのClaude分割版をGitHubへコミット・プッシュし、安全なセーブポイントの作成が完了**

## 2. 現在の作業

### 現在取り組んでいるタスク
Project Chaseのコード破綻から復旧し、今後の開発を安全に継続できる運用を整える。  

1. **[完了] PC側Git・Obsidian環境の構築**

  

- スマホとPCで別々に作成されていたGitHubリポジトリ（`01_siogao`）の一本化。
- PCでの `git clone` 実行とディレクトリ構成の修復。
- PCのObsidianコミュニティプラグイン「Obsidian Git」の自動同期設定。
2. **[完了] Project Chase正常動作版の保全とGitHub保存**

- 復旧確認済みのClaudeコード分割版（`ProjectChase_ClaudeRecovery\ProjectChase`）を基準版として、GitHubリポジトリ（`project-Chase`）へコミットおよびプッシュ（保存）完了。
3. **[次タスク] 通常の開発・機能拡張の再開**

- 安全なバックアップが確保されたため、開発タスク（機能追加・UI調整等）を安全に再開する。

### 現在の段階
**`project-Chase` 正常動作確認済み状態のGitHub保存およびセーブポイント作成が完了。安全に次の開発へ進める状態。**

## 3. 直前に行った変更

### Project ChaseコードのGitHub保存

- 動作確認済みのClaudeコード分割版（`ProjectChase_ClaudeRecovery\ProjectChase`）を基準版として確定。
- GitHubの `project-Chase` リモートリポジトリへ最新コードをコミット・プッシュし、復旧可能なセーブポイントを作成完了。

### Obsidian & Git同期環境の修正・設定

- **PC側のGit環境修復**: ユーザーフォルダ直下に作られていた誤った `.git` を削除し、`01_siogao` フォルダへ正常に `git clone` を実施。
- **Obsidian Gitプラグイン設定**: 自動同期（Auto push: 10分、Auto pull: 10分、Pull on startup: ON）を設定完了。

## 4. 現在の状態

### 正常動作を確認済み（基準版として保存完了）
検証環境および保存対象：

Plaintext

```
ProjectChase_ClaudeRecovery\ProjectChase
```

確認済み事項：  

- ゲーム起動
- 5×5盤面
- 犯人／警察の役割選択
- ゲーム全体の正常復元

### PC作業環境の状態

- **Obsidian**: リポジトリ `01_siogao` とPC間で正常にGit同期完了。
- **Project Chase**: GitHubリモートリポジトリ（`project-Chase`）へ正常保存完了。`git status` もクリーンな状態。

## 5. 最後に正常だった状態
現在の基準版：

Plaintext

```
ProjectChase_ClaudeRecovery\ProjectChase
```

**この状態がGitHubへ安全に保存・保全されたため、今後の変更で問題が生じた場合もいつでもこの状態へ復元可能。**

## 6. バックアップ / Git状態

### 現在のステータス

- **Obsidian環境**: GitHub（`01_siogao`）での自動同期・バックアップ運用中。
- **Project Chaseコード**: GitHub（`project-Chase`）への正常動作版保存（コミット＆プッシュ）完了。
- **ローカル復旧用コピー**: `ProjectChase_ClaudeRecovery` 保持済み。

## 7. 次にやること
優先順位：

### 最優先

1. 次に取り組む開発タスク（新規機能追加、UI調整、ルール調整など）の整理
2. 作業着手前の変更目的と変更範囲の明確化
3. 変更を加える際の一度の変更量の最小化とこまめな動作確認

### その後

1. コード変更の区切りごとにGitHubへコミット・プッシュを実施する
2. AI切り替え時に `AI_HANDOVER.md` を最新化する運用を継続する

## 8. 次のAIが最初にすること
次のAIは、いきなりコードを変更しない。  

1. `AI_HANDOVER.md` を読む
2. `AI_GUIDE.md` / `AI_PROJECT_MANAGER.md` / `CURRENT_STATUS.md` を確認する
3. 現在のコードの状態を確認する
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
- 正常動作確認済みの状態を、バックアップなしで直接上書き破壊しない
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
