import 'package:flutter/material.dart';
import 'models/player_role.dart';
import 'views/role_select_view.dart';
import 'views/game_page.dart';

void main() {
  runApp(const CityChaseApp());
}

class CityChaseApp extends StatefulWidget {
  const CityChaseApp({super.key});

  @override
  State<CityChaseApp> createState() => _CityChaseAppState();
}

class _CityChaseAppState extends State<CityChaseApp> {
  PlayerRole? selectedRole;

  void _selectRole(PlayerRole role) {
    setState(() {
      selectedRole = role;
    });
  }

  void _resetRole() {
    setState(() {
      selectedRole = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'City Chase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: selectedRole == null
          ? Scaffold(
              body: RoleSelectView(onRoleSelected: _selectRole),
            )
          : GamePage(
              playerRole: selectedRole!,
              onResetRole: _resetRole,
            ),
    );
  }
}