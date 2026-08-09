class Helicopter {
  int id;
  int x;
  int y;
  bool isSearching;
  bool hasActedThisTurn;

  Helicopter({
    this.id = 1,
    required this.x,
    required this.y,
    this.isSearching = false,
    this.hasActedThisTurn = false,
  });

  // Backward compatibility getters/setters for row/col
  int get row => y;
  set row(int val) => y = val;
  int get col => x;
  set col(int val) => x = val;
}

