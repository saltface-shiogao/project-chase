import 'package:flutter/material.dart';

import '../models/app_theme.dart';

/// 遊び方（ルール説明）画面。
///
/// タイトル画面（title_view.dart）の「遊び方を見る」から開く、
/// 参照用の読み物画面。GamePhase（ゲームの進行状態）には含めず、
/// Navigator.pushで独立した画面として開く設計にしている
/// （ルール確認は「ゲームの進行」ではなく「参照」なので、
/// 状態遷移の仕組みに組み込む必要がないため）。
///
/// 見た目はタイトル画面のネオン夜景トーンではなく、盤面と同じ
/// クラフト紙調（AppTheme.boardGame()）にしている。文章の読みやすさを
/// 優先したため。
///
/// 内容は下書き。実際のゲームロジック（移動・捜索・勝敗判定）を確認した
/// うえで簡易的にまとめたもので、後ほど修正される前提。
class HowToPlayView extends StatelessWidget {
  const HowToPlayView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.boardGame();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('遊び方'),
        backgroundColor: theme.appBarBackground,
        foregroundColor: theme.appBarForeground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              theme: theme,
              title: 'ゲームの目的',
              body:
                  'シティチェイスは、街に隠れた「犯人」を「警察」が捜し出す、'
                  '鬼ごっこ×かくれんぼのゲームです。\n\n'
                  '・警察役：3機のヘリコプターで街を捜索し、11ラウンド以内に'
                  '犯人を見つけ出す\n'
                  '・犯人役：ビルからビルへ移動しながら、11ラウンドの間'
                  '逃げ切る',
            ),
            _Section(
              theme: theme,
              title: '盤面',
              body:
                  '・5×5のビルが並ぶ街が舞台です\n'
                  '・ビルとビルの間の交差点（4×4マス）に、警察のヘリコプター'
                  '3機が配置されます',
            ),
            _Section(
              theme: theme,
              title: 'ゲームの流れ',
              body:
                  '1. 準備：警察はヘリ3機の初期位置を、犯人は隠れるビルを'
                  '選びます（お互いに見えません）\n'
                  '2. 各ラウンドで、警察は3機のヘリをそれぞれ1回ずつ行動させ、'
                  'そのあとに犯人が1回移動します\n'
                  '3. これを11ラウンド繰り返します',
            ),
            _Section(
              theme: theme,
              title: '警察の行動（ヘリ1機につき1回）',
              body:
                  '・移動：隣接する交差点（上下左右）へ1マス移動する\n'
                  '・捜索：今いる交差点の周囲4棟のビルのうち1棟を選んで'
                  '捜索する\n\n'
                  '捜索の結果：\n'
                  '　- 犯人がそこにいれば、逮捕成功で警察の勝利\n'
                  '　- 犯人が過去にそこを通っていれば「痕跡」が見つかる'
                  '（何ラウンド前に通過したかが分かります）\n'
                  '　- 何もなければ空振り',
            ),
            _Section(
              theme: theme,
              title: '犯人の行動（1ラウンドに1回）',
              body:
                  '・隣接するビル（上下左右）のうち、まだ一度も訪れていない'
                  'ビルへ1棟だけ移動します\n'
                  '・一度訪れたビルには二度と戻れません\n'
                  '・移動できるビルが1つもなくなると、その時点で包囲され、'
                  '警察の勝利になります',
            ),
            _Section(
              theme: theme,
              title: '勝敗',
              body:
                  '・警察の勝利：犯人のいるビルを捜索で発見する、または'
                  '犯人を身動きできない状態に追い込む\n'
                  '・犯人の勝利：11ラウンドの間、発見されずに逃げ切る',
            ),
            _Section(
              theme: theme,
              title: 'ゲームモード',
              body:
                  '・1人プレイ：警察役または犯人役を選び、AIと対戦します'
                  '（AI難易度：やさしい／ふつう／むずかしい）\n'
                  '・2人対戦：同じ端末を交互に手渡しながら対戦します'
                  '（相手に見えてはいけない情報は、受け渡し画面で'
                  '一時的に隠されます）',
            ),
            const SizedBox(height: 8),
            Text(
              '※このページは下書きです。内容は今後修正される予定です。',
              style: TextStyle(
                fontSize: 12,
                color: theme.inkColor.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final AppTheme theme;
  final String title;
  final String body;

  const _Section({required this.theme, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 20,
                color: theme.pendingSearchColor,
                margin: const EdgeInsets.only(right: 8),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.appBarBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: theme.inkColor,
            ),
          ),
        ],
      ),
    );
  }
}
