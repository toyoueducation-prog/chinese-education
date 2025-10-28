import SpriteKit
import Foundation

// MARK: - 🗺️ MAP MANAGER - Modern Map System (Parallel Implementation)
class MapManager {
    static let shared = MapManager()
    
    // MARK: - 🎯 MAP SYSTEM CONFIGURATION
    private var useModernMapSystem: Bool = false  // Toggle between old and new systems
    private var currentMapName: String = "level_1"
    private var currentTileMap: SKTileMapNode?
    private var loadedMaps: [String: SKTileMapNode] = [:]
    
    // MARK: - 📋 MAP METADATA STRUCTURE
    struct MapInfo {
        let name: String
        let displayName: String
        let unlockLevel: Int
        let spawnPoint: CGPoint
        let enemyCount: Int
        let fileName: String
    }
    
    // MARK: - 🗺️ AVAILABLE MAPS CATALOG
    private let availableMaps: [MapInfo] = [
        MapInfo(name: "level_1", displayName: "新手村", unlockLevel: 0, spawnPoint: CGPoint(x: 640, y: 640), enemyCount: 2, fileName: "level_1.tmx"),
        MapInfo(name: "level_2", displayName: "森林區", unlockLevel: 5, spawnPoint: CGPoint(x: 640, y: 640), enemyCount: 4, fileName: "level_2.tmx"),
        MapInfo(name: "level_3", displayName: "水晶洞", unlockLevel: 10, spawnPoint: CGPoint(x: 640, y: 640), enemyCount: 6, fileName: "level_3.tmx")
    ]
    
    private init() {}
    
    // MARK: - 🔧 SYSTEM TOGGLE
    func enableModernMapSystem(_ enabled: Bool) {
        useModernMapSystem = enabled
        print("🗺️ Map System: \(enabled ? "Modern (Tiled)" : "Original (Character Array)")")
    }
    
    func isModernSystemEnabled() -> Bool {
        return useModernMapSystem
    }
    
    // MARK: - 📖 MAP LOADING FUNCTIONS
    func loadMap(named mapName: String, in scene: SKScene) -> SKTileMapNode? {
        guard useModernMapSystem else {
            print("⚠️ Modern map system disabled, using original system")
            return nil
        }
        
        // Check if map is already loaded
        if let cachedMap = loadedMaps[mapName] {
            currentTileMap = cachedMap
            return cachedMap
        }
        
        // Find map info
        guard let mapInfo = availableMaps.first(where: { $0.name == mapName }) else {
            print("❌ Map not found: \(mapName)")
            return nil
        }
        
        // Try to load .tmx file
        guard let mapURL = Bundle.main.url(forResource: mapInfo.fileName.replacingOccurrences(of: ".tmx", with: ""), withExtension: "tmx") else {
            print("❌ TMX file not found: \(mapInfo.fileName)")
            return createFallbackMap(for: mapInfo, in: scene)
        }
        
        do {
            // Parse TMX file
            let tileMap = try parseTMXFile(url: mapURL, mapInfo: mapInfo, in: scene)
            loadedMaps[mapName] = tileMap
            currentTileMap = tileMap
            currentMapName = mapName
            print("✅ Successfully loaded TMX map: \(mapName)")
            return tileMap
        } catch {
            print("❌ Error parsing TMX file: \(error)")
            return createFallbackMap(for: mapInfo, in: scene)
        }
    }
    
    // MARK: - 🔧 TMX PARSER
    private func parseTMXFile(url: URL, mapInfo: MapInfo, in scene: SKScene) throws -> SKTileMapNode {
        let data = try Data(contentsOf: url)
        let parser = XMLParser(data: data)
        let delegate = TMXParserDelegate()
        parser.delegate = delegate
        
        guard parser.parse() else {
            throw NSError(domain: "TMXParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse TMX file"])
        }
        
        // Create tile map from parsed data
        let tileSize = CGSize(width: 64, height: 64)
        let tileSet = createBasicTileSet()
        let tileMap = SKTileMapNode(tileSet: tileSet, columns: 20, rows: 20, tileSize: tileSize)
        
        // Apply ground layer data
        if let groundData = delegate.groundLayerData {
            for (index, tileId) in groundData.enumerated() {
                let col = index % 20
                let row = index / 20
                
                if tileId > 0, let tileGroup = tileSet.tileGroups.first(where: { $0.name == getTileGroupName(for: tileId) }) {
                    tileMap.setTileGroup(tileGroup, forColumn: col, row: row)
                }
            }
        }
        
        // Setup animated tiles
        setupAnimatedTiles(in: tileMap)
        
