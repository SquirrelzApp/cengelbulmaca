import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/turkish_casing.dart';
import '../providers/game_provider.dart';
import '../widgets/crossword_grid.dart';
import '../widgets/clues_panel.dart';
import '../widgets/collapsible_clues_panel.dart';
import '../widgets/turkish_character_picker.dart';
// import '../widgets/top_clues_panel.dart';
import '../models/game_state.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();
  final TextEditingController _mobileController = TextEditingController();
  final GlobalKey _gridAreaKey = GlobalKey();
  String _lastMobileText = ' ';
  bool _resettingMobileInput = false;
  bool _isPortrait = true;
  bool _keyboardVisible = false;
  bool _userDismissedKeyboard = false;
  bool _panelJustCollapsed = false; // Track if panel was collapsed programmatically
  String? _lastSelectedCellKey; // Track last selection to avoid unwanted refocus
  bool _showTurkishCharacterPicker = false;

  // Method to signal that panel collapsed programmatically
  void _onPanelCollapsed() {
    _panelJustCollapsed = true;
    _userDismissedKeyboard = false; // Reset dismiss flag when panel collapses
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize mobile controller with space for backspace detection
    _mobileController.text = ' ';
    _mobileController.selection = TextSelection.fromPosition(
      const TextPosition(offset: 1),
    );
    _lastMobileText = ' ';
    
    // Do not auto-focus hardware key listener; mobile input will manage focus.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _focusNode.dispose();
    _mobileFocusNode.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    
    // Detect keyboard visibility changes
    if (viewInsets > 0 && !_keyboardVisible) {
      _keyboardVisible = true;
    } else if (viewInsets == 0 && _keyboardVisible) {
      // Keyboard became hidden (possibly transient during taps). Do not
      // auto-mark as user dismissal or unfocus here. Let explicit actions
      // (back button, empty space tap, done) control dismissal.
      _keyboardVisible = false;
    }
  }

  // Design constants matching main menu theme
  static const Color _paperWhite = Color(0xFFFEFCF7);
  static const Color _inkBlue = Color(0xFF2C3E50);
  static const Color _vintageGold = Color(0xFFD4AF37);
  static const Color _warmGray = Color(0xFF5D6D7E);
  static const Color _gridLine = Color(0xFFE8E4DC);
  static const Color _cardSurface = Color(0xFFF8F6F0);

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    _isPortrait = orientation == Orientation.portrait;

    return WillPopScope(
      onWillPop: () async {
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        if (gameProvider.gameState.selectedCell != null || _mobileFocusNode.hasFocus || _keyboardVisible) {
          _userDismissedKeyboard = true;
          if (_mobileFocusNode.hasFocus) {
            _mobileFocusNode.unfocus();
          }
          gameProvider.deselectCell();
          return false;
        }
        return true;
      },
      child: Scaffold(
      backgroundColor: _paperWhite,
      resizeToAvoidBottomInset: false, // Prevent game from resizing when keyboard appears
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          // If tap is outside the grid area, clear selection + dismiss keyboard
          if (!_isPointInsideGrid(details.globalPosition)) {
            _handleGlobalEmptyTap();
          }
        },
        child: Container(
        decoration: _buildGameBackground(),
        child: SafeArea(
          child: Consumer<GameProvider>(
            builder: (context, gameProvider, child) {
              // Handle cell selection changes
              final sc = gameProvider.gameState.selectedCell;
              final currentKey = sc != null ? '${sc.row},${sc.col},${sc.direction}' : null;
              if (currentKey != _lastSelectedCellKey) {
                if (currentKey != null) {
                  // Switching to a new cell: keep keyboard open and focus maintained
                  _userDismissedKeyboard = false;
                  if (!_mobileFocusNode.hasFocus) {
                    _mobileFocusNode.requestFocus();
                  }
                } else {
                  // No selected cell: mark as user dismissal and unfocus
                  _userDismissedKeyboard = true;
                  if (_mobileFocusNode.hasFocus) {
                    _mobileFocusNode.unfocus();
                  }
                }
                _lastSelectedCellKey = currentKey;
              }
              if (gameProvider.isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: _vintageGold,
                        backgroundColor: _gridLine,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Bulmaca hazırlanıyor...',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          color: _warmGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (gameProvider.errorMessage != null) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: _cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _gridLine, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: _warmGray,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Hata: ${gameProvider.errorMessage}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 16,
                            color: _inkBlue,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => gameProvider.newGame(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _inkBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: _vintageGold, width: 1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text(
                            'Yeni Oyun Başlat',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  KeyboardListener(
                    focusNode: _focusNode,
                    autofocus: false,
                    onKeyEvent: (KeyEvent event) => _handleKeyPress(event, gameProvider),
                    child: Column(
                      children: [
                        // Elegant App bar
                        _buildElegantAppBar(gameProvider),
                        // Main content
                        Expanded(
                          child: _isPortrait
                              ? _buildPortraitLayoutWithOverlay(gameProvider)
                              : _buildLandscapeLayout(),
                        ),
                        // Turkish character picker
                        if (_showTurkishCharacterPicker && gameProvider.gameState.selectedCell != null)
                          TurkishCharacterPicker(
                            onCharacterSelected: (char) {
                              gameProvider.inputLetter(char);
                            },
                            onClose: () {
                              setState(() {
                                _showTurkishCharacterPicker = false;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  // Elegant clue display
                  if (gameProvider.gameState.selectedWord != null)
                    _buildElegantClueDisplay(gameProvider),
                  // Invisible TextField for mobile keyboard
                  if (gameProvider.gameState.selectedCell != null)
                    _buildInvisibleMobileInput(gameProvider),
                ],
              );
            },
          ),
        ),
      ),
      ),
    ),
    );
  }

  bool _isPointInsideGrid(Offset globalPosition) {
    final ctx = _gridAreaKey.currentContext;
    if (ctx == null) return false;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final topLeft = box.localToGlobal(Offset.zero);
    final rect = topLeft & box.size;
    return rect.contains(globalPosition);
  }

  // Background decoration matching main menu
  BoxDecoration _buildGameBackground() {
    return const BoxDecoration(
      color: _paperWhite,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _paperWhite,
          Color(0xFFFBF9F4),
          _paperWhite,
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }

  Widget _buildElegantAppBar(GameProvider gameProvider) {
    final gameState = gameProvider.gameState;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: _cardSurface,
        border: Border(
          bottom: BorderSide(color: _gridLine, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: _inkBlue.withOpacity(0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: _warmGray, size: 20),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          // Title with responsive sizing
          Expanded(
            flex: isSmallScreen ? 2 : 3,
            child: Text(
              isSmallScreen ? 'Bulmaca' : 'Çengel Bulmaca',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: _inkBlue,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Responsive stats - show only time on very small screens
          if (isSmallScreen) ...[
            _buildCompactStat(
              Icons.access_time_rounded, 
              gameState.formattedTime, 
              _vintageGold
            ),
          ] else ...[
            _buildElegantStat(
              Icons.access_time_rounded, 
              gameState.formattedTime, 
              _vintageGold
            ),
            const SizedBox(width: 8),
            _buildElegantStat(
              Icons.trending_up_rounded, 
              '${(gameState.completionPercentage * 100).toInt()}%', 
              _warmGray
            ),
            const SizedBox(width: 8),
            _buildElegantStat(
              Icons.text_fields_rounded, 
              '${gameState.lettersUsed}', 
              _inkBlue
            ),
          ],
          
          const SizedBox(width: 8),
          
          // Turkish character picker toggle
          if (gameProvider.gameState.selectedCell != null)
            IconButton(
              icon: Icon(
                _showTurkishCharacterPicker ? Icons.keyboard_hide : Icons.text_fields,
                color: _showTurkishCharacterPicker ? _vintageGold : _warmGray,
                size: 18,
              ),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                setState(() {
                  _showTurkishCharacterPicker = !_showTurkishCharacterPicker;
                });
              },
              tooltip: 'Türkçe karakterler',
            ),

          // Menu button
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: _warmGray, size: 20),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _showGameMenu(gameProvider),
          ),
        ],
      ),
    );
  }

  // Compact stat for small screens
  Widget _buildCompactStat(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildElegantStat(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'sans-serif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // Crossword grid with elegant styling
        Expanded(
          child: Container(
            key: _gridAreaKey,
            margin: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gridLine, width: 1),
              boxShadow: [
                BoxShadow(
                  color: _inkBlue.withOpacity(0.08),
                  blurRadius: 12.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CrosswordGrid(
              onEmptySpaceTap: _handleGlobalEmptyTap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayoutWithOverlay(GameProvider gameProvider) {
    return Column(
      children: [
        // Removed TopCluesPanel as requested; keep only bottom panel
        // Main game content (grid only)
        Expanded(child: _buildPortraitLayout()),
        // Bottom positioned clues panel that overlays the grid
        _buildOverlayCluesPanel(gameProvider),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Column(
      children: [
        // Main content
        Expanded(
          child: Row(
            children: [
              // Crossword grid with elegant styling
              Expanded(
                flex: 3,
                child: Container(
                  key: _gridAreaKey,
                  margin: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _gridLine, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _inkBlue.withOpacity(0.08),
                        blurRadius: 12.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CrosswordGrid(
                    onEmptySpaceTap: _handleGlobalEmptyTap,
                  ),
                ),
              ),
              // Elegant clues panel on the right
              Container(
                width: 280,
                margin: const EdgeInsets.fromLTRB(0, 12.0, 12.0, 12.0),
                decoration: BoxDecoration(
                  color: _cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _gridLine, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: _inkBlue.withOpacity(0.08),
                      blurRadius: 12.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const CluesPanel(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayCluesPanel(GameProvider gameProvider) {
    return CollapsibleCluesPanel(
      onPanelCollapsed: _onPanelCollapsed,
    );
  }


  void _handleKeyPress(KeyEvent event, GameProvider gameProvider) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      
      if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
        gameProvider.deleteLetter();
      } else if (key.keyLabel.length == 1 && RegExp(r'^[a-zA-ZçğıöşüÇĞIİÖŞÜ]$').hasMatch(key.keyLabel)) {
        gameProvider.inputLetter(key.keyLabel);
      } else if (key == LogicalKeyboardKey.arrowUp ||
                 key == LogicalKeyboardKey.arrowDown ||
                 key == LogicalKeyboardKey.arrowLeft ||
                 key == LogicalKeyboardKey.arrowRight) {
        _handleArrowKey(key, gameProvider);
      }
    }
  }

  void _handleArrowKey(LogicalKeyboardKey key, GameProvider gameProvider) {
    final selectedCell = gameProvider.gameState.selectedCell;
    if (selectedCell == null) return;

    int newRow = selectedCell.row;
    int newCol = selectedCell.col;
    Direction? preferredDirection;

    if (key == LogicalKeyboardKey.arrowUp) {
      newRow--;
      preferredDirection = Direction.vertical;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      newRow++;
      preferredDirection = Direction.vertical;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      newCol--;
      preferredDirection = Direction.horizontal;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      newCol++;
      preferredDirection = Direction.horizontal;
    }

    if (gameProvider.puzzle.isValidPosition(newRow, newCol)) {
      gameProvider.selectCell(newRow, newCol, preferredDirection: preferredDirection);
    }
  }


  Widget _buildElegantClueDisplay(GameProvider gameProvider) {
    final selectedWord = gameProvider.gameState.selectedWord;
    if (selectedWord == null) return const SizedBox();

    return Positioned(
      top: 78, // Closer to app bar
      left: 12,
      right: 12,
      child: IgnorePointer(
        ignoring: true, // Do not block game interactions beneath
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _gridLine, width: 1),
          boxShadow: [
            BoxShadow(
              color: _inkBlue.withOpacity(0.12),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Compact direction badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _vintageGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _vintageGold.withOpacity(0.3)),
              ),
              child: Text(
                '${selectedWord.number}${selectedWord.isHorizontal ? "Y" : "D"}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _vintageGold.withOpacity(0.9),
                  fontFamily: 'sans-serif',
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Compact clue text
            Expanded(
              child: Text(
                selectedWord.clue,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 13,
                  color: _inkBlue,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildInvisibleMobileInput(GameProvider gameProvider) {
    final hasSelectedCell = gameProvider.gameState.selectedCell != null;
    
    // Always show the TextField when a cell is selected to ensure focus can be gained
    if (!hasSelectedCell) {
      return const SizedBox.shrink();
    }
    
    // Ensure focus stays when a cell is selected (unless user dismissed)
    if (hasSelectedCell && !_mobileFocusNode.hasFocus && (!_userDismissedKeyboard || _panelJustCollapsed)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && gameProvider.gameState.selectedCell != null && (!_userDismissedKeyboard || _panelJustCollapsed)) {
          _mobileFocusNode.requestFocus();
          _panelJustCollapsed = false; // Reset flag after requesting focus
        }
      });
    }
    
    return Positioned(
      left: -100, // Move off-screen
      top: -100,
      child: SizedBox(
        width: 1,
        height: 1,
        child: TextField(
          controller: _mobileController,
          focusNode: _mobileFocusNode,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.characters,
          autofocus: false,
          enableInteractiveSelection: false,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(color: Colors.transparent, fontSize: 0.1),
          cursorColor: Colors.transparent,
          cursorWidth: 0,
          cursorHeight: 0,
          showCursor: false,
          maxLines: 1,
          decoration: const InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
            isCollapsed: true,
            isDense: true,
          ),
          onChanged: (text) {
            // New mobile backspace/letter handling using sentinel space
            if (_resettingMobileInput) {
              return;
            }
            if (text.isEmpty && _lastMobileText.isNotEmpty) {
              gameProvider.deleteLetter();
              _resettingMobileInput = true;
              Future.microtask(() {
                _mobileController.text = ' ';
                _mobileController.selection = const TextSelection.collapsed(offset: 1);
                _lastMobileText = ' ';
                _resettingMobileInput = false;
              });
              return;
            } else if (text.isNotEmpty) {
              final upper = toUpperTr(text);
              final reg = RegExp(r'[A-ZÇĞİÖŞÜ]');
              final matches = reg.allMatches(upper);
              if (matches.isNotEmpty) {
                final ch = matches.last.group(0)!;
                gameProvider.inputLetter(ch);
              }
              _resettingMobileInput = true;
              Future.microtask(() {
                _mobileController.text = ' ';
                _mobileController.selection = const TextSelection.collapsed(offset: 1);
                _lastMobileText = ' ';
                _resettingMobileInput = false;
              });
              return;
            }
            if (text.isEmpty && _mobileController.text.isNotEmpty) {
              // Handle backspace - when text becomes empty but controller had content
              gameProvider.deleteLetter();
            } else if (text.isNotEmpty) {
              // Accept Turkish letters and A-Z, map with Turkish-aware uppercasing
              final upper = toUpperTr(text);
              final matches = RegExp(r'[A-ZÇĞİÖŞÜ]').allMatches(upper);
              if (matches.isNotEmpty) {
                final ch = matches.last.group(0)!;
                gameProvider.inputLetter(ch);
              }
            }
            // Always clear to maintain clean state
            Future.microtask(() {
              if (_mobileController.text != ' ') {
                _mobileController.text = ' '; // Keep a space to detect backspace
                _mobileController.selection = TextSelection.fromPosition(
                  const TextPosition(offset: 1),
                );
              }
            });
          },
          // Remove global onTapOutside to avoid closing keyboard
          // when tapping another cell. Dismissal is handled by
          // grid empty-space taps and back/done actions.
          onEditingComplete: () {
            // Close the keyboard on OK/tick action
            _userDismissedKeyboard = true;
            if (_mobileFocusNode.hasFocus) {
              _mobileFocusNode.unfocus();
            }
          },
          onSubmitted: (text) {
            // Close the keyboard on OK/tick action
            _userDismissedKeyboard = true;
            if (_mobileFocusNode.hasFocus) {
              _mobileFocusNode.unfocus();
            }
          },
        ),
      ),
    );
  }


  void _showGameMenu(GameProvider gameProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: _cardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: _gridLine, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              // Handle bar
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: _gridLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Menu title
              Text(
                'Oyun Menüsü',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _inkBlue,
                  letterSpacing: 0.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Menu items
              _buildElegantMenuItem(
                context,
                icon: Icons.refresh_rounded,
                title: 'Yeni Oyun',
                subtitle: 'Baştan başla',
                onTap: () {
                  Navigator.pop(context);
                  gameProvider.newGame();
                },
              ),
              
              if (gameProvider.gameState.status == GameStatus.playing)
                _buildElegantMenuItem(
                  context,
                  icon: Icons.pause_rounded,
                  title: 'Oyunu Duraklat',
                  subtitle: 'Molaya çık',
                  onTap: () {
                    Navigator.pop(context);
                    gameProvider.pauseGame();
                  },
                ),
              
              if (gameProvider.gameState.status == GameStatus.paused)
                _buildElegantMenuItem(
                  context,
                  icon: Icons.play_arrow_rounded,
                  title: 'Oyunu Sürdür',
                  subtitle: 'Oyuna devam et',
                  onTap: () {
                    Navigator.pop(context);
                    gameProvider.resumeGame();
                  },
                ),
              
              _buildElegantMenuItem(
                context,
                icon: Icons.home_rounded,
                title: 'Ana Menü',
                subtitle: 'Oyundan çık',
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pop(context); // Go back to main menu
                },
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildElegantMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: _gridLine, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _vintageGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _vintageGold.withOpacity(0.3)),
                  ),
                  child: Icon(
                    icon,
                    color: _vintageGold,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _inkBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: _warmGray,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _warmGray,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleGlobalEmptyTap() {
    // User tapped outside any cell: clear selection and fully dismiss focus/keyboard
    _userDismissedKeyboard = true;
    FocusManager.instance.primaryFocus?.unfocus();
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.gameState.selectedCell != null) {
      gameProvider.deselectCell();
    }
  }
}
