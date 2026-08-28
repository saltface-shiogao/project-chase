import 'dart:math';
import 'package:flutter/material.dart';

import 'how_to_play_view.dart';

/// タイトル画面（アプリ起動直後、最初に表示される画面）。
///
/// 実物のボードゲーム「シティチェイス」の箱の雰囲気（ネオン夜景っぽい配色）と、
/// 参考画像「4 GATE」（バックライトのビル＋放射状の光）を参考にしているが、
/// 実物のイラスト素材は一切使用せず、グラデーション・発光表現のみで
/// オリジナルに再構成している。
///
/// ゲーム中の盤面（AppTheme.boardGame()のクラフト紙調・明るい配色）とは
/// あえてトーンを変えており、「箱の表紙は華やか、中身は落ち着いた盤面」
/// という対比を意図したデザイン（HTMLモックアップで方向性をすり合わせ済み）。
///
/// 配置はCSSモックアップのような絶対座標ではなく、Flutterの通常のColumnで
/// 上から順に積むだけの構成にしている。これにより「光の演出とタイトル文字が
/// 重なる」といった問題が構造的に起こらないようにしている
/// （モックアップ側で絶対座標の数値調整に苦労した反省を踏まえた設計）。
class TitleView extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback? onHowToPlay;

  const TitleView({super.key, required this.onStart, this.onHowToPlay});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.25, 0.45, 0.68, 0.85, 1.0],
            colors: [
              Color(0xFF3A1F63),
              Color(0xFF5A2969),
              Color(0xFF7D3268),
              Color(0xFFA8433F),
              Color(0xFFD97239),
              Color(0xFFF0A24E),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTitles(),
                _buildSkylineWithRays(),
                _buildCta(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitles() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'CITY CHASE',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Color(0xFFC9A227),
                offset: Offset(0, 2),
              ),
              Shadow(
                color: Color(0x66140F1D),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'シティチェイス',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: Color(0xFFC9A227),
          ),
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: 0.85,
          child: Text(
            '鬼ごっこ×かくれんぼ、これは頭脳戦。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.0,
              color: const Color(0xFFF4EFE1),
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ビルのシルエット＋その背後の放射状の光。
  // 光はこの固定高さのボックスの中だけで完結しており、Column内の
  // 他の要素（タイトル文字・ボタン）に重なることは構造上あり得ない。
  Widget _buildSkylineWithRays() {
    return SizedBox(
      height: 130,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: ClipRect(child: CustomPaint(painter: _RaysPainter())),
          ),
          _buildSkyline(),
        ],
      ),
    );
  }

  Widget _buildSkyline() {
    const heights = [40.0, 65.0, 30.0, 80.0, 50.0, 70.0, 35.0, 60.0, 45.0];
    const windowCounts = [1, 2, 0, 3, 1, 2, 0, 2, 1];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(heights.length, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: _Building(height: heights[i], windowCount: windowCounts[i]),
        );
      }),
    );
  }

  Widget _buildCta(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onStart,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD2603F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 6,
            shadowColor: const Color(0xFF7A2E20),
          ),
          child: const Text(
            'ゲームを始める',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onHowToPlay ?? () => _openHowToPlay(context),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFF0E6D2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          child: const Text(
            '遊び方を見る',
            style: TextStyle(fontSize: 13, decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  void _openHowToPlay(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HowToPlayView()),
    );
  }
}

class _Building extends StatelessWidget {
  final double height;
  final int windowCount;

  const _Building({required this.height, required this.windowCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F42),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC882).withOpacity(0.55),
            blurRadius: 14,
            spreadRadius: -2,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: windowCount > 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Wrap(
                spacing: 3,
                runSpacing: 4,
                children: List.generate(
                  windowCount,
                  (_) => Container(
                    width: 4,
                    height: 6,
                    color: const Color(0xFFFFCF7A),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// 下端中央を光源にした、扇形に広がる光の帯を描く。
// HTMLモックアップのrepeating-conic-gradientと同じ考え方
// （角度10度の光の帯を22度おきに繰り返す）をCanvas描画で再現している。
class _RaysPainter extends CustomPainter {
  const _RaysPainter();

  static const double _startDeg = 180;
  static const double _sweepRangeDeg = 180;
  static const double _wedgeDeg = 10;
  static const double _periodDeg = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset origin = Offset(size.width / 2, size.height);
    final double maxRadius = size.height * 2.2 + size.width / 2;
    final Paint paint = Paint()
      ..color = const Color(0xFFFFDCAF).withOpacity(0.32);

    for (double a = _startDeg; a < _startDeg + _sweepRangeDeg; a += _periodDeg) {
      final double startRad = a * pi / 180;
      final double sweepRad = _wedgeDeg * pi / 180;
      final Path path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..arcTo(
          Rect.fromCircle(center: origin, radius: maxRadius),
          startRad,
          sweepRad,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter oldDelegate) => false;
}
