import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/cell.dart';
import '../utils/turkish_casing.dart';

class CrosswordGrid extends StatefulWidget {
  final VoidCallback? onEmptySpaceTap;

  const CrosswordGrid({Key? key, this.onEmptySpaceTap}) : super(key: key);

  @override
  State<CrosswordGrid> createState() => _CrosswordGridState();
}

class _CrosswordGridState extends State<CrosswordGrid> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  String? _lastSelectedWordKey; // Track last selected word to avoid unnecessary animations
  static const double _padding = 8.0;
  double? _cellSize; // computed dynamically based on available size
  // Live layout metrics for accurate hit-testing (tap empty vs cell)
  double _gridOffsetX = 0.0;
  double _gridOffsetY = 0.0;
  double _gridWidth = 0.0;
  double _gridHeight = 0.0;
  static const double _minScale = 0.5;
  static const double _maxScale = 3.0;

  late final AnimationController _animationController;
  Matrix4Tween? _matrixTween;
  final Curve _animationCurve = Curves.easeInOutCubic;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))
      ..addListener(() {
        if (_matrixTween != null) {
          final t = _animationCurve.transform(_animationController.value);
          _transformationController.value = _matrixTween!.transform(t);
        }
      });
  }

  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _fitGridToScreen() {
    // Fit the entire grid to screen with padding
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewportSize = renderBox.size;
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;

    // Reset to identity matrix with smooth animation
    _matrixTween = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity()
    );
    _animationController.forward(from: 0.0);
  }

  void _scrollToSelectedWord(GameProvider gameProvider) {
    final selectedWord = gameProvider.gameState.selectedWord;
    if (selectedWord == null) return;

    // Get viewport dimensions
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final viewportSize = renderBox.size;
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;

    // Compute keyboard occlusion for this widget (portion covered by soft keyboard)
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardInset = mediaQuery.viewInsets.bottom; // keyboard height
    double occludedHeight = 0.0;
    if (keyboardInset > 0) {
      final widgetTop = renderBox.localToGlobal(Offset.zero).dy;
      final widgetBottom = widgetTop + viewportSize.height;
      final keyboardTop = screenHeight - keyboardInset;
      occludedHeight = (widgetBottom - keyboardTop).clamp(0.0, viewportSize.height);
    }

    // Build an animation key that changes when occlusion/size changes
    final wordKey = '${selectedWord.number}_${selectedWord.isHorizontal}_${occludedHeight.round()}_${viewportSize.width.round()}x${viewportSize.height.round()}';
    if (wordKey == _lastSelectedWordKey) return; // Avoid duplicate animations

    _lastSelectedWordKey = wordKey;

    // Recompute layout similar to build() to get precise sizes and centering offsets
    final puzzle = gameProvider.puzzle;
    final availableWidth = viewportSize.width - _padding * 2;
    final availableHeight = viewportSize.height - _padding * 2;
    final targetAspect = puzzle.cols / puzzle.rows;
    double gridWidth = availableWidth;
    double gridHeight = gridWidth / targetAspect;
    if (gridHeight > availableHeight) {
      gridHeight = availableHeight;
      gridWidth = gridHeight * targetAspect;
    }

    // Determine cell size and the grid paint offset within the container (centered + padding)
    final cellSize = (gridWidth / puzzle.cols);
    final offsetX = _padding + (availableWidth - gridWidth) / 2.0;
    final offsetY = _padding + (availableHeight - gridHeight) / 2.0;

    // Calculate word center position in container pixel coordinates
    final startRow = selectedWord.startRow;
    final startCol = selectedWord.startCol;
    final endRow = selectedWord.isHorizontal ? startRow : startRow + selectedWord.length - 1;
    final endCol = selectedWord.isHorizontal ? startCol + selectedWord.length - 1 : startCol;
    
    // Word bounds
    final wordCenterRow = (startRow + endRow) / 2;
    final wordCenterCol = (startCol + endCol) / 2;
    
    // Convert to pixel coordinates within the InteractiveViewer child (include padding + centering offsets)
    final wordCenterX = offsetX + wordCenterCol * cellSize + cellSize / 2;
    final wordCenterY = offsetY + wordCenterRow * cellSize + cellSize / 2;
    
    // Calculate word dimensions for zoom calculation
    final wordWidth = (endCol - startCol + 1) * cellSize;
    final wordHeight = (endRow - startRow + 1) * cellSize;
    
    // Fit scale so the entire word is visible with some padding (add ~1 cell margin around the word)
    const double extraCellsPadding = 1.0; // add one cell on each side
    final paddedWordWidth = wordWidth + extraCellsPadding * 2 * cellSize;
    final paddedWordHeight = wordHeight + extraCellsPadding * 2 * cellSize;

    // Use 90% of viewport to leave edges visible
    final scaleX = (viewportSize.width * 0.9) / paddedWordWidth;
    final effectiveHeight = (viewportSize.height - occludedHeight).clamp(1.0, viewportSize.height);
    final scaleY = (effectiveHeight * 0.9) / paddedWordHeight;
    double targetScale = (scaleX < scaleY ? scaleX : scaleY).clamp(_minScale, _maxScale);
    
    // Calculate viewport center
    final viewportCenterX = viewportSize.width / 2;
    final viewportCenterY = effectiveHeight / 2; // center within the visible region (above keyboard)
    
    // Calculate translation needed to center the word
    final translateX = viewportCenterX - (wordCenterX * targetScale);
    final translateY = viewportCenterY - (wordCenterY * targetScale);
    
    // Build target transformation matrix (scale then translate)
    final targetMatrix = Matrix4.identity()
      ..scale(targetScale, targetScale)
      ..setTranslationRaw(translateX, translateY, 0.0);

    // Animate smoothly to target
    _matrixTween = Matrix4Tween(begin: _transformationController.value, end: targetMatrix);
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final puzzle = gameProvider.puzzle;
        final gameState = gameProvider.gameState;
        
        // Auto-scroll to selected word after build completes
        if (gameState.selectedWord != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToSelectedWord(gameProvider);
          });
        } else {
          _lastSelectedWordKey = null; // Reset when no word is selected
        }
        
        if (puzzle.rows == 0 || puzzle.cols == 0) {
          return const Center(
            child: Text('No puzzle loaded'),
          );
        }

        return GestureDetector(
          onDoubleTap: () {
            // Double tap to fit grid to screen
            _fitGridToScreen();
          },
          child: Listener(
            onPointerUp: (PointerUpEvent event) {
              // Convert global position to local position relative to the scene
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(event.position);
              final scenePosition = _transformationController.toScene(localPosition);

              // Check if the tap is on an empty area (not on a crossword cell)
              if (_isEmptySpaceTap(scenePosition, puzzle)) {
                final gameProvider = Provider.of<GameProvider>(context, listen: false);
                gameProvider.deselectCell();
                // Inform parent screen to dismiss keyboard and clear focus completely
                if (widget.onEmptySpaceTap != null) {
                  widget.onEmptySpaceTap!.call();
                } else {
                  // Fallback in case callback isn't provided
                  FocusScope.of(context).unfocus();
                }
              }
            },
            child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(8.0),
            minScale: _minScale,
            maxScale: _maxScale,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(_padding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth - _padding * 2;
                  final availableHeight = constraints.maxHeight - _padding * 2;
                  final targetAspect = puzzle.cols / puzzle.rows;
                  double width = availableWidth;
                  double height = width / targetAspect;
                  if (height > availableHeight) {
                    height = availableHeight;
                    width = height * targetAspect;
                  }

                  // Compute and store dynamic cell size for interactions
                  _cellSize = width / puzzle.cols;
                  // Store live grid bounds within the InteractiveViewer child
                  _gridWidth = width;
                  _gridHeight = height;
                  _gridOffsetX = _padding + (availableWidth - width) / 2.0;
                  _gridOffsetY = _padding + (availableHeight - height) / 2.0;

                  return SizedBox(
                    width: width,
                    height: height,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: puzzle.cols,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 1.0,
                        mainAxisSpacing: 1.0,
                      ),
                      itemCount: puzzle.rows * puzzle.cols,
                      itemBuilder: (context, index) {
                        final row = index ~/ puzzle.cols;
                        final col = index % puzzle.cols;
                        final cell = puzzle.getCellAt(row, col);

                        if (cell == null || cell.isHidden) {
                          return Container(
                            color: Colors.transparent,
                            // Empty container allows parent tap to go through
                          );
                        }

                        return CrosswordCell(
                          key: ValueKey('cell-$row-$col'),
                          cell: cell,
                          row: row,
                          col: col,
                          isSelected: gameState.isCellSelected(row, col),
                          isInSelectedWord: gameState.isCellInSelectedWord(row, col),
                          isTaken: gameState.takenLetters['$row,$col'] == true,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  bool _isEmptySpaceTap(Offset position, puzzle) {
    // Use live layout metrics (account for center offsets and padding)
    final cellSize = _cellSize ?? 0.0;
    if (cellSize <= 0) return true;

    // Check if tap is outside the drawn grid rectangle
    if (position.dx < _gridOffsetX ||
        position.dy < _gridOffsetY ||
        position.dx > _gridOffsetX + _gridWidth ||
        position.dy > _gridOffsetY + _gridHeight) {
      return true;
    }

    // Map tap position to cell coordinates
    final cellX = ((position.dx - _gridOffsetX) / cellSize).floor();
    final cellY = ((position.dy - _gridOffsetY) / cellSize).floor();

    // Check bounds
    if (cellX < 0 || cellX >= puzzle.cols || cellY < 0 || cellY >= puzzle.rows) {
      return true;
    }

    // Check if the cell is empty/hidden
    final cell = puzzle.getCellAt(cellY, cellX);
    return cell == null || cell.isHidden;
  }
  
  // Removed unsafe ancestor state traversal; use onEmptySpaceTap callback
  // from parent screen to handle keyboard dismissal. If not provided,
  // callers locally unfocus via FocusScope.
}

class CrosswordCell extends StatefulWidget {
  final Cell cell;
  final int row;
  final int col;
  final bool isSelected;
  final bool isInSelectedWord;
  final bool isTaken;

  const CrosswordCell({
    Key? key,
    required this.cell,
    required this.row,
    required this.col,
    required this.isSelected,
    required this.isInSelectedWord,
    required this.isTaken,
  }) : super(key: key);

  @override
  State<CrosswordCell> createState() => _CrosswordCellState();
}

class _CrosswordCellState extends State<CrosswordCell> with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      value: 0.0,
    );
    if (widget.isInSelectedWord) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CrosswordCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInSelectedWord && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (!widget.isInSelectedWord && _glowController.isAnimating) {
      _glowController.stop();
      _glowController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        // Ensure minimum touch target of 44px
        final adjustedSize = size < 44.0 ? 44.0 : size;
        final letterFont = adjustedSize * 0.62; // classic: large, clear
        final numberFont = adjustedSize * 0.20; // slightly smaller for better hierarchy
        // Border styling - calculated but currently not used in the design
        // final selectedBorderW = (adjustedSize * 0.08).clamp(2.0, 4.0);
        // final inWordBorderW = (adjustedSize * 0.04).clamp(1.0, 2.0);
        // final hasBorder = widget.isSelected || widget.isInSelectedWord;
        // final borderWidth = widget.isSelected ? selectedBorderW : inWordBorderW;

        // Green pulsing glow on selected word
        final green = const Color(0xFF2ECC71); // emerald green
        final inWord = widget.isInSelectedWord;

        return GestureDetector(
          onTap: () {
            if (!widget.cell.isBlocked && !widget.cell.isEmpty && !widget.cell.isHidden) {
              // Add haptic feedback for cell selection
              HapticFeedback.selectionClick();
              final gameProvider = Provider.of<GameProvider>(context, listen: false);
              gameProvider.selectCell(widget.row, widget.col);
            }
          },
          onLongPress: () {
            if (!widget.cell.isBlocked && !widget.cell.isEmpty && !widget.cell.isHidden && widget.cell.hasUserInput && !widget.isTaken) {
              // Add stronger haptic feedback for letter taking
              HapticFeedback.lightImpact();
              final gameProvider = Provider.of<GameProvider>(context, listen: false);
              gameProvider.takeLetter(widget.row, widget.col);
            }
          },
          child: AnimatedScale(
            scale: widget.isSelected ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                final t = Curves.easeInOutSine.transform(_glowController.value); // 0..1 eased
                // Smoother, slightly faster pulse with lighter cost
                final glowOpacity = inWord ? (0.18 + 0.22 * t) : 0.0; // up to ~0.40
                final glowBlur = inWord ? size * (0.20 + 0.24 * t) : 0.0;  // moderate blur
                final glowSpread = inWord ? size * (0.02 + 0.04 * t) : 0.0; // moderate spread
                final pulseWidth = (size * 0.05).clamp(1.0, 2.5);
                // Background pulse (slight tint change)
                final baseFill = _getCellColor();
                final fillColor = inWord
                    ? Color.lerp(Colors.grey.shade100, Colors.grey.shade300, t * 0.6)!
                    : baseFill;

                return RepaintBoundary(
                  child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Outer glow behind the cell
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: inWord
                            ? [
                                // Primary glow
                                BoxShadow(
                                  color: green.withOpacity(glowOpacity),
                                  blurRadius: glowBlur,
                                  spreadRadius: glowSpread,
                                ),
                                // Secondary softer halo further out
                                BoxShadow(
                                  color: green.withOpacity(0.10 + 0.18 * t),
                                  blurRadius: glowBlur * 1.6,
                                  spreadRadius: glowSpread * 1.4,
                                ),
                              ]
                            : [],
                      ),
                    ),
                    // Base panel (fill + normal border)
                    Container(
                      decoration: BoxDecoration(
                        color: fillColor,
                        border: Border.all(
                          color: _getBorderColor(),
                          width: _getBorderWidth(),
                        ),
                      ),
                    ),
                    // Pulsing green border overlay for selected word
                    if (inWord)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: green.withOpacity(0.20 + 0.35 * t),
                                width: pulseWidth,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Foreground content (numbers + letter)
                    Stack(
                       children: [
                        if (widget.cell.isStartOfWord)
                          Positioned(
                            top: size * 0.06,
                            left: size * 0.06,
                            child: Text(
                              '${widget.cell.number}',
                              style: TextStyle(
                                fontSize: numberFont,
                                fontWeight: FontWeight.w600,
                                color: _getNumberColor(),
                                height: 1.0,
                              ),
                            ),
                          ),
                        if (!widget.cell.isBlocked && !widget.cell.isEmpty)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                _getDisplayText(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: letterFont,
                                  fontWeight: FontWeight.w800, // Increased for better readability
                                  color: _getTextColor(),
                                  height: 1.0,
                                  letterSpacing: adjustedSize * 0.01,
                                  shadows: [
                                    // Add subtle shadow for better contrast
                                    Shadow(
                                      offset: const Offset(0.5, 0.5),
                                      blurRadius: 1.0,
                                      color: Colors.black.withOpacity(0.1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ));
              },
            ),
          ),
        );
      },
    );
  }

  Color _getCellColor() {
    if (widget.cell.isBlocked) {
      return Colors.black;
    } else if (widget.isSelected) {
      return Colors.grey.shade300; // neutral selection background (no blue)
    } else if (widget.isInSelectedWord) {
      return Colors.grey.shade100; // subtle word background
    } else if (widget.cell.hasUserInput) {
      if (widget.cell.isCorrect) {
        return widget.isTaken ? const Color(0xFFD4AF37).withOpacity(0.3) : Colors.white; // Golden color for taken letters
      } else {
        return Colors.red.shade50;
      }
    } else {
      return Colors.white;
    }
  }

  Color _getBorderColor() {
    if (widget.cell.isBlocked) {
      return Colors.black;
    } else if (widget.isSelected) {
      return const Color(0xFF27AE60); // dark green for selected cell
    } else if (widget.isInSelectedWord) {
      return const Color(0xFF2ECC71); // mid green for selected word
    } else {
      return Colors.grey.shade400;
    }
  }

  double _getBorderWidth() {
    if (widget.isSelected) {
      return 3.0;
    } else if (widget.isInSelectedWord) {
      return 2.0;
    } else {
      return 1.0;
    }
  }

  Color _getTextColor() {
    if (widget.isTaken) {
      return const Color(0xFFD4AF37); // Golden color for taken letters
    } else if (widget.cell.hasUserInput && !widget.cell.isCorrect) {
      return Colors.red.shade800;
    } else {
      return Colors.black87;
    }
  }

  Color _getNumberColor() {
    return Colors.black54;
  }

  String _getDisplayText() {
    if (widget.cell.hasUserInput) {
      return toUpperTr(widget.cell.userInput!);
    } else {
      return '';
    }
  }
}
