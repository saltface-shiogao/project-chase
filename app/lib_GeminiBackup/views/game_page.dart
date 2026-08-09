import 'package:flutter/material.dart';
import '../models/helicopter.dart';
import '../models/player_role.dart';
import '../views/board_widget.dart';

class GamePage extends StatefulWidget {
  final PlayerRole playerRole;
  final VoidCallback onResetRole;

  const GamePage({
    super.key,
    required this.playerRole,
    required this.onResetRole,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const int maxTurns = 10;
  int currentTurn = 1;
  bool isGameOver = false;
  String gameResultMessage = '';

  List<Helicopter> helicopters = [];
  Helicopter? selectedHelicopter;
  List<List<int>> searchedBuildings = [];

  int criminalX = 2;
  int criminalY = 2;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    setState(() {
      currentTurn = 1;
      isGameOver = false;
      gameResultMessage = '';
      searchedBuildings.clear();

      helicopters = [
        Helicopter(id: 1, x: 0, y: 0),
        Helicopter(id: 2, x: 3, y: 0),
      ];
      selectedHelicopter = null;

      criminalX = 2;
      criminalY = 2;
    });
  }

  void _onSelectHelicopter(Helicopter helicopter) {
    if (widget.playerRole != PlayerRole.police || isGameOver) return;
    setState(() {
      selectedHelicopter = helicopter;
    });
  }

  void _onMoveHelicopter(int newX, int newY) {
    if (selectedHelicopter == null || isGameOver) return;

    setState(() {
      selectedHelicopter!.x = newX;
      selectedHelicopter!.y = newY;
      selectedHelicopter = null;

      _processTurnEnd();
    });
  }

  void _onMoveCriminal(int newX, int newY) {
    if (widget.playerRole != PlayerRole.criminal || isGameOver) return;

    setState(() {
      criminalX = newX;
      criminalY = newY;

      // 警察ヘリの簡易AI移動（犯人の位置へ近づく）
      _movePoliceAi();
      _processTurnEnd();
    });
  }

  void _movePoliceAi() {
    for (var h in helicopters) {
      if (h.x < criminalX) {
        h.x++;
      } else if (h.x > criminalX) {
        h.x--;
      } else if (h.y < criminalY) {
        h.y++;
      } else if (h.y > criminalY) {
        h.y--;
      }
    }
  }

  void _moveCriminalAi() {
    // 犯人AIの簡易移動（警察ヘリから離れるマスを選択）
    final directions = [
      [0, -1], [0, 1], [-1, 0], [1, 0]
    ];
    int bestX = criminalX;
    int bestY = criminalY;
    double maxDist = -1;

    for (var d in directions) {
      int nx = criminalX + d[0];
      int ny = criminalY + d[1];
      if (nx >= 0 && nx < 5 && ny >= 0 && ny < 5) {
        double minDistToHeli = 999;
        for (var h in helicopters) {
          double dist = ((h.x - nx).abs() + (h.y - ny).abs()).toDouble();
          if (dist < minDistToHeli) minDistToHeli = dist;
        }
        if (minDistToHeli > maxDist) {
          maxDist = minDistToHeli;
          bestX = nx;
          bestY = ny;
        }
      }
    }
    criminalX = bestX;
    criminalY = bestY;
  }

  void _processTurnEnd() {
    // 勝利判定
    for (var h in helicopters) {
      if (h.x == criminalX && h.y == criminalY) {
        isGameOver = true;
        gameResultMessage = widget.playerRole == PlayerRole.police
            ? '警察の勝利！ 犯人を追い詰めました！'
            : '犯人の敗北... 警察に捕まりました。';
        return;
      }
    }

    if (currentTurn >= maxTurns) {
      isGameOver = true;
      gameResultMessage = widget.playerRole == PlayerRole.criminal
          ? '犯人の勝利！ 逃走に成功しました！'
          : '警察の敗北... 逃走を許しました。';
      return;
    }

    currentTurn++;

    if (widget.playerRole == PlayerRole.police) {
      _moveCriminalAi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('City Chase - ターン $currentTurn / $maxTurns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initGame,
            tooltip: 'ゲームリセット',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: widget.onResetRole,
            tooltip: '役割変更',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.playerRole == PlayerRole.police
                  ? '【警察プレイ】ヘリを選択して動かし、犯人を追い詰めてください'
                  : '【犯人プレイ】緑枠のマスへ移動し、10ターン逃げ切ってください',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Center(
              child: BoardWidget(
                helicopters: helicopters,
                selectedHelicopter: selectedHelicopter,
                searchedBuildings: searchedBuildings,
                criminalX: criminalX,
                criminalY: criminalY,
                playerRole: widget.playerRole,
                isGameOver: isGameOver,
                onSelectHelicopter: _onSelectHelicopter,
                onMoveHelicopter: _onMoveHelicopter,
                onMoveCriminal: _onMoveCriminal,
              ),
            ),
          ),
          if (isGameOver)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withValues(alpha: 0.8),
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    gameResultMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _initGame,
                    child: const Text('もう一度遊ぶ'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}