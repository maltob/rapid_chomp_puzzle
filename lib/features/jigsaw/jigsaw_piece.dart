import 'package:flutter/material.dart';

enum JigsawPieceType { traditional, rounded }

class JigsawPiece {
  final int id;
  final int correctX;
  final int correctY;
  final Rect imageRect;
  final ImageProvider imageProvider;
  final JigsawPieceType pieceType;

  // Side shapes: 0 = flat, 1 = tab (out), -1 = blank (in)
  final int top;
  final int right;
  final int bottom;
  final int left;

  // Current position (normalized 0.0 to 1.0 within boxSize)
  double currentX;
  double currentY;
  bool isPlaced;

  JigsawPiece({
    required this.id,
    required this.correctX,
    required this.correctY,
    required this.imageRect,
    required this.imageProvider,
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
    this.pieceType = JigsawPieceType.rounded,
    this.currentX = 0,
    this.currentY = 0,
    this.isPlaced = false,
  });
}
