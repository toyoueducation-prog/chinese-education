# 🗺️ Modern Map System - Implementation Guide

## Overview
This modern map system provides a professional, industry-standard approach to game map management using Tiled Map Editor (.tmx files) with layered rendering, animated tiles, multiple levels, and centralized management.

## 🎯 Features Implemented

### ✅ Core Features
- **Parallel System**: Works alongside original character-array system
- **TMX File Support**: Loads maps from Tiled Map Editor .tmx files
- **Layered Rendering**: Ground, water, decoration, and collision layers
- **Animated Tiles**: Water ripples and grass sway animations
- **Multiple Levels**: 3 different levels with progression system
- **Level Selection**: UI for choosing between available levels
- **Parallax Backgrounds**: Depth with layered background scrolling
- **Collision System**: Physics-based collision from tile data
- **Spawn Points**: Player and enemy spawn management
- **Toggle System**: Switch between old and new systems

### 🎮 UI Features
- **Map System Toggle**: "🗺️ 原始地圖" ↔ "🗺️ 現代地圖"
- **Level Selector**: "🎮 選擇關卡" with unlock progression
- **Visual Feedback**: Clear indicators for current system and available levels

## 📁 File Structure

```
Maps/
├── level_1.tmx          # Level 1: 新手村 (Beginner Village)
├── level_2.tmx          # Level 2: 森林區 (Forest Area)  
├── level_3.tmx          # Level 3: 水晶洞 (Crystal Cave)
├── Tilesets/
│   ├── basic_tileset.png    # Combined tileset image
│   ├── basic_tileset.tsx    # Tileset definition
│   ├── grass_tile.png       # Individual grass tile
│   ├── path_tile.png        # Individual path tile
│   ├── water_tile.png       # Individual water tile
│   ├── stone_tile.png       # Individual stone tile
│   └── tree_tile.png        # Individual tree tile
├── create_tileset.py        # Script to create tileset
├── test_map_system.py       # Test script
└── README.md                # This file
```

## 🚀 How to Use

### 1. Testing the System
1. **Build and run** the iOS app
2. **Look for the toggle button** "🗺️ 原始地圖" in the bottom-left area
3. **Tap the toggle** to switch to "🗺️ 現代地圖" (restarts scene)
4. **Test level selector** with "🎮 選擇關卡" button
5. **Verify features**:
   - Different map layouts for each level
   - Animated water tiles
   - Parallax background scrolling
   - Collision system working
   - Enemy spawning at correct positions

### 2. Creating New Maps
1. **Open Tiled Map Editor** (free download from mapeditor.org)
2. **Create new map**: 20x20 tiles, 64x64 tile size
3. **Add layers**:
   - `ground_layer`: Base terrain (grass, paths, stone)
   - `water_layer`: Animated water tiles
   - `decoration_layer`: Trees, rocks, visual objects
   - `collision_layer`: Invisible collision tiles
4. **Add object layers**:
   - `spawn_points`: Player and enemy spawn points
   - `interactive_objects`: Portals, treasure chests, signs
5. **Export as .tmx** and add to Xcode project

### 3. Adding New Levels
1. **Create .tmx file** following the structure above
2. **Add to MapManager.swift** in `availableMaps` array:
   ```swift
   MapInfo(name: "level_4", displayName: "新關卡", unlockLevel: 15, spawnPoint: CGPoint(x: 640, y: 640), enemyCount: 8, fileName: "level_4.tmx")
   ```
3. **Update level unlock requirements** as needed

## 🔧 Technical Details

### MapManager Class
- **Singleton pattern** for centralized map management
- **TMX parser** with XMLParserDelegate for .tmx file loading
- **Fallback system** creates maps from existing assets if .tmx fails
- **Caching system** stores loaded maps for performance
- **Spawn point management** for players and enemies

### GameScene Integration
- **Parallel system** runs alongside original map system
- **Toggle functionality** switches between systems
- **UI integration** with level selector and system toggle
- **Parallax scrolling** for background depth
- **Collision setup** from tile data

### Animation System
- **Water tiles**: Alternating between water.png and water_original.png
- **Grass tiles**: Subtle sway animation
- **Parallax backgrounds**: Different scroll factors for depth

## 🎨 Visual Features

### Layered Rendering
- **Ground Layer** (z: -10): Base terrain tiles
- **Water Layer** (z: -9): Animated water with ripples
- **Decoration Layer** (z: 0): Trees and visual objects
- **Collision Layer**: Invisible physics bodies

### Parallax Backgrounds
- **Sky Layer** (scroll: 0.1): Slowest moving background
- **Cloud Layer** (scroll: 0.3): Medium speed clouds
- **Mountain Layer** (scroll: 0.5): Faster moving mountains

### Tile Animations
- **Water**: 0.5s frame rate with alternating textures
- **Grass**: 2s sway cycle with subtle rotation
- **Backgrounds**: Smooth parallax scrolling

## 🐛 Troubleshooting

### Common Issues
1. **Map not loading**: Check .tmx file is in Xcode project
2. **Tiles not showing**: Verify tileset images are in Assets.xcassets
3. **Collision not working**: Check collision layer has tile ID 3 (stone)
4. **Animations not playing**: Ensure texture names match exactly

### Debug Information
- **Console logs** show map loading status
- **Toggle button** shows current system
- **Level selector** shows available levels
- **Test script** verifies all files exist

## 🔄 Migration Path

### Phase 1: Parallel Testing (Current)
- Both systems work simultaneously
- Toggle between them for testing
- Verify all features work correctly

### Phase 2: Full Migration
- Remove original character-array system
- Set modern system as default
- Clean up old code

### Phase 3: Enhancement
- Add more tile types and animations
- Implement advanced Tiled features
- Add more level variety

## 📊 Performance Benefits

- **Memory efficient**: Only loads visible tiles
- **Cached maps**: Avoids reloading same maps
- **Optimized rendering**: Proper z-positioning
- **Smooth animations**: Hardware-accelerated tile animations

## 🎯 Future Enhancements

- **SKTiled integration** for full .tmx feature support
- **Auto-tiling** for seamless tile transitions
- **More tile types** with varied animations
- **Interactive objects** from object layers
- **Map transitions** with smooth animations
- **Procedural generation** for infinite maps

---

**Status**: ✅ Ready for Testing  
**Last Updated**: October 2024  
**Version**: 1.0.0
