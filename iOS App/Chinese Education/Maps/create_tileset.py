#!/usr/bin/env python3
"""
Create a simple tileset image for Tiled Map Editor
Combines individual tile images into a single tileset
"""

from PIL import Image
import os

# Tile size (64x64 pixels)
TILE_SIZE = 64

# Create a 4x1 tileset (4 tiles horizontally)
TILESET_WIDTH = TILE_SIZE * 4
TILESET_HEIGHT = TILE_SIZE

# Create the tileset image
tileset = Image.new('RGBA', (TILESET_WIDTH, TILESET_HEIGHT), (0, 0, 0, 0))

# Define tile positions and files
tiles = [
    ("grass_tile.png", 0),      # Position 0
    ("path_tile.png", 1),       # Position 1  
    ("water_tile.png", 2),      # Position 2
    ("stone_tile.png", 3)       # Position 3
]

# Load and paste each tile
for tile_file, position in tiles:
    tile_path = f"Tilesets/{tile_file}"
    if os.path.exists(tile_path):
        try:
            tile_img = Image.open(tile_path)
            # Resize to 64x64 if needed
            tile_img = tile_img.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
            
            # Paste at the correct position
            x = position * TILE_SIZE
            tileset.paste(tile_img, (x, 0))
            print(f"✅ Added {tile_file} at position {position}")
        except Exception as e:
            print(f"❌ Error loading {tile_file}: {e}")
    else:
        print(f"❌ File not found: {tile_path}")

# Save the tileset
tileset_path = "Tilesets/basic_tileset.png"
tileset.save(tileset_path)
print(f"✅ Tileset saved: {tileset_path}")

# Create a simple .tsx file for Tiled
tsx_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.10.2" name="basic_tileset" tilewidth="{TILE_SIZE}" tileheight="{TILE_SIZE}" tilecount="4" columns="4">
 <image source="basic_tileset.png" width="{TILESET_WIDTH}" height="{TILESET_HEIGHT}"/>
 <tile id="0">
  <properties>
   <property name="type" value="grass"/>
  </properties>
 </tile>
 <tile id="1">
  <properties>
   <property name="type" value="path"/>
  </properties>
 </tile>
 <tile id="2">
  <properties>
   <property name="type" value="water"/>
  </properties>
 </tile>
 <tile id="3">
  <properties>
   <property name="type" value="stone"/>
  </properties>
 </tile>
</tileset>'''

with open("Tilesets/basic_tileset.tsx", "w") as f:
    f.write(tsx_content)

print("✅ Tileset definition saved: Tilesets/basic_tileset.tsx")
