import 'package:flutter/material.dart';

import '../models/player_role.dart';

/// 役割選択画面（警察役 / 犯人役）
class RoleSelectView extends StatelessWidget {
  final void Function(PlayerRole role) onSelectRole;

  const RoleSelectView({super.key, required this.onSelectRole});

  @override
  Widget build(BuildContext context) {
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
              const Text('役割を選んでください', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => onSelectRole(PlayerRole.police),
                icon: const Icon(Icons.local_police),
                label: const Text('警察役でプレイ（AIが犯人）'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => onSelectRole(PlayerRole.criminal),
                icon: const Icon(Icons.directions_car),
                label: const Text('犯人役でプレイ（AIが警察）'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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
