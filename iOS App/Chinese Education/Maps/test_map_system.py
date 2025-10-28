#!/usr/bin/env python3
"""
Test script to verify the modern map system setup
"""

import os
import sys

def test_file_exists(filepath, description):
    """Test if a file exists and report status"""
    if os.path.exists(filepath):
        size = os.path.getsize(filepath)
        print(f"✅ {description}: {filepath} ({size} bytes)")
        return True
    else:
        print(f"❌ {description}: {filepath} - NOT FOUND")
        return False

def main():
    print("🧪 Testing Modern Map System Setup")
    print("=" * 50)
    
    base_path = "/Users/jackkohk/Desktop/Chinese Edu/chinese_education/iOS App/Chinese Education/Maps"
    
    # Test map files
    map_files = [
        ("level_1.tmx", "Level 1 Map"),
        ("level_2.tmx", "Level 2 Map"),
        ("level_3.tmx", "Level 3 Map")
    ]
    
    # Test tileset files
    tileset_files = [
        ("Tilesets/basic_tileset.png", "Basic Tileset Image"),
        ("Tilesets/basic_tileset.tsx", "Basic Tileset Definition"),
        ("Tilesets/grass_tile.png", "Grass Tile"),
        ("Tilesets/path_tile.png", "Path Tile"),
        ("Tilesets/water_tile.png", "Water Tile"),
        ("Tilesets/stone_tile.png", "Stone Tile"),
        ("Tilesets/tree_tile.png", "Tree Tile")
    ]
    
    # Test Swift files
    swift_files = [
        ("../MapManager.swift", "MapManager Class"),
        ("../GameScene.swift", "GameScene with Modern Map Support")
    ]
    
    all_passed = True
    
    print("\n📁 Map Files:")
    for filename, description in map_files:
        filepath = os.path.join(base_path, filename)
        if not test_file_exists(filepath, description):
            all_passed = False
    
    print("\n🎨 Tileset Files:")
    for filename, description in tileset_files:
        filepath = os.path.join(base_path, filename)
        if not test_file_exists(filepath, description):
            all_passed = False
    
    print("\n💻 Swift Files:")
    for filename, description in swift_files:
        filepath = os.path.join(base_path, filename)
        if not test_file_exists(filepath, description):
            all_passed = False
    
    print("\n" + "=" * 50)
    if all_passed:
        print("🎉 ALL TESTS PASSED! Modern Map System is ready for testing.")
        print("\n📋 Next Steps:")
        print("1. Build and run the iOS app")
        print("2. Look for the '🗺️ 原始地圖' toggle button")
        print("3. Tap it to switch to '🗺️ 現代地圖'")
        print("4. Test the level selector with '🎮 選擇關卡'")
        print("5. Verify different map layouts and animations")
    else:
        print("❌ Some tests failed. Please check the missing files.")
        sys.exit(1)

if __name__ == "__main__":
    main()
