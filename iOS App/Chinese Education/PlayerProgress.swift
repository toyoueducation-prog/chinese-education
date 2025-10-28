import Foundation
import SpriteKit  // Import SpriteKit for scene handling

// MARK: - 📈 PLAYER PROGRESS MANAGER - Leveling & Achievement System
class PlayerProgress {
    static let shared = PlayerProgress()  // Singleton instance
    
    // MARK: - 🔑 USER DEFAULTS KEYS
    private let levelKey = "playerLevel"      // Key for storing player level
    private let xpKey = "playerXP"           // Key for storing experience points
    private let badgesKey = "playerBadges"   // Key for storing unlocked badges
    private let worldsKey = "unlockedWorlds" // Key for storing unlocked worlds

    private init() {}  // Private initializer for singleton

    // MARK: - XP & Leveling
    var level: Int {
        get { UserDefaults.standard.integer(forKey: levelKey) }
        set { UserDefaults.standard.set(newValue, forKey: levelKey) }
    }

    var xp: Int {
        get { UserDefaults.standard.integer(forKey: xpKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: xpKey)
            checkLevelUp()
        }
    }

    func addXP(amount: Int) {
        xp += amount
    }

    private func checkLevelUp() {
        let xpThreshold = level * 100 // Example: 100 XP per level
        if xp >= xpThreshold {
            level += 1
            xp = 0 // Reset XP after leveling up
            unlockWorld(forLevel: level)
        }
    }

    // MARK: - Badge System
    var badges: [String] {
        get { UserDefaults.standard.stringArray(forKey: badgesKey) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: badgesKey) }
    }

    func unlockBadge(_ badge: String, in scene: SKScene) {
        if !badges.contains(badge) {
            badges.append(badge)
            print("🏅 Badge Unlocked: \(badge)")

            // ✅ Show Badge Award Scene
            let badgeScene = BadgeScene(size: scene.size)
            badgeScene.scaleMode = .aspectFill
            badgeScene.badgeName = badge
            let transition = SKTransition.fade(withDuration: 1.0)
            scene.view?.presentScene(badgeScene, transition: transition)
        }
    }

    // MARK: - Unlocking Worlds
    var unlockedWorlds: [String] {
        get { UserDefaults.standard.stringArray(forKey: worldsKey) ?? ["World1"] } // Default starting world
        set { UserDefaults.standard.set(newValue, forKey: worldsKey) }
    }

    private func unlockWorld(forLevel level: Int) {
        let newWorld = "World\(level)"
        if !unlockedWorlds.contains(newWorld) {
            unlockedWorlds.append(newWorld)
        }
    }
}
