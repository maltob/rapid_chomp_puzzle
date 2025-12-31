class MemoryCard {
  final int id;
  final String content;
  bool isFaceUp;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.content,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}