        return tileMap
    }
    
    // MARK: - 🎬 ANIMATED TILES
    private func setupAnimatedTiles(in tileMap: SKTileMapNode) {
        // Water animation
        let waterFrames = [
            SKTexture(imageNamed: "water"),
            SKTexture(imageNamed: "water_original")
        ]
        let waterAnimation = SKAction.animate(with: waterFrames, timePerFrame: 0.5)
        let repeatWater = SKAction.repeatForever(waterAnimation)
        
        // Apply to all water tiles
        tileMap.enumerateChildNodes(withName: "//water_*") { node, _ in
            node.run(repeatWater)
        }
        
        // Grass sway animation (subtle)
        let swayAction = SKAction.sequence([
            SKAction.rotate(byAngle: 0.02, duration: 2.0),
            SKAction.rotate(byAngle: -0.02, duration: 2.0)
        ])
        let repeatSway = SKAction.repeatForever(swayAction)
        
        tileMap.enumerateChildNodes(withName: "//grass_*") { node, _ in
            node.run(repeatSway)
        }
    }
    
    private func getTileGroupName(for tileId: Int) -> String {
        switch tileId {
        case 0: return "grass"
        case 1: return "path"
        case 2: return "water"
        case 3: return "stone"
        default: return "grass"
        }
    }
    
    // MARK: - 🔄 MAP TRANSITION
    func transitionToMap(named mapName: String, in scene: SKScene, completion: @escaping () -> Void) {
        guard useModernMapSystem else {
            print("⚠️ Modern map system disabled")
            completion()
            return
        }
        
        // Save current level
        UserDefaults.standard.set(mapName, forKey: "currentLevel")
        
        // Load new map
        if let newMap = loadMap(named: mapName, in: scene) {
            // Remove old map
            currentTileMap?.removeFromParent()
            
            // Add new map
            newMap.position = CGPoint(x: 0, y: 0)
            newMap.zPosition = -10
            scene.addChild(newMap)
            
            currentTileMap = newMap
            currentMapName = mapName
            
            print("✅ Successfully loaded map: \(mapName)")
        }
        
        completion()
    }
    
    // MARK: - 🎯 SPAWN POINT MANAGEMENT
    func getPlayerSpawnPoint() -> CGPoint {
        guard useModernMapSystem else {
            // Return original spawn point
            return CGPoint(x: 0, y: 0)
        }
        
        guard let mapInfo = availableMaps.first(where: { $0.name == currentMapName }) else {
            return CGPoint(x: 0, y: 0)
        }
        
        return mapInfo.spawnPoint
    }
    
    func getEnemySpawnPoints() -> [CGPoint] {
        guard useModernMapSystem else {
            // Return empty array for original system
            return []
        }
        
        guard let mapInfo = availableMaps.first(where: { $0.name == currentMapName }) else {
            return []
        }
        
        // Generate random spawn points around the map
        var spawnPoints: [CGPoint] = []
        let mapSize = CGSize(width: 1280, height: 1280) // Default map size
        
        for _ in 0..<mapInfo.enemyCount {
            let x = CGFloat.random(in: 100...(mapSize.width - 100))
            let y = CGFloat.random(in: 100...(mapSize.height - 100))
            spawnPoints.append(CGPoint(x: x, y: y))
        }
        
        return spawnPoints
    }
    
    // MARK: - 🎮 COLLISION MANAGEMENT
    func getCollidableTiles() -> [SKNode] {
        guard useModernMapSystem, let tileMap = currentTileMap else {
            return []
        }
        
        var collisionNodes: [SKNode] = []
        
        // This would normally read from collision layer in .tmx file
        // For now, create some basic collision areas
        let collisionAreas = [
            CGRect(x: 0, y: 0, width: 1280, height: 64),      // Top border
            CGRect(x: 0, y: 1216, width: 1280, height: 64),   // Bottom border
            CGRect(x: 0, y: 0, width: 64, height: 1280),      // Left border
            CGRect(x: 1216, y: 0, width: 64, height: 1280)    // Right border
        ]
        
        for area in collisionAreas {
            let collisionNode = SKNode()
            collisionNode.position = CGPoint(x: area.midX, y: area.midY)
            collisionNode.physicsBody = SKPhysicsBody(rectangleOf: area.size)
            collisionNode.physicsBody?.isDynamic = false
            collisionNode.physicsBody?.categoryBitMask = 0x1 << 2
            collisionNode.physicsBody?.collisionBitMask = 0xFFFFFFFF
            collisionNodes.append(collisionNode)
        }
        
        return collisionNodes
    }
    
    // MARK: - 🎨 INTERACTIVE OBJECTS
    func getInteractiveObjects() -> [String: [SKNode]] {
        guard useModernMapSystem else {
            return [:]
        }
        
        // This would normally read from object layers in .tmx file
        // For now, return empty dictionary
        return [:]
    }
    
    // MARK: - 📊 MAP INFORMATION
    func getMapInfo(for mapName: String) -> MapInfo? {
        return availableMaps.first(where: { $0.name == mapName })
    }
    
    func getCurrentMapInfo() -> MapInfo? {
        return getMapInfo(for: currentMapName)
    }
    
    func getAvailableMaps() -> [MapInfo] {
        return availableMaps
    }
    
    // MARK: - 🔧 FALLBACK MAP CREATION
    private func createFallbackMap(for mapInfo: MapInfo, in scene: SKScene) -> SKTileMapNode? {
        print("🔧 Creating fallback map for: \(mapInfo.name)")
        
        // Create a simple tile map using existing assets
        let tileSize = CGSize(width: 64, height: 64)
        let mapSize = CGSize(width: 20, height: 20) // 20x20 grid
        
        // Create a basic tile map node
        let tileMap = SKTileMapNode(tileSet: createBasicTileSet(), columns: Int(mapSize.width), rows: Int(mapSize.height), tileSize: tileSize)
        
        // Fill with basic tiles
        for row in 0..<Int(mapSize.height) {
            for col in 0..<Int(mapSize.width) {
                let tileName = getTileNameForPosition(col: col, row: row, mapName: mapInfo.name)
                if let tileDefinition = tileMap.tileSet.tileDefinitions.first(where: { $0.name == tileName }) {
                    tileMap.setTileGroup(tileDefinition.parent, andTileDefinition: tileDefinition, forColumn: col, row: row)
                }
            }
        }
        
        return tileMap
    }
    
    private func createBasicTileSet() -> SKTileSet {
        let tileSet = SKTileSet()
        
        // Create tile groups for different terrain types
        let grassGroup = SKTileGroup()
        let pathGroup = SKTileGroup()
        let waterGroup = SKTileGroup()
        let stoneGroup = SKTileGroup()
        
        // Add tile definitions (simplified for now)
        if let grassTexture = SKTexture(imageNamed: "grass2") {
            let grassDefinition = SKTileDefinition(texture: grassTexture)
            grassDefinition.name = "grass"
            grassGroup.rules = [SKTileGroupRule()]
            grassGroup.rules[0].tileDefinitions = [grassDefinition]
        }
        
        if let pathTexture = SKTexture(imageNamed: "path") {
            let pathDefinition = SKTileDefinition(texture: pathTexture)
            pathDefinition.name = "path"
            pathGroup.rules = [SKTileGroupRule()]
            pathGroup.rules[0].tileDefinitions = [pathDefinition]
        }
        
        if let waterTexture = SKTexture(imageNamed: "water") {
            let waterDefinition = SKTileDefinition(texture: waterTexture)
            waterDefinition.name = "water"
            waterGroup.rules = [SKTileGroupRule()]
            waterGroup.rules[0].tileDefinitions = [waterDefinition]
        }
        
        if let stoneTexture = SKTexture(imageNamed: "stone2") {
            let stoneDefinition = SKTileDefinition(texture: stoneTexture)
            stoneDefinition.name = "stone"
            stoneGroup.rules = [SKTileGroupRule()]
            stoneGroup.rules[0].tileDefinitions = [stoneDefinition]
        }
        
        tileSet.tileGroups = [grassGroup, pathGroup, waterGroup, stoneGroup]
        return tileSet
    }
    
    private func getTileNameForPosition(col: Int, row: Int, mapName: String) -> String {
        // Create different patterns for different maps
        switch mapName {
        case "level_1":
            return createLevel1Pattern(col: col, row: row)
        case "level_2":
            return createLevel2Pattern(col: col, row: row)
        case "level_3":
            return createLevel3Pattern(col: col, row: row)
        default:
            return "grass"
        }
    }
    
    private func createLevel1Pattern(col: Int, row: Int) -> String {
        // Create a simple pattern for level 1
        if col == 0 || col == 19 || row == 0 || row == 19 {
            return "stone" // Border
        } else if (col >= 8 && col <= 11) && (row >= 8 && row <= 11) {
            return "water" // Water area in center
        } else if (col >= 2 && col <= 4) && (row >= 2 && row <= 4) {
            return "path" // Path area
        } else {
            return "grass" // Default grass
        }
    }
    
    private func createLevel2Pattern(col: Int, row: Int) -> String {
        // Create a forest pattern for level 2
        if col == 0 || col == 19 || row == 0 || row == 19 {
            return "stone" // Border
        } else if (col + row) % 3 == 0 {
            return "water" // Scattered water
        } else if (col + row) % 5 == 0 {
            return "path" // Scattered paths
        } else {
            return "grass" // Default grass
        }
    }
    
    private func createLevel3Pattern(col: Int, row: Int) -> String {
        // Create a cave pattern for level 3
        if col == 0 || col == 19 || row == 0 || row == 19 {
            return "stone" // Border
        } else if (col >= 5 && col <= 14) && (row >= 5 && row <= 14) {
            return "water" // Large water area
        } else if (col + row) % 2 == 0 {
            return "path" // Grid pattern paths
        } else {
            return "grass" // Default grass
        }
    }
    
    // MARK: - 🧹 CLEANUP
    func cleanup() {
        loadedMaps.removeAll()
        currentTileMap = nil
        print("🧹 MapManager cleaned up")
    }
}

// MARK: - 🔧 TMX PARSER DELEGATE
class TMXParserDelegate: NSObject, XMLParserDelegate {
    var groundLayerData: [Int]?
    var currentLayerName: String?
    var currentData: String = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "layer" {
            currentLayerName = attributeDict["name"]
        } else if elementName == "data" {
            currentData = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentLayerName == "ground_layer" {
            currentData += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "data" && currentLayerName == "ground_layer" {
            // Parse CSV data
            let csvData = currentData.trimmingCharacters(in: .whitespacesAndNewlines)
            let tileIds = csvData.components(separatedBy: ",").compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            groundLayerData = tileIds
        }
    }
}
