import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/stash_card.dart';

class DailyReviewScreen extends StatefulWidget {
  final StorageService storageService;

  const DailyReviewScreen({super.key, required this.storageService});

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onAction(StashCard card, bool keep) async {
    await _animController.forward();
    if (!keep) {
      await widget.storageService.moveToTrash(card.id);
    } else {
      await widget.storageService.markReviewed(card.id);
    }
    _animController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.storageService,
      builder: (context, _) {
        final cards = widget.storageService.getCardsForReview();
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0A0E),
                  Color(0xFF14141A),
                  Color(0xFF0A0A0E),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    "Serendipity",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Rediscovering your mind",
                    style: TextStyle(fontSize: 14, color: Colors.white38),
                  ),
                  Expanded(
                    child: Center(
                      child: cards.isEmpty
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.white12, size: 64),
                                SizedBox(height: 16),
                                Text(
                                  "Your mind is clear today.",
                                  style: TextStyle(fontSize: 18, color: Colors.white54),
                                ),
                              ],
                            )
                          : _buildAnimatedStack(cards),
                    ),
                  ),
                  if (cards.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 64.0, top: 32.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCircleBtn("Forget", Colors.redAccent.withValues(alpha: 0.1), () => _onAction(cards.first, false)),
                          const SizedBox(width: 48),
                          _buildCircleBtn("Keep", Colors.tealAccent.withValues(alpha: 0.1), () => _onAction(cards.first, true)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircleBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Text(
                label[0].toUpperCase(),
                style: const TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAnimatedStack(List<StashCard> cards) {
    final currentCard = cards.first;
    
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (cards.length > 1)
              Transform.scale(
                scale: 0.9 + (0.1 * _animController.value),
                child: Opacity(
                  opacity: 0.5 + (0.5 * _animController.value),
                  child: _buildSquareCard(cards[1], isBack: true),
                ),
              ),
            Dismissible(
              key: ValueKey(currentCard.id),
              onDismissed: (direction) {
                _onAction(currentCard, direction == DismissDirection.startToEnd);
              },
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: _buildSquareCard(currentCard),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSquareCard(StashCard card, {bool isBack = false}) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size.width * 0.8;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isBack)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0, height: 6,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.5)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  card.type == CardType.video ? Icons.play_circle_fill : 
                  card.type == CardType.link ? Icons.link : 
                  card.type == CardType.quote ? Icons.format_quote : Icons.notes,
                  color: Colors.white24,
                  size: 32,
                ),
                const SizedBox(height: 20),
                Text(
                  card.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: card.type == CardType.quote ? 'Georgia' : 'Inter',
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    card.content,
                    maxLines: 6,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white60,
                      height: 1.5,
                      fontFamily: card.type == CardType.quote ? 'Georgia' : 'Inter',
                      fontStyle: card.type == CardType.quote ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                if (card.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      card.category!.toLowerCase(),
                      style: const TextStyle(color: Colors.white30, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
