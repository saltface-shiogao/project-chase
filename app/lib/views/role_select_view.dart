import 'package:flutter/material.dart';

import '../models/player_role.dart';

/// 役割選択画面（警察役 / 犯人役）
///
/// isTwoPlayerMode はローカル2人対戦モード用に追加したオプション引数。
/// 省略時（false）は、これまでと完全に同じ表示・動作になる
/// （1人プレイ側の既存の呼び出し方 RoleSelectView(onSelectRole: ...) は
/// 一切変更する必要がなく、そのままの見た目・挙動で動く）。
/// true の場合のみ、AIが相手を務める前提の文言を、2人の人間が
/// それぞれの役を担当する前提の文言に出し分ける。
/// onSelectRole のコールバック自体（呼ばれ方・渡す値）は変更していない。
class RoleSelectView extends StatelessWidget {
  final void Function(PlayerRole role) onSelectRole;
  final bool isTwoPlayerMode;

  const RoleSelectView({
    super.key,
    required this.onSelectRole,
    this.isTwoPlayerMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final String policeLabel = isTwoPlayerMode
        ? '警察役でプレイ（あなたが警察、もう一人が犯人）'
        : '警察役でプレイ（AIが犯人）';
    final String criminalLabel = isTwoPlayerMode
        ? '犯人役でプレイ（あなたが犯人、もう一人が警察）'
        : '犯人役でプレイ（AIが警察）';

    return Scaffold(
      appBar: AppBar(
        title: const Text('シティチェイス'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '役割を選んでください',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => onSelectRole(PlayerRole.police),
                icon: const Icon(Icons.local_police),
                label: Text(policeLabel),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => onSelectRole(PlayerRole.criminal),
                icon: const Icon(Icons.directions_car),
                label: Text(criminalLabel),
                style: ElevatedButton.styleFrom(
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
