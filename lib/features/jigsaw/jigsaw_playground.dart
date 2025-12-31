import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'jigsaw_engine.dart';
import 'jigsaw_piece.dart';
import '../../core/widgets/fireworks_painter.dart';

class JigsawPlayground extends StatelessWidget {
  final File imageFile;
  final int piecesCount;
  final bool isEasyMode;
  final JigsawPieceType pieceType;

  const JigsawPlayground({
    super.key,
    required this.imageFile,
    required this.piecesCount,
    this.isEasyMode = true,
    this.pieceType = JigsawPieceType.traditional,
  });

  @override
  Widget build(BuildContext context) {
    // Basic square grid logic for piecesCount (approximate)
    int cols = sqrt(piecesCount).floor();
    int rows = (piecesCount / cols).ceil();

    return ChangeNotifierProvider(
      create: (_) => JigsawEngine(
        imageProvider: FileImage(imageFile),
        gridRows: rows,
        gridCols: cols,
        isEasyMode: isEasyMode,
        pieceType: pieceType,
      ),
      child: const Scaffold(body: _JigsawBody()),
    );
  }
}

class _JigsawBody extends StatefulWidget {
  const _JigsawBody();

  @override
  State<_JigsawBody> createState() => _JigsawBodyState();
}

class _JigsawBodyState extends State<_JigsawBody> {
  Size? _lastSize;

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<JigsawEngine>(context);

    if (engine.isComplete) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Puzzle Complete! 🏆', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Menu'),
            ),
          ],
        ),
      );
    }

    if (engine.isImageLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the best fit for the image while maintaining aspect ratio
        // Leave room for pieces scattered around (0.7 scale for the puzzle board)
        final double trayScale = 0.75;
        final double imageWidth = engine.resolvedImage!.width.toDouble();
        final double imageHeight = engine.resolvedImage!.height.toDouble();
        final double aspectRatio = imageWidth / imageHeight;

        double boxWidth, boxHeight;
        if (constraints.maxWidth / constraints.maxHeight > aspectRatio) {
          boxHeight = constraints.maxHeight * trayScale;
          boxWidth = boxHeight * aspectRatio;
        } else {
          boxWidth = constraints.maxWidth * trayScale;
          boxHeight = boxWidth / aspectRatio;
        }

        final Offset centerOffset = Offset(
          (constraints.maxWidth - boxWidth) / 2,
          (constraints.maxHeight - boxHeight) / 2,
        );

        // Check if orientation/size changed to clamp pieces
        final Size currentSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        if (_lastSize != currentSize) {
          _lastSize = currentSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final double minX = -centerOffset.dx / boxWidth;
            final double maxX =
                (currentSize.width - centerOffset.dx) / boxWidth - 0.1;
            final double minY = -centerOffset.dy / boxHeight;
            final double maxY =
                (currentSize.height - centerOffset.dy) / boxHeight - 0.1;

            engine.clampAllPieces(
              minX: minX,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
            );
          });
        }

        return Stack(
          children: [
            // Normal mode: Side preview
            if (!engine.isEasyMode && !engine.isComplete)
              Positioned(
                left: 16,
                top: 16,
                child: Container(
                  width: 120,
                  height: 120 / aspectRatio,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: RawImage(
                    image: engine.resolvedImage,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            // Target area (hints in Easy mode, empty board in Normal mode)
            Positioned(
              left: centerOffset.dx,
              top: centerOffset.dy,
              child: Opacity(
                opacity: engine.isEasyMode ? 0.2 : 1.0,
                child: Container(
                  width: boxWidth,
                  height: boxHeight,
                  decoration: BoxDecoration(
                    color: engine.isEasyMode
                        ? null
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.05),
                    border: engine.isEasyMode
                        ? null
                        : Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                          ),
                  ),
                  child: engine.isEasyMode
                      ? RawImage(image: engine.resolvedImage!, fit: BoxFit.fill)
                      : null,
                ),
              ),
            ),

            // The Puzzle Pieces
            // 1. Placed pieces at the bottom
            ...engine.pieces
                .where((p) => p.isPlaced)
                .map(
                  (piece) => _DraggablePiece(
                    key: ValueKey(piece.id),
                    piece: piece,
                    boxSize: Size(boxWidth, boxHeight),
                    boxOffset: centerOffset,
                    screenConstraints: Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ),
                  ),
                ),
            // 2. Unplaced pieces on top
            ...engine.pieces
                .where((p) => !p.isPlaced)
                .map(
                  (piece) => _DraggablePiece(
                    key: ValueKey(piece.id),
                    piece: piece,
                    boxSize: Size(boxWidth, boxHeight),
                    boxOffset: centerOffset,
                    screenConstraints: Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ),
                  ),
                ),

            // Snap Fireworks
            if (engine.lastSnapOffset != null)
              Positioned(
                left:
                    centerOffset.dx +
                    (engine.lastSnapOffset!.dx * boxWidth) -
                    75,
                top:
                    centerOffset.dy +
                    (engine.lastSnapOffset!.dy * boxHeight) -
                    75,
                child: FireworksWidget(
                  key: ValueKey(
                    'snap_${engine.lastSnapOffset}_${engine.pieces.where((p) => p.isPlaced).length}',
                  ),
                  triggerPosition: const Offset(75, 75),
                  onFinished: engine.clearLastSnap,
                ),
              ),

            // Final Completed Image (Fades in)
            if (engine.isComplete)
              Positioned(
                left: centerOffset.dx,
                top: centerOffset.dy,
                width: boxWidth,
                height: boxHeight,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 5000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: RawImage(
                        image: engine.resolvedImage!,
                        fit: BoxFit.fill,
                      ),
                    );
                  },
                ),
              ),

            // Completion Success UI (Fades in secondary)
            if (engine.isComplete)
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
                                const SizedBox(height: 48),
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

