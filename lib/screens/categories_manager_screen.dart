import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/create_space_modal.dart';
import 'space_detail_screen.dart';

class CategoriesManagerScreen extends StatefulWidget {
  final StorageService storageService;

  const CategoriesManagerScreen({super.key, required this.storageService});

  @override
  State<CategoriesManagerScreen> createState() => _CategoriesManagerScreenState();
}

class _CategoriesManagerScreenState extends State<CategoriesManagerScreen> {
  Color _getSpaceColor(String name) {
    Color? color = widget.storageService.getCategoryColor(name);
    if (color != null) return color;

    const List<Color> fallbackColors = [
      Color(0xFFFF3B30),
      Color(0xFF34C759),
      Color(0xFF007AFF),
      Color(0xFFFF9500),
      Color(0xFFA2845E),
      Color(0xFF5ED3C4),
      Color(0xFFFF2D55),
      Color(0xFF5856D6),
    ];
    return fallbackColors[name.hashCode.abs() % fallbackColors.length];
  }

  void _refresh() => setState(() {});

  void _showCreateSpaceModal() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateSpaceModal(storageService: widget.storageService),
    );
    if (result == true) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.storageService,
      builder: (context, _) {
        final cats = widget.storageService.categories;
        final theme = Theme.of(context);

        List<String> leftCol = [];
        List<String> rightCol = [];
        for (int i = 0; i < cats.length; i++) {
          if (i % 2 == 0) {
            leftCol.add(cats[i]);
          } else {
            rightCol.add(cats[i]);
          }
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text('All Spaces', style: TextStyle(fontSize: 16, color: Colors.white70)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _showCreateSpaceModal,
                          child: const Icon(Icons.add, color: Colors.white70, size: 28),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: leftCol.map((c) => _buildSpaceCard(c)).toList(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: rightCol.map((c) => _buildSpaceCard(c)).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpaceCard(String name) {
    final theme = Theme.of(context);
    final count = widget.storageService.getCardsByCategory(name).length;
    final color = _getSpaceColor(name);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SpaceDetailScreen(categoryName: name, storageService: widget.storageService),
        ),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(height: 4, width: double.infinity, color: color),
                  Expanded(
                    child: Center(
                      child: Text(
                        count.toString(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white24),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2.5),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    name.toLowerCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 15, letterSpacing: -0.2),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
