import 'package:flutter/material.dart';

/// アプリ全体の見た目（配色・盤面デザイン）をまとめたテーマ定義。
///
/// 現時点では「ボードゲーム風（原作に近い）」テーマのみを実装しているが、
/// 将来的に設定画面から複数テーマを切り替えられるようにすることを見据え、
/// 色やアイコンなどの「見た目の値」をこのクラスに集約している。
/// ゲームロジック（判定・状態管理）とは完全に分離しており、
/// views/ 側はこのクラスの値を参照するだけで、分岐処理は一切変更しない。
class AppTheme {
  final String name;

  // ---- 全体（AppBar・背景など） ----
  final Color appBarBackground;
  final Color appBarForeground;
  final Color scaffoldBackground;

  // ---- 盤面 ----
  final Color boardBackground; // 盤面のベース（クラフト紙）
  final Color gridLine; // 道路・グリッド線（インク）
  final Color buildingColor; // 通常のビル（木目調）
  final Color buildingHighlight; // ビルのベベル：ハイライト側
  final Color buildingShadow; // ビルのベベル：シャドウ側
  final Color searchedBuildingColor; // 捜索済みビル
  final Color searchableZoneColor; // 警察の捜索可能範囲
  final Color pendingSearchColor; // 確定待ちの捜索候補
  final Color moveCandidateColor; // 犯人の移動候補
  final Color deadEndWarningColor; // 包囲事前警告（3-7）
  final Color carColor; // 車（犯人）のマーカー色
  final Color traceAccentColor; // 痕跡・警告のアクセント色（金具・ニス）
  final Color inkColor; // 文字・アイコンの基本色

  const AppTheme({
    required this.name,
    required this.appBarBackground,
    required this.appBarForeground,
    required this.scaffoldBackground,
    required this.boardBackground,
    required this.gridLine,
    required this.buildingColor,
    required this.buildingHighlight,
    required this.buildingShadow,
    required this.searchedBuildingColor,
    required this.searchableZoneColor,
    required this.pendingSearchColor,
    required this.moveCandidateColor,
    required this.deadEndWarningColor,
    required this.carColor,
    required this.traceAccentColor,
    required this.inkColor,
  });

  /// 「ボードゲーム風（原作に近い）」テーマ。
  /// クラフト紙・木目・印刷インクを思わせる、渋めのパレット。
  factory AppTheme.boardGame() {
    return const AppTheme(
      name: 'ボードゲーム風',
      appBarBackground: Color(0xFF2B3A55), // インクネイビー
      appBarForeground: Color(0xFFE8DCC3), // 生成り
      scaffoldBackground: Color(0xFFE8DCC3), // 生成り（クラフト紙）
      boardBackground: Color(0xFFE8DCC3),
      gridLine: Color(0xFF2B3A55), // インクネイビー
      buildingColor: Color(0xFF8A7A64), // 木目調ブラウン
      buildingHighlight: Color(0xFFA9998A),
      buildingShadow: Color(0xFF5C4F3F),
      searchedBuildingColor: Color(0xFFBEB29B), // 捜索済み＝色が抜けた紙
      searchableZoneColor: Color(0xFFB5533C), // 赤茶（朱色）
      pendingSearchColor: Color(0xFFC9A227), // マスタードゴールド
      moveCandidateColor: Color(0xFF6B7A4F), // モスグリーン
      deadEndWarningColor: Color(0xFFB5533C), // 赤茶（警告）
      carColor: Color(0xFFC9A227), // マスタードゴールド
      traceAccentColor: Color(0xFFC9A227),
      inkColor: Color(0xFF1F1B16), // ほぼ黒の焦げ茶
    );
  }
}
