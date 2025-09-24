import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../screens/game_screen.dart';
import '../models/difficulty_level.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  DifficultyLevel _selectedDifficulty = DifficultyLevel.medium;

  // Design Constants
  static const Color _paperWhite = Color(0xFFFEFCF7);
  static const Color _inkBlue = Color(0xFF2C3E50);
  static const Color _vintageGold = Color(0xFFD4AF37);
  static const Color _warmGray = Color(0xFF5D6D7E);
  static const Color _gridLine = Color(0xFFE8E4DC);
  static const Color _cardSurface = Color(0xFFF8F6F0);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: _paperWhite,
      body: Container(
        decoration: _buildGridBackground(),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 48.0 : 24.0,
              vertical: isTablet ? 32.0 : 20.0,
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    (isTablet ? 64.0 : 40.0), // Subtract padding
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Header Section
                      Flexible(
                        flex: 3,
                        fit: FlexFit.loose,
                        child: _buildHeaderSection(isSmallScreen, isTablet),
                      ),

                      // Difficulty Selection
                      Flexible(
                        flex: 2,
                        fit: FlexFit.loose,
                        child: _buildDifficultySelection(isSmallScreen, isTablet),
                      ),

                      SizedBox(height: isTablet ? 24 : 16),

                      // Main Action Button
                      Flexible(
                        flex: 2,
                        fit: FlexFit.loose,
                        child: Center(
                          child: _buildPrimaryButton(
                            context,
                            isSmallScreen,
                            isTablet,
                          ),
                        ),
                      ),

                      SizedBox(height: isTablet ? 24 : 16),

                      // Secondary Actions
                      Flexible(
                        fit: FlexFit.loose,
                        child: _buildSecondaryActions(context, isSmallScreen, isTablet),
                      ),

                      SizedBox(height: isTablet ? 40 : 24),

                      // Elegant Footer
                      Flexible(
                        fit: FlexFit.loose,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _buildFooter(isSmallScreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Grid background decoration for crossword theme
  BoxDecoration _buildGridBackground() {
    return const BoxDecoration(
      color: _paperWhite,
      // Simple gradient for paper texture effect
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

  // Header section with elegant title
  Widget _buildHeaderSection(bool isSmallScreen, bool isTablet) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decorative top border
          Container(
            width: isTablet ? 200 : 150,
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_vintageGold, Colors.transparent, _vintageGold],
              ),
            ),
          ),
          
          SizedBox(height: isTablet ? 24 : 16),
          
          // Main title with classic typography
          Text(
            'Çengel Bulmaca',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: isSmallScreen ? 32 : (isTablet ? 48 : 40),
              fontWeight: FontWeight.bold,
              color: _inkBlue,
              letterSpacing: 2.0,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isTablet ? 16 : 12),
          
          // Subtitle with classic newspaper feel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gridLine, width: 1),
            ),
            child: Text(
              'Klasik Kelime Bulmacası',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: isSmallScreen ? 14 : 16,
                color: _warmGray,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(height: isTablet ? 24 : 16),
          
          // Bottom decorative border
          Container(
            width: isTablet ? 200 : 150,
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_vintageGold, Colors.transparent, _vintageGold],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Primary action button with premium design
  Widget _buildPrimaryButton(BuildContext context, bool isSmallScreen, bool isTablet) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isTablet ? 400 : 320,
        minHeight: isSmallScreen ? 70 : 80,
      ),
      child: ElevatedButton(
        onPressed: () => _startNewGame(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _inkBlue,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: _inkBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _vintageGold, width: 2),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 48 : 32,
            vertical: isTablet ? 20 : 16,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: _vintageGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: _inkBlue,
                size: 18,
              ),
            ),
            
            SizedBox(width: isTablet ? 16 : 12),
            
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OYUNA BAŞLA',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : (isTablet ? 22 : 20),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'Yeni bulmaca çöz',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Secondary actions with refined styling
  Widget _buildSecondaryActions(BuildContext context, bool isSmallScreen, bool isTablet) {
    return Column(
      children: [
        // Settings button
        Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 300 : 250,
          ),
          child: OutlinedButton(
            onPressed: () => _showSettings(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _inkBlue,
              side: const BorderSide(color: _gridLine, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 24,
                vertical: isTablet ? 16 : 12,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: _warmGray,
                ),
                
                SizedBox(width: isTablet ? 12 : 8),
                
                Text(
                  'Ayarlar',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: _warmGray,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: isTablet ? 16 : 12),
        
        // Statistics button (placeholder)
        Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 300 : 250,
          ),
          child: TextButton(
            onPressed: () => _showStatistics(context),
            style: TextButton.styleFrom(
              foregroundColor: _warmGray,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 24,
                vertical: isTablet ? 12 : 8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bar_chart_outlined,
                  size: 18,
                ),
                
                SizedBox(width: isTablet ? 12 : 8),
                
                Text(
                  'İstatistikler',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Elegant footer
  Widget _buildFooter(bool isSmallScreen) {
    return Column(
      children: [
        // Divider line
        Container(
          width: 60,
          height: 1,
          color: _gridLine,
          margin: const EdgeInsets.only(bottom: 16),
        ),
        
        Text(
          'Geleneksel bulmaca deneyimi',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: isSmallScreen ? 12 : 14,
            color: _warmGray.withOpacity(0.8),
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Difficulty selection widget
  Widget _buildDifficultySelection(bool isSmallScreen, bool isTablet) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isTablet ? 500 : 350,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Zorluk Seviyesi',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: isSmallScreen ? 16 : (isTablet ? 20 : 18),
              fontWeight: FontWeight.w600,
              color: _inkBlue,
              letterSpacing: 0.5,
            ),
          ),

          SizedBox(height: isTablet ? 16 : 12),

          Container(
            decoration: BoxDecoration(
              color: _cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gridLine, width: 1),
              boxShadow: [
                BoxShadow(
                  color: _inkBlue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 8),
              child: isSmallScreen
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: DifficultyLevel.values.map((level) {
                      final isSelected = _selectedDifficulty == level;
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDifficulty = level),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? _inkBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? _vintageGold : _gridLine,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  level.displayName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : _inkBlue,
                                  ),
                                ),
                                Text(
                                  '${level.maxWords} kelime • ${level.gridSize}x${level.gridSize}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white.withOpacity(0.9) : _warmGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: DifficultyLevel.values.map((level) {
                      final isSelected = _selectedDifficulty == level;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDifficulty = level),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 12 : 10,
                              horizontal: isTablet ? 16 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? _inkBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? _vintageGold : _gridLine,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  level.displayName,
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : _inkBlue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${level.maxWords} kelime\n${level.gridSize}x${level.gridSize}',
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 10,
                                    color: isSelected ? Colors.white.withOpacity(0.9) : _warmGray,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            ),
          ),

          SizedBox(height: isTablet ? 12 : 8),

          Text(
            _selectedDifficulty.description,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: _warmGray,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Action methods
  void _startNewGame(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.newGameWithDifficulty(_selectedDifficulty);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GameScreen()),
    );
  }

  void _showSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ayarlar ekranı geliştiriliyor...'),
        backgroundColor: _inkBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('İstatistikler ekranı geliştiriliyor...'),
        backgroundColor: _warmGray,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}


