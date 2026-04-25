import 'package:flutter/material.dart';
import 'dart:math';

import '../services/storage_service.dart';

class CreateSpaceModal extends StatefulWidget {
  final StorageService storageService;

  const CreateSpaceModal({super.key, required this.storageService});

  @override
  State<CreateSpaceModal> createState() => _CreateSpaceModalState();
}

class _CreateSpaceModalState extends State<CreateSpaceModal> {
  int _step = 1;
  final TextEditingController _nameCtrl = TextEditingController();
  Color? _selectedColor;

  final List<Color> _availableColors = const [
    Color(0xFFFF3B30), // Red
    Color(0xFFFF9500), // Orange
    Color(0xFFFFCC00), // Yellow
    Color(0xFF4CD964), // Green Light
    Color(0xFF34C759), // Green Dark
    Color(0xFF5ED3C4), // Teal
    Color(0xFF5AC8FA), // Light Blue
    Color(0xFF007AFF), // Blue
    Color(0xFF5856D6), // Purple
    Color(0xFFFF2D55), // Pink
    Color(0xFFA2845E), // Brown
    Color(0xFF8E8E93), // Gray
  ];

  @override
  Widget build(BuildContext context) {
    if (_step == 1) {
      return _buildStep1();
    } else {
      return _buildStep2();
    }
  }

  Widget _buildStep1() {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white54, size: 24),
                )
              ],
            ),
            // Fake intersecting circles logo
            const SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(top: 0, left: 12, child: Icon(Icons.circle_outlined, color: Colors.yellow, size: 24)),
                  Positioned(top: 0, right: 12, child: Icon(Icons.circle_outlined, color: Colors.pink, size: 24)),
                  Positioned(bottom: 0, left: 12, child: Icon(Icons.circle_outlined, color: Colors.lightGreen, size: 24)),
                  Positioned(bottom: 0, right: 12, child: Icon(Icons.circle_outlined, color: Colors.lightBlue, size: 24)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Create new space',
              style: TextStyle(
                fontSize: 32,
                fontFamily: 'Georgia',
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'A space is a collection of cards inside your mind. Upload directly into a space, or pick a card from the overview.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameCtrl,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Name your new space',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () {
                  if (_nameCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      _step = 2;
                      _selectedColor = _availableColors[0];
                    });
                  }
                },
                child: const Text('NEXT STEP', style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final theme = Theme.of(context);
    const double radius = 100;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white54, size: 24),
                )
              ],
            ),
            const Text(
              'Pick a color',
              style: TextStyle(
                fontSize: 32,
                fontFamily: 'Georgia',
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Color coding your space helps you to spot it a lot easier when you need it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 48),
            // The Circle of Colors
            LayoutBuilder(
              builder: (context, constraints) {
                final centerX = constraints.maxWidth / 2;
                const centerY = 120.0; // Half of SizedBox height 240
                
                return SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Center selection container (the landing spot)
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10, width: 2),
                        ),
                      ),
                      // Outer ring of colors
                      ...List.generate(_availableColors.length, (index) {
                        final color = _availableColors[index];
                        final isSelected = _selectedColor == color;
                        final angle = (index * (360 / _availableColors.length)) * (pi / 180);
                        
                        final double dx = isSelected ? 0 : radius * cos(angle - pi/2);
                        final double dy = isSelected ? 0 : radius * sin(angle - pi/2);

                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          left: centerX + dx - (isSelected ? 28 : 16),
                          top: centerY + dy - (isSelected ? 28 : 16),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isSelected ? 56 : 32,
                              height: isSelected ? 56 : 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                boxShadow: isSelected ? [
                                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 2)
                                ] : [],
                              ),
                            ),
                          ),
                        );
                      })
                    ],
                  ),
                );
              }
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () async {
                  await widget.storageService.addCategory(_nameCtrl.text.trim(), color: _selectedColor);
                  if (!mounted) return;
                  Navigator.pop(context, true); // Return true to trigger refresh
                },
                child: const Text('FINISH & SAVE', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
