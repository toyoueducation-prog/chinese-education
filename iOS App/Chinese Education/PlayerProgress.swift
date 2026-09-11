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
        // Support 6 primary levels (Primary 1-6)
        let maxLevel = 6
        
        // ✅ Calculate XP threshold: Level 1 needs 100 XP, then progressively more
        // Level 0 → 1: 100 XP (total)
        // Level 1 → 2: 250 XP (total, needs 150 more)
        // Level 2 → 3: 450 XP (total, needs 200 more)
        // Level 3 → 4: 700 XP (total, needs 250 more)
        // Level 4 → 5: 1000 XP (total, needs 300 more)
        // Level 5 → 6: 1350 XP (total, needs 350 more)
        let xpThresholds: [Int] = [100, 250, 450, 700, 1000, 1350]
        let currentThreshold = level < xpThresholds.count ? xpThresholds[level] : xpThresholds.last ?? 1350
        
        if xp >= currentThreshold && level < maxLevel {
            let oldLevel = level
            level += 1
            // ✅ Don't reset XP to 0, keep the excess XP for next level
            unlockWorld(forLevel: level)
            // Sync with StudentProfile
            StudentProfile.shared.currentLevel = level
            StudentProfile.shared.saveProfile()
            
            let nextThreshold = level < xpThresholds.count ? xpThresholds[level] : xpThresholds.last ?? 1350
            print("🎉 Level Up! From Level \(oldLevel) to Level \(level)! XP: \(xp)/\(nextThreshold)")
            
            // ✅ Post notification for level up scene
            NotificationCenter.default.post(
                name: NSNotification.Name("PlayerLevelUp"),
                object: nil,
                userInfo: ["newLevel": level, "oldLevel": oldLevel]
            )
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
    
    // MARK: - PIRLS Process-Specific Badges (Phase 2.1)
    /**
     * Checks and unlocks PIRLS process-specific achievements.
     * Badges are awarded when students reach mastery thresholds in specific processes.
     */
    func checkPIRLSProcessBadges(in scene: SKScene) {
        let profile = StudentProfile.shared
        
        // Process-specific badges
        let processBadges: [PIRLSProcess: (name: String, threshold: Double)] = [
            .retrieving: ("檢索大師", 0.8),
            .inferring: ("推論專家", 0.8),
            .interpreting: ("詮釋達人", 0.8),
            .evaluating: ("評價高手", 0.8)
        ]
        
        for (process, badgeInfo) in processBadges {
            if let performance = profile.pirlsAssessment.processPerformance[process],
               performance.masteryLevel >= badgeInfo.threshold {
                let badgeName = badgeInfo.name
                if !badges.contains(badgeName) {
                    unlockBadge(badgeName, in: scene)
                }
            }
        }
    }
    
    // MARK: - Reading Purpose Badges (Phase 2.1)
    /**
     * Awards badges for reading purpose achievements.
     */
    func checkReadingPurposeBadges(in scene: SKScene) {
        let profile = StudentProfile.shared
        
        // Literary reading badge
        if profile.literaryPerformance >= 0.8 {
            let badgeName = "文學愛好者"
            if !badges.contains(badgeName) {
                unlockBadge(badgeName, in: scene)
            }
        }
        
        // Informational reading badge
        if profile.informationalPerformance >= 0.8 {
            let badgeName = "資訊探索家"
            if !badges.contains(badgeName) {
                unlockBadge(badgeName, in: scene)
            }
        }
    }
    
    // MARK: - Vocabulary Milestone Badges (Phase 2.1)
    /**
     * Awards badges for vocabulary milestones.
     */
    func checkVocabularyBadges(in scene: SKScene) {
        let vocabStats = VocabularyManager.shared.getStatistics()
        
        let vocabularyMilestones: [(count: Int, badge: String)] = [
            (100, "100詞彙"),
            (250, "250詞彙"),
            (500, "500詞彙"),
            (1000, "1000詞彙大師")
        ]
        
        for milestone in vocabularyMilestones {
            if vocabStats.totalWords >= milestone.count {
                if !badges.contains(milestone.badge) {
                    unlockBadge(milestone.badge, in: scene)
                }
            }
        }
        
        // Mastery badges
        if vocabStats.masteryRate >= 0.9 {
            let badgeName = "詞彙大師"
            if !badges.contains(badgeName) {
                unlockBadge(badgeName, in: scene)
            }
        }
    }
    
    // MARK: - Streak Achievements (Phase 2.1)
    /**
     * Tracks and awards streak achievements.
     */
    private let lastPlayDateKey = "lastPlayDate"
    private let currentStreakKey = "currentStreak"
    private let longestStreakKey = "longestStreak"
    
    var currentStreak: Int {
        get { UserDefaults.standard.integer(forKey: currentStreakKey) }
        set { UserDefaults.standard.set(newValue, forKey: currentStreakKey) }
    }
    
    var longestStreak: Int {
        get { UserDefaults.standard.integer(forKey: longestStreakKey) }
        set { UserDefaults.standard.set(newValue, forKey: longestStreakKey) }
    }
    
    func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastPlayDate = UserDefaults.standard.object(forKey: lastPlayDateKey) as? Date
        let lastPlay = lastPlayDate != nil ? Calendar.current.startOfDay(for: lastPlayDate!) : nil
        
        if let lastPlay = lastPlay {
            let daysSince = Calendar.current.dateComponents([.day], from: lastPlay, to: today).day ?? 0
            
            if daysSince == 0 {
                // Same day, no update needed
                return
            } else if daysSince == 1 {
                // Consecutive day
                currentStreak += 1
            } else {
                // Streak broken
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
                currentStreak = 1
            }
        } else {
            // First time playing
            currentStreak = 1
        }
        
        UserDefaults.standard.set(today, forKey: lastPlayDateKey)
        
        // Check for streak badges
        checkStreakBadges()
    }
    
    private func checkStreakBadges() {
        let streakBadges: [(days: Int, badge: String)] = [
            (7, "連續7天"),
            (14, "連續14天"),
            (30, "連續30天"),
            (60, "連續60天"),
            (100, "連續100天")
        ]
        
        for streakBadge in streakBadges {
            if currentStreak >= streakBadge.days {
                // Note: We'd need access to scene here, but for now just track
                // In real implementation, call from scene context
                if !badges.contains(streakBadge.badge) {
                    badges.append(streakBadge.badge)
                    print("🏅 Streak Badge Unlocked: \(streakBadge.badge)")
                }
            }
        }
    }
    
    // MARK: - Level Progression Celebrations (Phase 2.1)
    /**
     * Enhanced level up celebration with PIRLS context.
     */
    func celebrateLevelUp(in scene: SKScene) {
        let profile = StudentProfile.shared
        let level = profile.currentLevel
        
        // Level-specific celebrations
        let celebrationMessages: [Int: String] = [
            2: "恭喜升級到小學二年級！",
            3: "恭喜升級到小學三年級！",
            4: "恭喜升級到小學四年級！",
            5: "恭喜升級到小學五年級！",
            6: "恭喜升級到小學六年級！"
        ]
        
        if let message = celebrationMessages[level] {
            // Show celebration (could be enhanced with animation)
            print("🎉 \(message)")
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