class _DraggablePiece extends StatefulWidget {
  final JigsawPiece piece;
  final Size boxSize;
  final Offset boxOffset;
  final Size screenConstraints;

  const _DraggablePiece({
    super.key,
    required this.piece,
    required this.boxSize,
    required this.boxOffset,
    required this.screenConstraints,
  });

  @override
  State<_DraggablePiece> createState() => _DraggablePieceState();
}

class _DraggablePieceState extends State<_DraggablePiece> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<JigsawEngine>(context);
    final double pieceWidth = widget.boxSize.width / engine.gridCols;
    final double pieceHeight = widget.boxSize.height / engine.gridRows;

    // Use tab expansion (0.2) to match painter
    final double tabScale = 0.2;
    final double paddingW = pieceWidth * tabScale;
    final double paddingH = pieceHeight * tabScale;

    return Positioned(
      left:
          widget.boxOffset.dx +
          (widget.piece.currentX * widget.boxSize.width) -
          paddingW,
      top:
          widget.boxOffset.dy +
          (widget.piece.currentY * widget.boxSize.height) -
          paddingH,
      child: GestureDetector(
        onPanStart: widget.piece.isPlaced
            ? null
            : (_) {
                engine.bringPieceToFront(widget.piece);
                setState(() => _isDragging = true);
              },
        onPanUpdate: widget.piece.isPlaced
            ? null
            : (details) {
                final dx = details.delta.dx / widget.boxSize.width;
                final dy = details.delta.dy / widget.boxSize.height;

                double nextX = widget.piece.currentX + dx;
                double nextY = widget.piece.currentY + dy;

                // Clamp to screen bounds
                // Piece pivot is top-left of the piece square.
                // We want to keep at least a bit of the piece on screen.
                final double minX = -widget.boxOffset.dx / widget.boxSize.width;
                final double maxX =
                    (widget.screenConstraints.width - widget.boxOffset.dx) /
                        widget.boxSize.width -
                    0.1;
                final double minY =
                    -widget.boxOffset.dy / widget.boxSize.height;
                final double maxY =
                    (widget.screenConstraints.height - widget.boxOffset.dy) /
                        widget.boxSize.height -
                    0.1;

                engine.updatePiecePosition(
                  widget.piece,
                  nextX.clamp(minX, maxX),
                  nextY.clamp(minY, maxY),
                );
              },
        onPanEnd: widget.piece.isPlaced
            ? null
            : (_) {
                setState(() => _isDragging = false);
                engine.trySnapPiece(widget.piece);
              },
        child: SizedBox(
          width: pieceWidth + (paddingW * 2),
          height: pieceHeight + (paddingH * 2),
          child: CustomPaint(
            painter: _PiecePainter(
              resolvedImage: engine.resolvedImage!,
              piece: widget.piece,
              gridRows: engine.gridRows,
              gridCols: engine.gridCols,
              isDragging: _isDragging,
            ),
          ),
        ),
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  final ui.Image resolvedImage;
  final JigsawPiece piece;
  final int gridRows;
  final int gridCols;
  final bool isDragging;

  _PiecePainter({
    required this.resolvedImage,
    required this.piece,
    required this.gridRows,
    required this.gridCols,
    this.isDragging = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = _getPiecePath(size);

    final double tabScale = 0.2;
    final double pieceWidth = size.width / (1 + 2 * tabScale);
    final double pieceHeight = size.height / (1 + 2 * tabScale);

    // Calculate image slice coordinates
    final double imgPieceW = resolvedImage.width / gridCols;
    final double imgPieceH = resolvedImage.height / gridRows;
    final double imgSrcX = piece.correctX * imgPieceW;
    final double imgSrcY = piece.correctY * imgPieceH;

    // The expansion in image pixels
    final double imgPaddingW = imgPieceW * tabScale;
    final double imgPaddingH = imgPieceH * tabScale;

    // We want to map:
    // (imgSrcX - imgPaddingW, imgSrcY - imgPaddingH) in image space
    // to (0, 0) in canvas space.
    // And scale image pixels to canvas pixels.
    final double scaleX = pieceWidth / imgPieceW;
    final double scaleY = pieceHeight / imgPieceH;

    final Matrix4 matrix = Matrix4.identity()
      ..scale(scaleX, scaleY, 1.0)
      ..translate(-(imgSrcX - imgPaddingW), -(imgSrcY - imgPaddingH));

    final Paint shaderPaint = Paint()
      ..shader = ui.ImageShader(
        resolvedImage,
        ui.TileMode.clamp,
        ui.TileMode.clamp,
        matrix.storage,
      )
      ..filterQuality = ui.FilterQuality.high
      ..isAntiAlias = true;

    canvas.drawPath(path, shaderPaint);

    // No restore needed as we didn't save/clip
    // canvas.restore(); (removed)

    // Draw piece border (only if not placed)
    if (!piece.isPlaced) {
      final Paint borderPaint = Paint()
        ..color = isDragging ? Colors.cyanAccent : Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = isDragging ? 3.0 : 1.0;
      canvas.drawPath(path, borderPaint);
    }

    // Add subtle shadow if dragging
    if (isDragging) {
      canvas.drawShadow(path, Colors.black, 4, true);
    }
  }

  Path _getPiecePath(Size size) {
    final double tabScale = 0.2;
    // The size passed here is the total widget size, so base size is smaller
    final double baseWidth = size.width / (1 + 2 * tabScale);
    final double baseHeight = size.height / (1 + 2 * tabScale);
    final double paddingW = baseWidth * tabScale;
    final double paddingH = baseHeight * tabScale;

    final double tabWidth = baseWidth * tabScale;
    final double tabHeight = baseHeight * tabScale;

    final Path path = Path();
    path.moveTo(paddingW, paddingH);

    // Top
    if (piece.top == 0) {
      path.lineTo(paddingW + baseWidth, paddingH);
    } else {
      _drawTab(
        path,
        Offset(paddingW, paddingH),
        Offset(paddingW + baseWidth, paddingH),
        piece.top,
        tabWidth,
        tabHeight,
        true,
      );
    }

    // Right
    if (piece.right == 0) {
      path.lineTo(paddingW + baseWidth, paddingH + baseHeight);
    } else {
      _drawTab(
        path,
        Offset(paddingW + baseWidth, paddingH),
        Offset(paddingW + baseWidth, paddingH + baseHeight),
        piece.right,
        tabWidth,
        tabHeight,
        false,
      );
    }

    // Bottom
    if (piece.bottom == 0) {
      path.lineTo(paddingW, paddingH + baseHeight);
    } else {
      _drawTab(
        path,
        Offset(paddingW + baseWidth, paddingH + baseHeight),
        Offset(paddingW, paddingH + baseHeight),
        piece.bottom,
        tabWidth,
        tabHeight,
        true,
      );
    }

    // Left
    if (piece.left == 0) {
      path.close();
    } else {
      _drawTab(
        path,
        Offset(paddingW, paddingH + baseHeight),
        Offset(paddingW, paddingH),
        piece.left,
        tabWidth,
        tabHeight,
        false,
      );
      path.close();
    }

    return path;
  }

  void _drawTab(
    Path path,
    Offset start,
    Offset end,
    int type,
    double tabW,
    double tabH,
    bool horizontal,
  ) {
    final double dir = type.toDouble();
    if (horizontal) {
      final double width = (end.dx - start.dx).abs();
      final double sign = (end.dx > start.dx) ? 1.0 : -1.0;

      if (piece.pieceType == JigsawPieceType.traditional) {
        // Points for a smooth bulbous jigsaw tab (Classical Bulbous)
        path.cubicTo(
          start.dx + width * 0.35 * sign,
          start.dy,
          start.dx + width * 0.3 * sign,
          start.dy - tabH * 0.8 * dir,
          start.dx + width * 0.5 * sign - tabW * 0.4 * sign,
          start.dy - tabH * 0.85 * dir,
        );
        path.cubicTo(
          start.dx + width * 0.5 * sign - tabW * 1.2 * sign,
          start.dy - tabH * 1.5 * dir,
          start.dx + width * 0.5 * sign + tabW * 1.2 * sign,
          start.dy - tabH * 1.5 * dir,
          start.dx + width * 0.5 * sign + tabW * 0.4 * sign,
          start.dy - tabH * 0.85 * dir,
        );
        path.cubicTo(
          start.dx + width * 0.7 * sign,
          start.dy - tabH * 0.8 * dir,
          start.dx + width * 0.65 * sign,
          start.dy,
          end.dx,
          end.dy,
        );
      } else {
        // Points for an entirely rounded, pill-shaped tab (Modern Rounded)
        final double midX = start.dx + width * 0.5 * sign;
        path.cubicTo(
          start.dx + width * 0.25 * sign,
          start.dy,
          midX - tabW * 0.8 * sign,
          start.dy - tabH * 1.2 * dir,
          midX,
          start.dy - tabH * 1.2 * dir,
        );
        path.cubicTo(
          midX + tabW * 0.8 * sign,
          start.dy - tabH * 1.2 * dir,
          start.dx + width * 0.75 * sign,
          start.dy,
          end.dx,
          end.dy,
        );
      }
    } else {
      final double height = (end.dy - start.dy).abs();
      final double sign = (end.dy > start.dy) ? 1.0 : -1.0;

      if (piece.pieceType == JigsawPieceType.traditional) {
        path.cubicTo(
          start.dx,
          start.dy + height * 0.35 * sign,
          start.dx + tabW * 0.8 * dir,
          start.dy + height * 0.3 * sign,
          start.dx + tabW * 0.85 * dir,
          start.dy + height * 0.5 * sign - tabH * 0.4 * sign,
        );
        path.cubicTo(
          start.dx + tabW * 1.5 * dir,
          start.dy + height * 0.5 * sign - tabH * 1.2 * sign,
          start.dx + tabW * 1.5 * dir,
          start.dy + height * 0.5 * sign + tabH * 1.2 * sign,
          start.dx + tabW * 0.85 * dir,
          start.dy + height * 0.5 * sign + tabH * 0.4 * sign,
        );
        path.cubicTo(
          start.dx + tabW * 0.8 * dir,
          start.dy + height * 0.7 * sign,
          start.dx,
          start.dy + height * 0.65 * sign,
          end.dx,
          end.dy,
        );
      } else {
        // Modern Rounded for vertical
        final double midY = start.dy + height * 0.5 * sign;
        path.cubicTo(
          start.dx,
          start.dy + height * 0.25 * sign,
          start.dx + tabW * 1.2 * dir,
          midY - tabH * 0.8 * sign,
          start.dx + tabW * 1.2 * dir,
          midY,
        );
        path.cubicTo(
          start.dx + tabW * 1.2 * dir,
          midY + tabH * 0.8 * sign,
          start.dx,
          start.dy + height * 0.75 * sign,
          end.dx,
          end.dy,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PiecePainter oldDelegate) =>
      oldDelegate.isDragging != isDragging || oldDelegate.piece != piece;
}
