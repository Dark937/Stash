import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../models/stash_card.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'categories_manager_screen.dart';
import 'daily_review_screen.dart';

class MainShell extends StatefulWidget {
  final StorageService storageService;

  const MainShell({super.key, required this.storageService});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;
  late StreamSubscription _intentDataStreamSubscription;

  void _handleSharedData(String content) async {
    if (content.trim().isEmpty) return;
    
    // Auto-detect link, video, quote, list, or text note (mirrored from CreateHubScreen)
    CardType type = CardType.note;
    if (content.startsWith('"') && content.endsWith('"')) {
      type = CardType.quote;
    } else if (content.startsWith('- ') || content.startsWith('* ')) {
      type = CardType.list;
    } else if (content.startsWith('http://') || content.startsWith('https://')) {
      if (content.contains('youtube.com') || content.contains('youtu.be') || content.contains('tiktok.com') || content.contains('instagram.com')) {
        type = CardType.video;
      } else {
        type = CardType.link;
      }
    }

    final card = StashCard(
      id: const Uuid().v4(),
      type: type,
      title: content.split('\n')[0],
      content: content,
      category: null,
      dateAdded: DateTime.now(),
    );

    await widget.storageService.addCard(card);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Stash!'), backgroundColor: Color(0xFF5ED3C4), behavior: SnackBarBehavior.floating),
      );
      setState(() {
        _pages[0] = HomeScreen(storageService: widget.storageService); // force refresh
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(storageService: widget.storageService),
      CategoriesManagerScreen(storageService: widget.storageService),
      DailyReviewScreen(storageService: widget.storageService),
    ];

    // Universal sharing handler (URLs, notes, quotes, and files)
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        // In version 1.5.0+, text content is also provided in the 'path' field
        _handleSharedData(value.first.path);
      }
    }, onError: (err) => debugPrint("getMediaStream error: $err"));

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedData(value.first.path);
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffold = Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListenableBuilder(
        listenable: widget.storageService,
        builder: (context, _) {
          return IndexedStack(
            index: _currentIndex,
            children: _pages,
          );
        },
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent, // Transparent background matching the gradient
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          currentIndex: _currentIndex,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: Colors.grey.shade500,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.dashboard_rounded, size: 26),
              ),
              label: 'Everything',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.circle_outlined, size: 26),
              ),
              label: 'Spaces',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.psychology, size: 28),
              ),
              label: 'Serendipity',
            ),
          ],
        ),
      ),
    );

    // Forces mobile layout feel on wide screens (desktop/web)
    return Stack(
      children: [
        Container(
          color: const Color(0xFF0F0F14), // Deep charcoal instead of pure black
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: ClipRRect(
                child: scaffold,
              ),
            ),
          ),
        ),
        // Overlay gradient for bottom bar (matches screenshot aesthetic)
        Positioned(
          bottom: 0, left: 0, right: 0,
          height: 100,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        theme.scaffoldBackgroundColor,
                        theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                        theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
