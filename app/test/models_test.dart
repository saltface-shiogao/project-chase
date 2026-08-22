import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/models/player_role.dart';
import 'package:my_first_app/models/game_phase.dart';
import 'package:my_first_app/models/helicopter.dart';
import 'package:my_first_app/models/police_ai_action.dart';
import 'package:my_first_app/ai/criminal_ai.dart';
import 'package:my_first_app/ai/police_ai.dart';

void main() {
  test('Dummy test', () {
    expect(true, isTrue);
  });

  test('PlayerRole and GamePhase enum test', () {
    expect(PlayerRole.police, isNotNull);
    expect(PlayerRole.criminal, isNotNull);
    expect(GamePhase.playing, isNotNull);
  });

  test('Helicopter model test', () {
    final heli = Helicopter(1, 0, 0);
    expect(heli.id, 1);
    expect(heli.row, 0);
    expect(heli.col, 0);
    expect(heli.hasActedThisTurn, isFalse);
  });

  test('PoliceAiAction model test', () {
    final heli = Helicopter(1, 1, 1);
    // PoliceAiAction.search は (targetRow, targetCol) の2引数のみを受け取る
    // （helicopterId というフィールドは存在しないため、ここでは検証しない）
    final action = PoliceAiAction.search(heli.row, heli.col);
    expect(action.type, PoliceActionType.search);
    expect(action.targetRow, heli.row);
    expect(action.targetCol, heli.col);
  });

  test('CriminalAi test', () {
    final grid = List.generate(5, (_) => List.generate(5, (_) => 0));
    final moves = CriminalAi.getValidMoves(grid, 5, 2, 2);
    expect(moves.isNotEmpty, isTrue);

    final move = CriminalAi.decideMove(grid, 5, 2, 2);
    expect(move, isNotNull);
    expect(move?.length, 2);
  });

  test('PoliceAi test', () {
    final helis = [Helicopter(1, 0, 0)];
    final searchedGrid = List.generate(5, (_) => List.filled(5, false));
    final action = PoliceAi.decideAction(helis.first, helis, searchedGrid);
    expect(action, isNotNull);
  });
}
