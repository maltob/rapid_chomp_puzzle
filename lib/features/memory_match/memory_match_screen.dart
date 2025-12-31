import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'memory_match_engine.dart';
import 'memory_card.dart';
import '../../core/widgets/fireworks_painter.dart';

class MemoryMatchScreen extends StatelessWidget {
  final int numberOfPairs;
  final List<String>? customImagePaths;

  const MemoryMatchScreen({
    super.key,
    this.numberOfPairs = 6,
    this.customImagePaths,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey('${numberOfPairs}_${customImagePaths?.length}'),
      create: (_) =>
          MemoryMatchEngine(numberOfPairs, customImagePaths: customImagePaths),
      child: const Scaffold(body: _MemoryMatchBody()),
    );
  }
}

class _MemoryMatchBody extends StatelessWidget {
  const _MemoryMatchBody();

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<MemoryMatchEngine>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final int totalCards = engine.cards.length;
        int crossAxisCount;

        if (constraints.maxWidth > constraints.maxHeight) {
          crossAxisCount = totalCards > 12 ? 6 : 4;
        } else {
          crossAxisCount = totalCards > 12 ? 4 : 3;
        }

        final int rowCount = (totalCards / crossAxisCount).ceil();
        final double spacing = 12.0;
        final double padding = 16.0;
        final double topReservedSpace =
            80.0; // Space for moves text and buttons

        final double gridWidth = constraints.maxWidth - (padding * 2);
        final double gridHeight =
            constraints.maxHeight - topReservedSpace - padding;

        final double itemWidth =
            (gridWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
        final double itemHeight =
            (gridHeight - (rowCount - 1) * spacing) / rowCount;

        return Stack(
          children: [
            Column(
              children: [
                SizedBox(height: topReservedSpace / 2),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Moves: ${engine.moves}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: padding / 2,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: itemWidth / itemHeight,
                    ),
                    itemCount: totalCards,
                    itemBuilder: (context, index) {
                      return _CardWidget(card: engine.cards[index]);
                    },
                  ),
                ),
              ],
            ),

            // Top Buttons Overlay
            Positioned(
              top: 10,
              left: 10,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: engine.resetGame,
                ),
              ),
            ),

            // Match Fireworks
            if (engine.lastMatchIndices.isNotEmpty)
              ...engine.lastMatchIndices.map((index) {
                final int row = index ~/ crossAxisCount;
                final int col = index % crossAxisCount;

                // Calculate center of the card
                final double x =
                    padding + col * (itemWidth + spacing) + (itemWidth / 2);
                final double y =
                    50 +
                    row * (itemHeight + spacing) +
                    (itemHeight / 2); // 50 is approx Moves text height

                return Positioned(
                  left: x - 75, // Half of FireworksWidget width (150)
                  top: y - 75, // Half of FireworksWidget height (150)
                  child: FireworksWidget(
                    key: ValueKey('match_${index}_${engine.matches}'),
                    triggerPosition: const Offset(
                      75,
                      75,
                    ), // Center of the 150x150 widget
                    onFinished: engine.clearLastMatch,
                  ),
                );
              }),

            // Completion Overlay
            if (engine.isGameOver)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 5000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, opacity, child) {
                    final double textOpacity =
                        (opacity - 0.5).clamp(0.0, 1.0) / 0.5;
                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        color: Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withOpacity(0.9 * opacity),
                        child: Opacity(
                          opacity: textOpacity,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '🎉 You Won!',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Moves: ${engine.moves}',
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 40),
                                ElevatedButton.icon(
                                  onPressed: engine.resetGame,
                                  icon: const Icon(Icons.refresh, size: 28),
                                  label: const Text('Play Again'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 20,
                                    ),
                                    textStyle: const TextStyle(fontSize: 22),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Back to Menu',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CardWidget extends StatelessWidget {
  final MemoryCard card;

  const _CardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<MemoryMatchEngine>(context, listen: false);

    final bool isFront = card.isFaceUp || card.isMatched;

    return GestureDetector(
      onTap: () => engine.onCardTap(card),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        tween: Tween<double>(begin: 0, end: isFront ? 3.14159 : 0),
        builder: (context, angle, child) {
          // Show back if angle < 90 deg, otherwise show front
          final bool showingFront = angle > 3.14159 / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: showingFront
                    ? (card.isMatched
                          ? Colors.greenAccent.withOpacity(0.5)
                          : Theme.of(context).colorScheme.surface)
                    : Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Transform(
                // When showing front, we are rotated 180 deg, so we must un-rotate the child
                transform: Matrix4.identity()
                  ..rotateY(showingFront ? 3.14159 : 0),
                alignment: Alignment.center,
                child: Center(
                  child: showingFront
                      ? (engine.isCustomMode
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(card.content),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : Text(
                                card.content,
                                style: const TextStyle(fontSize: 32),
                              ))
                      : const Text(
                          '?',
                          style: TextStyle(fontSize: 32, color: Colors.white),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
