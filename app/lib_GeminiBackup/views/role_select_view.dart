import 'package:flutter/material.dart';
import '../models/player_role.dart';

class RoleSelectView extends StatelessWidget {
  final Function(PlayerRole) onRoleSelected;

  const RoleSelectView({super.key, required this.onRoleSelected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_police, size: 64, color: Colors.indigo),
              const SizedBox(height: 16),
              const Text(
                'City Chase',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              const Text(
                'プレイヤーの役割を選択してください',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.security),
                label: const Text('警察としてプレイ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () => onRoleSelected(PlayerRole.police),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.directions_run),
                label: const Text('犯人としてプレイ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () => onRoleSelected(PlayerRole.criminal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}