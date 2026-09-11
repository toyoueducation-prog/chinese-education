import Foundation

// MARK: - 💰 GAME STATS MANAGER - Score & Currency System
class GameStats {
    static let shared = GameStats()  // Singleton pattern

    // MARK: - 🔑 USER DEFAULTS KEYS
    private let scoreKey = "gameScore"        // Key for storing game score
    private let crystalCoinKey = "crystalCoins"  // Key for storing crystal coins
    private let collectedDollsKey = "collectedDolls"  // Key for storing collected dolls/stars

    private init() {}  // Private initializer for singleton

    // MARK: - Score Handling
    var gameScore: Int {
        get { UserDefaults.standard.integer(forKey: scoreKey) }
        set { UserDefaults.standard.set(newValue, forKey: scoreKey) }
    }

    func addScore(points: Int) {
        gameScore += points
    }

    func resetScore() {
        gameScore = 0
    }

    // MARK: - Crystal Coin Handling
    var crystalCoins: Int {
        get {
            let storedValue = UserDefaults.standard.integer(forKey: crystalCoinKey)
            return storedValue == 0 ? 3 : storedValue  // ✅ Default to 3 if uninitialized
        }
        set { UserDefaults.standard.set(newValue, forKey: crystalCoinKey) }
    }
    
    // MARK: - Collected Dolls/Stars Handling
    var collectedDolls: Int {
        get { UserDefaults.standard.integer(forKey: collectedDollsKey) }
        set { UserDefaults.standard.set(newValue, forKey: collectedDollsKey) }
    }
    
    func addCollectedDoll() {
        collectedDolls += 1
    }


    func convertScoreToCrystals() {
        if gameScore >= 10 {
            let crystalsEarned = gameScore / 10
            crystalCoins += crystalsEarned
            resetScore()
        }
    }
}
