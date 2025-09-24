# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cruci Verba is a Turkish crossword puzzle game built with Flutter. The app generates dynamic crosswords from a Turkish word database and provides an interactive solving experience.

## Development Commands

### Build and Run
```bash
flutter run                    # Run app in development mode
flutter build apk             # Build Android APK
flutter build ios             # Build iOS app (requires macOS)
```

### Analysis and Testing
```bash
flutter analyze               # Run static analysis with linter
flutter test                  # Run unit tests
dart format lib/              # Format Dart code
```

### Dependencies
```bash
flutter pub get              # Install dependencies
flutter pub upgrade          # Update dependencies
```

## Architecture Overview

### State Management
- Uses **Provider pattern** with `ChangeNotifier`
- Main state handled by `GameProvider` (`lib/providers/game_provider.dart`)
- Game state includes puzzle data, timer, selection, and user input

### Core Services
- **CrosswordGeneratorService**: Generates puzzles using existing crossword algorithm
- **CrosswordDatabaseService**: Manages Turkish word database from JSON files
- Uses original crossword generation algorithm from `lib/classes/CrossWord.dart`

### Data Models
- **CrosswordPuzzle**: Main puzzle data structure with grid and clues
- **Cell**: Individual grid cell with letter, user input, and state
- **WordClue**: Word definition with position, direction, and clue text
- **GameState**: Complete game state including timer and selection

### Key Features
- Dynamic crossword generation from Turkish word database
- Interactive grid with cell selection and input
- Horizontal/vertical word direction handling
- Turkish character support with proper casing utilities
- Timer and game progress tracking
- Hint system with letter revelation

### File Structure
- `/lib/screens/` - UI screens (main menu, game screen)
- `/lib/widgets/` - Reusable UI components (grid, clues panels)
- `/lib/providers/` - State management
- `/lib/services/` - Business logic and data services
- `/lib/models/` - Data structures
- `/lib/utils/` - Utilities (Turkish casing, etc.)
- `/assets/data/` - Word database JSON files

### Data Sources
- Word database: `assets/data/crossword_db_optimized.json`
- Contains Turkish words with meanings for clue generation

## Theme and Styling
- Uses custom Material theme with newspaper-inspired design
- Colors: Ink blue (#2C3E50), vintage gold (#D4AF37), paper white backgrounds
- Typography: Serif fonts for classic crossword appearance