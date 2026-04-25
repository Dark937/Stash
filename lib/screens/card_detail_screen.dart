import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/stash_card.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class CardDetailScreen extends StatefulWidget {
  final StashCard card;
  final StorageService storageService;

  const CardDetailScreen({super.key, required this.card, required this.storageService});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late StashCard _card;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
  }

  void _deleteCard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Delete Card?'),
        content: const Text('Are you sure you want to move this card to the trash?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storageService.moveToTrash(_card.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _showSpacePicker() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Move to Space', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            ...widget.storageService.categories.map((cat) => ListTile(
              title: Text(cat, style: const TextStyle(color: Colors.white70)),
              onTap: () async {
                final updated = _card.copyWith(category: cat);
                await widget.storageService.updateCard(updated);
                if (ctx.mounted) {
                  setState(() => _card = updated);
                  Navigator.pop(ctx);
                }
              },
            )),
            ListTile(
              title: const Text('None', style: TextStyle(color: Colors.white38)),
              onTap: () async {
                final updated = StashCard(
                  id: _card.id, type: _card.type, title: _card.title, content: _card.content,
                  category: null, dateAdded: _card.dateAdded, lastReviewed: _card.lastReviewed,
                  isDeleted: _card.isDeleted, deletedAt: _card.deletedAt, isPinned: _card.isPinned,
                  tags: _card.tags,
                  imagePath: _card.imagePath,
                );
                await widget.storageService.updateCard(updated);
                if (ctx.mounted) {
                  setState(() => _card = updated);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _togglePin() async {
    bool isPinned = await widget.storageService.togglePin(_card.id);
    setState(() {
      _card = _card.copyWith(isPinned: isPinned);
    });
  }

  void _shareCard() {
    // Only share content if it already contains the title, otherwise concat.
    String textToShare = _card.content;
    if (!_card.content.contains(_card.title)) {
      textToShare = "${_card.title}\n\n${_card.content}";
    }
    SharePlus.instance.share(
      ShareParams(text: textToShare),
    );
  }

  void _addTag() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Add Tag'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Enter tag name'),
          onSubmitted: (val) {
             if (val.trim().isNotEmpty) {
               final newTags = [..._card.tags, val.trim()];
               final updated = _card.copyWith(tags: newTags);
               widget.storageService.updateCard(updated);
               setState(() => _card = updated);
               Navigator.pop(ctx);
             }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                final newTags = [..._card.tags, ctrl.text.trim()];
                final updated = _card.copyWith(tags: newTags);
                widget.storageService.updateCard(updated);
                setState(() => _card = updated);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  void _removeTag(String tag) {
    final newTags = _card.tags.where((t) => t != tag).toList();
    final updated = _card.copyWith(tags: newTags);
    widget.storageService.updateCard(updated);
    setState(() => _card = updated);
  }

  void _toggleListItem(int index, bool checked) async {
    final lines = _card.content.split('\n');
    if (index < lines.length) {
      final line = lines[index];
      final newPrefix = checked ? '[x]' : '[ ]';
      lines[index] = line.replaceRange(0, 3, newPrefix);
      
      final updated = _card.copyWith(content: lines.join('\n'));
      await widget.storageService.updateCard(updated);
      setState(() => _card = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final bool isLink = _card.type == CardType.link;
    final bool isVideo = _card.type == CardType.video;
    final bool isQuote = _card.type == CardType.quote;
    final bool isList = _card.type == CardType.list;

    final formattedDate = DateFormat.yMMMd().format(_card.dateAdded);
    
    String brandName = 'Website';
    if (_card.content.contains('youtube.com') || _card.content.contains('youtu.be')) {
      brandName = 'YouTube';
    } else if (_card.content.contains('tiktok.com')) {
      brandName = 'TikTok';
    } else if (_card.content.contains('instagram.com')) {
      brandName = 'Instagram';
    }
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.expand_more, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _card.title,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_card.imagePath != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(File(_card.imagePath!), fit: BoxFit.cover),
                ),
              ),

            const SizedBox(height: 24),
            
            if (isLink || isVideo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(isVideo ? Icons.play_arrow_rounded : Icons.open_in_new_rounded, color: Colors.white, size: 18),
                  label: Text(isVideo ? 'WATCH ON $brandName' : 'OPEN IN BROWSER', style: const TextStyle(color: Colors.white, letterSpacing: 1.1, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),

            if (isLink || isVideo) const SizedBox(height: 24),
            
            if (isLink || isVideo)
              Column(
                children: [
                   const Text('ORIGIN', style: TextStyle(fontSize: 10, color: Colors.white30, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Text(brandName, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500)),
                   const SizedBox(height: 24),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 32.0),
                     child: Divider(color: Colors.white.withValues(alpha: 0.1)),
                   ),
                   const SizedBox(height: 24),
                ],
              ),
              
            if (isList)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _card.content.split('\n').where((s) => s.trim().isNotEmpty).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final line = entry.value;
                    bool isChecked = line.startsWith('[x]');
                    String text = line.length > 4 ? line.substring(4) : line;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: CheckboxListTile(
                        value: isChecked,
                        onChanged: (val) => _toggleListItem(index, val ?? false),
                        title: Text(text, style: TextStyle(color: isChecked ? Colors.white30 : Colors.white70, decoration: isChecked ? TextDecoration.lineThrough : null)),
                        activeColor: theme.primaryColor,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    );
                  }).toList(),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  _card.content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isQuote ? 26 : 16,
                    color: Colors.white70,
                    height: 1.6,
                    fontFamily: isQuote ? 'Georgia' : 'Inter',
                    fontStyle: isQuote ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),

            const SizedBox(height: 40),
            
            if (isLink)
               Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_fix_high, color: Colors.white.withValues(alpha: 0.5), size: 20),
                        const SizedBox(width: 8),
                        const Text("I've purchased this", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
               ),
               
            const SizedBox(height: 48),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MIND TAGS', style: TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GestureDetector(
                        onTap: _addTag,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Add tag', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      ..._card.tags.map((tag) => GestureDetector(
                        onTap: () => _removeTag(tag),
                        child: _buildTag(tag, null),
                      )),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SPACE', style: TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showSpacePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle_outlined, color: theme.primaryColor, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            _card.category ?? 'Choose a Space...',
                            style: TextStyle(color: _card.category != null ? Colors.white : Colors.white30, fontSize: 15),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_drop_down, color: Colors.white24, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MIND NOTES', style: TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'Type here to add a note...',
                      style: TextStyle(color: Colors.white30, fontSize: 15),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 40),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _togglePin,
                    child: _buildBottomBtn(_card.isPinned ? Icons.push_pin : Icons.push_pin_outlined, _card.isPinned ? 'Unpin' : 'Pin', theme.colorScheme.surface, textColor: _card.isPinned ? theme.primaryColor : Colors.white70),
                  ),
                  GestureDetector(
                    onTap: _shareCard,
                    child: _buildBottomBtn(Icons.ios_share, 'Share', theme.colorScheme.surface),
                  ),
                  GestureDetector(
                    onTap: _deleteCard,
                    child: _buildBottomBtn(Icons.delete_outline, 'Delete', const Color(0xFF3A1A22), textColor: const Color(0xFFFF453A)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                'Saved to your mind, $formattedDate',
                style: const TextStyle(color: Colors.white30, fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white54, size: 14),
            const SizedBox(width: 4),
          ],
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildBottomBtn(IconData icon, String text, Color bgColor, {Color textColor = Colors.white70}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
