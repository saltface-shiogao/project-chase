import 'dart:math';
import '../models/helicopter.dart';
import '../models/police_ai_action.dart';

class PoliceAi {
  static PoliceAiAction decideAction({
    required List<Helicopter> helicopters,
    required List<List<int>> searchedBuildings,
  }) {
    Helicopter? searchHeli;
    for (var h in helicopters) {
      if (!h.isSearching &&
          !searchedBuildings.any((b) => b[0] == h.x && b[1] == h.y)) {
        searchHeli = h;
        break;
      }
    }

    if (searchHeli != null) {
      return PoliceAiAction.search(searchHeli);
    }

    Helicopter? moveHeli;
    for (var h in helicopters) {
      if (!h.isSearching) {
        moveHeli = h;
        break;
      }
    }

    if (moveHeli != null) {
      List<List<int>> unsearchedList = [];
      for (int x = 0; x < 5; x++) {
        for (int y = 0; y < 5; y++) {
          if (!searchedBuildings.any((b) => b[0] == x && b[1] == y)) {
            unsearchedList.add([x, y]);
          }
        }
      }

      if (unsearchedList.isNotEmpty) {
        List<int> target = unsearchedList.first;
        double minDist = double.infinity;
        for (var pos in unsearchedList) {
          double dist = sqrt(
              pow(pos[0] - moveHeli.x, 2) + pow(pos[1] - moveHeli.y, 2));
          if (dist < minDist) {
            minDist = dist;
            target = pos;
          }
        }

        int nextX = moveHeli.x;
        int nextY = moveHeli.y;
        if (target[0] > moveHeli.x) nextX++;
        else if (target[0] < moveHeli.x) nextX--;
        else if (target[1] > moveHeli.y) nextY++;
        else if (target[1] < moveHeli.y) nextY--;

        return PoliceAiAction.move(moveHeli, nextX, nextY);
      }
    }

    return PoliceAiAction.stay();
  }
}
