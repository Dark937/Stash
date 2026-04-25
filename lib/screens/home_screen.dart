import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/storage_service.dart';
import '../models/stash_card.dart';
import 'card_detail_screen.dart';
import 'create_hub_screen.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;

  const HomeScreen({super.key, required this.storageService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  void _refresh() {
    setState(() {});
  }

  Widget _buildTypeOption(BuildContext ctx, String label, IconData icon, CardType type) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      onTap: () async {
        Navigator.pop(ctx);
        final changed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateHubScreen(storageService: widget.storageService, initialType: type),
            fullscreenDialog: true,
          ),
        );
        if (changed == true) _refresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allCards = widget.storageService.cards;
    
    final filteredCards = allCards.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             c.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Minimal Search Bar (Image 2 style)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface, 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Search your mind...',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 16),
                    prefixIcon: Icon(Icons.search, color: Colors.white24),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            Expanded(
              child: filteredCards.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bubble_chart_outlined, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        const Text('Your mind is clear.', style: TextStyle(color: Colors.white24, fontSize: 16)),
                      ],
                    ),
                  )
                : MasonryGridView.count(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    itemCount: filteredCards.length,
                    itemBuilder: (context, index) {
                      return _buildCard(filteredCards[index]);
                    },
                  ),
            ),

            // Floating footer-like Quick Add (Image 2)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Colors.white.withValues(alpha: 0.4), size: 20),
                          const SizedBox(width: 12),
                          const Text('Quick stash...', style: TextStyle(color: Colors.white24, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: theme.scaffoldBackgroundColor,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                        builder: (ctx) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('What do you want to stash?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 20),
                              _buildTypeOption(ctx, 'Note', Icons.edit_note, CardType.note),
                              _buildTypeOption(ctx, 'Link', Icons.link, CardType.link),
                              _buildTypeOption(ctx, 'Video', Icons.videocam_outlined, CardType.video),
                              _buildTypeOption(ctx, 'List', Icons.checklist_rounded, CardType.list),
                              _buildTypeOption(ctx, 'Quote', Icons.format_quote_rounded, CardType.quote),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(StashCard card) {
    final theme = Theme.of(context);
    final bool isQuote = card.type == CardType.quote;
    final bool isVideo = card.type == CardType.video;
    final bool isLink = card.type == CardType.link;
    final bool isList = card.type == CardType.list;
    final bool isNote = card.type == CardType.note;

    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CardDetailScreen(card: card, storageService: widget.storageService)),
        );
        if (changed == true) _refresh();
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.imagePath != null)
              Image.file(File(card.imagePath!), fit: BoxFit.cover, width: double.infinity),
            
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isQuote)
                    Text(
                      card.content,
                      maxLines: 8,
                      overflow: TextOverflow.fade,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: Colors.white,
                      ),
                    )
                  else if (isList)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        const SizedBox(height: 8),
                        ...card.content.split('\n').take(4).map((line) {
                          bool isChecked = line.startsWith('[x]');
                          String text = line.length > 4 ? line.substring(4) : line;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              children: [
                                Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, size: 14, color: isChecked ? theme.primaryColor : Colors.white24),
                                const SizedBox(width: 8),
                                Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: isChecked ? Colors.white24 : Colors.white70, decoration: isChecked ? TextDecoration.lineThrough : null))),
                              ],
                            ),
                          );
                        }),
                      ],
                    )
                  else if (isNote) 
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.content.startsWith(card.title) ? card.content.replaceFirst(card.title, '').trim() : card.content,
                          maxLines: 7,
                          overflow: TextOverflow.fade,
                          style: const TextStyle(fontSize: 14, height: 1.45, color: Colors.white70),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      children: [
                        if (isVideo) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.play_circle_outline, size: 14, color: Colors.white54)),
                        if (isLink) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.link, size: 14, color: Colors.white54)),
                        Expanded(child: Text(card.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(card.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.white54)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
