import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'card_detail_screen.dart';

class SpaceDetailScreen extends StatefulWidget {
  final String categoryName;
  final StorageService storageService;

  const SpaceDetailScreen({
    super.key,
    required this.categoryName,
    required this.storageService,
  });

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  void _deleteSpace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Delete Space?'),
        content: Text('Are you sure you want to delete "${widget.categoryName}"? All cards inside will be moved to "no space".'),
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
      await widget.storageService.deleteCategory(widget.categoryName);
      if (mounted) Navigator.pop(context);
    }
  }

  void _renameSpace() {
    final ctrl = TextEditingController(text: widget.categoryName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Rename Space'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty && newName != widget.categoryName) {
                await widget.storageService.updateCategory(widget.categoryName, newName);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.storageService,
      builder: (context, _) {
        final cards = widget.storageService.cards.where((c) => c.category == widget.categoryName && !c.isDeleted).toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(widget.categoryName),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.white70),
                color: Theme.of(context).colorScheme.surface,
                onSelected: (val) {
                  if (val == 'rename') _renameSpace();
                  if (val == 'delete') _deleteSpace();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              )
            ],
          ),
          body: cards.isEmpty
              ? const Center(child: Text('This space is empty', style: TextStyle(color: Colors.white38)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (ctx, index) {
                    final card = cards[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CardDetailScreen(card: card, storageService: widget.storageService)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Expanded(child: Text(card.content, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 5, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
