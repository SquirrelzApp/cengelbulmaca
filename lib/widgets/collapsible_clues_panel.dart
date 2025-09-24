import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'clues_panel.dart';

class CollapsibleCluesPanel extends StatefulWidget {
  final VoidCallback? onPanelCollapsed;
  
  const CollapsibleCluesPanel({Key? key, this.onPanelCollapsed}) : super(key: key);

  @override
  _CollapsibleCluesPanelState createState() => _CollapsibleCluesPanelState();
}

class _CollapsibleCluesPanelState extends State<CollapsibleCluesPanel>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightFactor;
  bool _isExpanded = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightFactor = _animationController.drive(CurveTween(curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _collapsePanel() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _animationController.reverse();
      });
      // Notify parent that panel was collapsed
      widget.onPanelCollapsed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final horizontalClues = gameProvider.horizontalClues;
        final verticalClues = gameProvider.verticalClues;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6F0), // _cardSurface from theme
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: const Color(0xFFE8E4DC), width: 1), // _gridLine
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2C3E50).withOpacity(0.15), // _inkBlue
                blurRadius: 16.0,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with toggle button and swipe gesture
              GestureDetector(
                onTap: _toggleExpanded,
                onPanUpdate: (details) {
                  // Swipe up to expand, swipe down to collapse
                  if (details.delta.dy < -5 && !_isExpanded) {
                    _toggleExpanded();
                  } else if (details.delta.dy > 5 && _isExpanded) {
                    _toggleExpanded();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    children: [
                      // Enhanced handle bar at top
                      Container(
                        width: 60, // Increased width for better ergonomics
                        height: 6, // Increased height for easier grabbing
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D6D7E), // More visible color
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Current clue indicator
                          Expanded(
                            child: _buildCurrentClueHeader(gameProvider),
                          ),
                          // Letter taking button for current word (when collapsed)
                          if (!_isExpanded && gameProvider.gameState.selectedWord != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: IconButton(
                                icon: const Icon(Icons.text_fields_outlined, size: 18),
                                onPressed: () => _takeLetterFromCurrentWord(gameProvider),
                                tooltip: 'Harf al',
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
                                  foregroundColor: const Color(0xFFD4AF37),
                                  minimumSize: const Size(36, 36),
                                ),
                              ),
                            ),
                          // Toggle button
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_up,
                              color: const Color(0xFF5D6D7E), // _warmGray
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Collapsible content
              AnimatedBuilder(
                animation: _heightFactor,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _heightFactor.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  height: _calculateOptimalHeight(context, horizontalClues, verticalClues),
                  child: Column(
                    children: [
                      // Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E4DC).withOpacity(0.3), // _gridLine with opacity
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTabButton(
                                'YATAY (${horizontalClues.length})',
                                Icons.arrow_forward,
                                0,
                              ),
                            ),
                            Expanded(
                              child: _buildTabButton(
                                'DİKEY (${verticalClues.length})',
                                Icons.arrow_downward,
                                1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Clues content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _selectedTabIndex == 0
                              ? CluesList(
                                  clues: horizontalClues,
                                  isHorizontal: true,
                                  onCollapsePanel: _collapsePanel,
                                )
                              : CluesList(
                                  clues: verticalClues,
                                  isHorizontal: false,
                                  onCollapsePanel: _collapsePanel,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentClueHeader(GameProvider gameProvider) {
    final selectedWord = gameProvider.gameState.selectedWord;
    if (selectedWord == null) {
      return const Text(
        'Kelime seçin',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF5D6D7E), // _warmGray
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final direction = selectedWord.isHorizontal ? 'YATAY' : 'DİKEY';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.2), // _vintageGold
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              ),
              child: Text(
                '${selectedWord.number} $direction',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50), // _inkBlue
                  fontFamily: 'serif',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${selectedWord.length} harf',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF5D6D7E), // _warmGray
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          selectedWord.clue,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50), // _inkBlue
            fontFamily: 'serif',
            height: 1.4, // Improved line height for Turkish text readability
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _takeLetterFromCurrentWord(GameProvider gameProvider) {
    final selectedWord = gameProvider.gameState.selectedWord;
    if (selectedWord != null) {
      gameProvider.takeRandomLetterFromWord(selectedWord);
    }
  }

  double _calculateOptimalHeight(BuildContext context, List horizontalClues, List verticalClues) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxClueCount = horizontalClues.length > verticalClues.length ? horizontalClues.length : verticalClues.length;
    
    // Calculate needed height based on clue count
    // Each clue item is approximately 70-80 pixels + tabs + padding
    const itemHeight = 76.0;
    const tabsHeight = 50.0;
    const padding = 32.0;
    
    final neededHeight = (maxClueCount * itemHeight) + tabsHeight + padding;
    final maxAllowedHeight = screenHeight * 0.4; // Max 40% of screen
    final minHeight = screenHeight * 0.25; // Min 25% of screen
    
    // Return optimal height within bounds
    if (neededHeight > maxAllowedHeight) {
      return maxAllowedHeight;
    } else if (neededHeight < minHeight) {
      return minHeight;
    } else {
      return neededHeight;
    }
  }

  Widget _buildTabButton(String label, IconData icon, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C3E50) : Colors.transparent, // _inkBlue
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF5D6D7E), // _warmGray
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF5D6D7E), // _warmGray
                  fontFamily: 'serif',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
