import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/stash_card.dart';

class StorageService extends ChangeNotifier {
  final SharedPreferences _prefs;
  static const String _cardsKey = 'stash_cards_2';
  static const String _categoriesKey = 'stash_categories_2';

  StorageService(this._prefs);

  List<StashCard> _cards = [];
  List<String> _categories = [];

  Future<void> init() async {
    _loadCards();
    _loadCategories();
    _cleanTrash();
  }

  void _loadCards() {
    final rawData = _prefs.getStringList(_cardsKey) ?? [];
    _cards = rawData
        .map((e) => StashCard.fromJson(json.decode(e)))
        .toList();
  }

  void _loadCategories() {
    _categories = _prefs.getStringList(_categoriesKey) ?? [];
  }

  Future<void> _saveCards() async {
    final rawData = _cards.map((e) => json.encode(e.toJson())).toList();
    await _prefs.setStringList(_cardsKey, rawData);
  }

  Future<void> _saveCategories() async {
    await _prefs.setStringList(_categoriesKey, _categories);
  }

  // Cards API
  List<StashCard> get cards => _cards.where((c) => !c.isDeleted).toList();
  List<StashCard> get trashCards => _cards.where((c) => c.isDeleted).toList();
  
  List<StashCard> getCardsByCategory(String? category) {
    if (category == null || category.isEmpty) return cards;
    return cards.where((c) => c.category == category).toList();
  }

  Future<void> addCard(StashCard card) async {
    _cards.add(card);
    await _saveCards();
    notifyListeners();
  }

  Future<void> updateCard(StashCard updated) async {
    final index = _cards.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _cards[index] = updated;
      await _saveCards();
      notifyListeners();
    }
  }

  Future<bool> togglePin(String id) async {
    final index = _cards.indexWhere((c) => c.id == id);
    if (index == -1) return false;
    
    final card = _cards[index];
    if (!card.isPinned) {
      // Check limit
      final pinnedCount = _cards.where((c) => c.isPinned && !c.isDeleted).length;
      if (pinnedCount >= 4) {
        // Unpin the oldest pinned
        final oldestPinnedIdx = _cards.indexWhere((c) => c.isPinned && !c.isDeleted);
        if (oldestPinnedIdx != -1) {
          _cards[oldestPinnedIdx] = _cards[oldestPinnedIdx].copyWith(isPinned: false);
        }
      }
    }

    _cards[index] = card.copyWith(isPinned: !card.isPinned);
    await _saveCards();
    notifyListeners();
    return _cards[index].isPinned;
  }

  Future<void> moveToTrash(String id) async {
    final index = _cards.indexWhere((c) => c.id == id);
    if (index != -1) {
      _cards[index] = _cards[index].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
      await _saveCards();
      notifyListeners();
    }
  }

  Future<void> restoreFromTrash(String id) async {
    final index = _cards.indexWhere((c) => c.id == id);
    if (index != -1) {
      _cards[index] = _cards[index].copyWith(
        isDeleted: false,
        deletedAt: null, // Hack around the fact copyWith needs exact null bypass or just assign a far future, actually let's implement true null clearing via another way.
      );
      
      // Fix on copyWith: it doesn't clear deletedAt if we use current copyWith. We just re-instantiate or explicitly handle it.
      _cards[index] = StashCard(
        id: _cards[index].id,
        type: _cards[index].type,
        title: _cards[index].title,
        content: _cards[index].content,
        category: _cards[index].category,
        dateAdded: _cards[index].dateAdded,
        lastReviewed: _cards[index].lastReviewed,
        isDeleted: false,
        deletedAt: null,
        tags: _cards[index].tags,
      );
      
      await _saveCards();
      notifyListeners();
    }
  }

  Future<void> permanentlyDelete(String id) async {
    _cards.removeWhere((c) => c.id == id);
    await _saveCards();
    notifyListeners();
  }

  // Trash Cleaner - called on startup
  void _cleanTrash() {
    final now = DateTime.now();
    bool changed = false;
    _cards.removeWhere((c) {
      if (c.isDeleted && c.deletedAt != null) {
        final diff = now.difference(c.deletedAt!).inDays;
        if (diff >= 3) {
          changed = true;
          return true; // Remove from list permanently
        }
      }
      return false;
    });
    if (changed) {
      _saveCards();
    }
  }

  // Daily Review Logic
  List<StashCard> getCardsForReview() {
    final now = DateTime.now();
    // Cards not in trash, order by oldest without review.
    var reviewable = cards.where((c) {
      if (c.lastReviewed == null) return true;
      // Not reviewed today
      return c.lastReviewed!.day != now.day || c.lastReviewed!.month != now.month || c.lastReviewed!.year != now.year;
    }).toList();
    
    // Sort logic: older unreviewed dates first
    reviewable.sort((a, b) {
      if (a.lastReviewed == null && b.lastReviewed == null) {
        return a.dateAdded.compareTo(b.dateAdded);
      }
      if (a.lastReviewed == null) return -1;
      if (b.lastReviewed == null) return 1;
      return a.lastReviewed!.compareTo(b.lastReviewed!);
    });
    
    // Max 20 cards
    return reviewable.take(20).toList();
  }

  Future<void> markReviewed(String id) async {
    final index = _cards.indexWhere((c) => c.id == id);
    if (index != -1) {
      _cards[index] = _cards[index].copyWith(lastReviewed: DateTime.now());
      await _saveCards();
      notifyListeners();
    }
  }

  // Categories API
  List<String> get categories => List.unmodifiable(_categories);

  Future<void> addCategory(String cat, {Color? color}) async {
    if (!_categories.contains(cat) && cat.trim().isNotEmpty) {
      _categories.add(cat.trim());
      await _saveCategories();
      if (color != null) {
        await _prefs.setInt('cat_color_${cat.trim()}', color.toARGB32());
      }
      notifyListeners();
    }
  }

  Color? getCategoryColor(String cat) {
    int? val = _prefs.getInt('cat_color_$cat');
    if (val != null) return Color(val);
    return null;
  }

  Future<void> updateCategory(String oldName, String newName) async {
    final idx = _categories.indexOf(oldName);
    if (idx != -1 && newName.trim().isNotEmpty) {
      _categories[idx] = newName.trim();
      await _saveCategories();

      // Migrate existing cards
      bool changedCards = false;
      for (int i = 0; i < _cards.length; i++) {
        if (_cards[i].category == oldName) {
          _cards[i] = _cards[i].copyWith(category: newName.trim());
          changedCards = true;
        }
      }
      if (changedCards) await _saveCards();
    }
  }

  Future<void> deleteCategory(String name) async {
    if (_categories.remove(name)) {
      await _saveCategories();

      // Detach category from existing cards
      bool changedCards = false;
      for (int i = 0; i < _cards.length; i++) {
        if (_cards[i].category == name) {
           // We can't set to null with current simple copyWith if it ignores null, so we recreate.
          _cards[i] = StashCard(
            id: _cards[i].id,
            type: _cards[i].type,
            title: _cards[i].title,
            content: _cards[i].content,
            category: null,
            dateAdded: _cards[i].dateAdded,
            lastReviewed: _cards[i].lastReviewed,
            isDeleted: _cards[i].isDeleted,
            deletedAt: _cards[i].deletedAt,
            tags: _cards[i].tags,
          );
          changedCards = true;
        }
      }
      if (changedCards) await _saveCards();
      notifyListeners();
    }
  }
}
