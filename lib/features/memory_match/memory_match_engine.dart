import 'dart:async';
import 'package:flutter/material.dart';
import 'memory_card.dart';

class MemoryMatchEngine extends ChangeNotifier {
  final int numberOfPairs;
  final List<String>? customImagePaths;
  List<MemoryCard> cards = [];
  MemoryCard? firstSelected;
  MemoryCard? secondSelected;
  bool _isBusy = false;
  int moves = 0;
  int matches = 0;
  List<int> lastMatchIndices = [];

  MemoryMatchEngine(this.numberOfPairs, {this.customImagePaths}) {
    _initializeGame();
  }

  bool get isCustomMode =>
      customImagePaths != null && customImagePaths!.isNotEmpty;

  void _initializeGame() {
    if (isCustomMode) {
      final selectedImages = customImagePaths!.take(numberOfPairs).toList();
      List<MemoryCard> newCards = [];
      for (int i = 0; i < selectedImages.length; i++) {
        newCards.add(MemoryCard(id: i * 2, content: selectedImages[i]));
        newCards.add(MemoryCard(id: i * 2 + 1, content: selectedImages[i]));
      }
      newCards.shuffle();
      cards = newCards;
    } else {
      final List<String> symbols = [
        '🍎',
        '🍌',
        '🍇',
        '🍓',
        '🍒',
        '🍍',
        '🥝',
        '🍋',
        '🍉',
        '🍑',
        '🍐',
        '🥭',
        '🥥',
        '🥑',
        '🍆',
        '🌽',
        '🥦',
        '🥕',
        '🍔',
        '🍕',
        '🍦',
        '🍩',
        '🍫',
        '🍭',
      ];
      symbols.shuffle();

      final selectedSymbols = symbols.take(numberOfPairs).toList();
      List<MemoryCard> newCards = [];

      for (int i = 0; i < selectedSymbols.length; i++) {
        newCards.add(MemoryCard(id: i * 2, content: selectedSymbols[i]));
        newCards.add(MemoryCard(id: i * 2 + 1, content: selectedSymbols[i]));
      }

      newCards.shuffle();
      cards = newCards;
    }
    notifyListeners();
  }

  void onCardTap(MemoryCard card) {
    if (_isBusy || card.isFaceUp || card.isMatched) return;

    card.isFaceUp = true;
    notifyListeners();

    if (firstSelected == null) {
      firstSelected = card;
    } else {
      secondSelected = card;
      moves++;
      _checkForMatch();
    }
  }

  void _checkForMatch() {
    _isBusy = true;

    if (firstSelected!.content == secondSelected!.content) {
      firstSelected!.isMatched = true;
      secondSelected!.isMatched = true;
      lastMatchIndices = [
        cards.indexOf(firstSelected!),
        cards.indexOf(secondSelected!),
      ];
      matches++;
      firstSelected = null;
      secondSelected = null;
      _isBusy = false;
      notifyListeners();
    } else {
      Timer(const Duration(milliseconds: 1000), () {
        firstSelected!.isFaceUp = false;
        secondSelected!.isFaceUp = false;
        firstSelected = null;
        secondSelected = null;
        _isBusy = false;
        notifyListeners();
      });
    }
  }

  bool get isGameOver => matches == numberOfPairs;

  void clearLastMatch() {
    lastMatchIndices.clear();
    notifyListeners();
  }

  void resetGame() {
    firstSelected = null;
    secondSelected = null;
    _isBusy = false;
    moves = 0;
    matches = 0;
    _initializeGame();
  }
}
