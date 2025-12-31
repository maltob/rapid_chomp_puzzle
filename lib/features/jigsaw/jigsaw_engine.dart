import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'jigsaw_piece.dart';

class JigsawEngine extends ChangeNotifier {
  final ImageProvider imageProvider;
  final int gridRows;
  final int gridCols;
  final bool isEasyMode;
  final JigsawPieceType pieceType;
  List<JigsawPiece> pieces = [];
  bool isComplete = false;
  ui.Image? resolvedImage;
  bool isImageLoading = true;
  Offset? lastSnapOffset;

  JigsawEngine({
    required this.imageProvider,
    required this.gridRows,
    required this.gridCols,
    this.isEasyMode = true,
    this.pieceType = JigsawPieceType.traditional,
  }) {
    _resolveImage();
  }

  Future<void> _resolveImage() async {
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ImageStreamListener? listener;
    listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
      completer.complete(info.image);
      stream.removeListener(listener!);
    });
    stream.addListener(listener);
    resolvedImage = await completer.future;
    isImageLoading = false;
    _generatePieces();
    notifyListeners();
  }

  void _generatePieces() {
    if (resolvedImage == null) return;
    pieces = [];

    // Pre-calculate side shapes
    // horizontalEdges[rows+1][cols]
    final List<List<int>> horizontalEdges = List.generate(
      gridRows + 1,
      (y) => List.generate(
        gridCols,
        (x) => (y == 0 || y == gridRows) ? 0 : (Random().nextBool() ? 1 : -1),
      ),
    );
    // verticalEdges[rows][cols+1]
    final List<List<int>> verticalEdges = List.generate(
      gridRows,
      (y) => List.generate(
        gridCols + 1,
        (x) => (x == 0 || x == gridCols) ? 0 : (Random().nextBool() ? 1 : -1),
      ),
    );

    int id = 0;
    for (int y = 0; y < gridRows; y++) {
      for (int x = 0; x < gridCols; x++) {
        // Random starting position outside the [0, 1] target area
        // Pieces should stay within [-0.15, 1.05] to ensure they are at least half visible
        double startX, startY;
        if (Random().nextBool()) {
          // Place on Left or Right
          startX = Random().nextBool()
              ? -0.15 - Random().nextDouble() * 0.05
              : 1.05 + Random().nextDouble() * 0.05;
          startY = Random().nextDouble() * 1.1 - 0.05;
        } else {
          // Place on Top or Bottom
          startX = Random().nextDouble() * 1.1 - 0.05;
          startY = Random().nextBool()
              ? -0.15 - Random().nextDouble() * 0.05
              : 1.05 + Random().nextDouble() * 0.05;
        }

        pieces.add(
          JigsawPiece(
            id: id++,
            correctX: x,
            correctY: y,
            imageRect: Rect.fromLTWH(
              x / gridCols,
              y / gridRows,
              1 / gridCols,
              1 / gridRows,
            ),
            imageProvider: imageProvider,
            top: horizontalEdges[y][x],
            right: verticalEdges[y][x + 1],
            bottom: horizontalEdges[y + 1][x],
            left: verticalEdges[y][x],
            pieceType: pieceType,
            currentX: startX,
            currentY: startY,
          ),
        );
      }
    }
  }

  void bringPieceToFront(JigsawPiece piece) {
    pieces.remove(piece);
    pieces.add(piece);
    notifyListeners();
  }

  void updatePiecePosition(JigsawPiece piece, double dx, double dy) {
    if (piece.isPlaced) return;
    // Allow pieces to move outside [0, 1] for the "tray" effect
    piece.currentX = dx;
    piece.currentY = dy;

    // Auto-snap if close enough (Easy Mode only)
    if (isEasyMode) {
      _trySnap(piece);
    }

    notifyListeners();
  }

  void trySnapPiece(JigsawPiece piece) {
    _trySnap(piece);
  }

  void _trySnap(JigsawPiece piece) {
    if (piece.isPlaced) return;

    // Check if close to correct position
    double targetX = piece.correctX / gridCols;
    double targetY = piece.correctY / gridRows;

    if ((piece.currentX - targetX).abs() < 0.05 &&
        (piece.currentY - targetY).abs() < 0.05) {
      piece.currentX = targetX;
      piece.currentY = targetY;
      piece.isPlaced = true;
      lastSnapOffset = Offset(targetX, targetY);
      _checkCompletion();
      notifyListeners();
    }
  }

  void _checkCompletion() {
    isComplete = pieces.every((p) => p.isPlaced);
    if (isComplete) notifyListeners();
  }

  void clampAllPieces({
    required double minX,
    required double maxX,
    required double minY,
    required double maxY,
  }) {
    bool changed = false;
    for (var piece in pieces) {
      if (piece.isPlaced) continue;
      final oldX = piece.currentX;
      final oldY = piece.currentY;
      piece.currentX = piece.currentX.clamp(minX, maxX);
      piece.currentY = piece.currentY.clamp(minY, maxY);
      if (piece.currentX != oldX || piece.currentY != oldY) {
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void clearLastSnap() {
    lastSnapOffset = null;
    notifyListeners();
  }

  void resetGame() {
    isComplete = false;
    lastSnapOffset = null;
    _generatePieces();
    notifyListeners();
  }
}
