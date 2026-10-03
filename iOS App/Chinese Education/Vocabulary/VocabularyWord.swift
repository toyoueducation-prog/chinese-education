import Foundation

// MARK: - 📖 VOCABULARY WORD - Individual Word Tracking Model
struct VocabularyWord: Codable, Identifiable, Equatable {
    let id: String  // Unique identifier (word itself or UUID)
    let word: String  // Chinese word
    var pinyin: String  // Pinyin pronunciation
    var meaning: String  // English/Chinese meaning
    var masteryLevel: Int  // 0-5 mastery level
    var encounters: Int  // Number of times encountered
    var correctUses: Int  // Number of correct uses in context
    var lastSeen: Date  // Last time word was encountered
    var firstSeen: Date  // First time word was encountered
    var contexts: [String]  // Example sentences/contexts where word appeared
    
    // MARK: - Mastery Level Descriptions
    static let masteryDescriptions = [
        0: "未學習",
        1: "初識",
        2: "認識",
        3: "理解",
        4: "熟練",
        5: "精通"
    ]
    
    var masteryDescription: String {
        return VocabularyWord.masteryDescriptions[masteryLevel] ?? "未知"
    }

    /// Only words with a real gloss should enter graded practice.
    var isPracticeReady: Bool {
        VocabularyGlossary.hasUsableMeaning(self)
    }

    mutating func applyGlossaryIfNeeded() {
        let gloss = VocabularyGlossary.gloss(for: word, existingPinyin: pinyin, existingMeaning: meaning)
        if pinyin.isEmpty { pinyin = gloss.pinyin }
        if meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            meaning = gloss.meaning
        }
    }
    
    // MARK: - Initialization
    init(word: String, pinyin: String = "", meaning: String = "", masteryLevel: Int = 0, encounters: Int = 0, correctUses: Int = 0, lastSeen: Date = Date(), firstSeen: Date = Date(), contexts: [String] = []) {
        self.id = word  // Use word as ID for simplicity
        self.word = word
        self.pinyin = pinyin
        self.meaning = meaning
        self.masteryLevel = masteryLevel
        self.encounters = encounters
        self.correctUses = correctUses
        self.lastSeen = lastSeen
        self.firstSeen = firstSeen
        self.contexts = contexts
    }
    
    // MARK: - Mastery Calculation
    mutating func updateMastery() {
        // Calculate mastery based on encounters and correct uses
        let accuracyRate = encounters > 0 ? Double(correctUses) / Double(encounters) : 0.0
        
        if encounters == 0 {
            masteryLevel = 0
        } else if encounters < 3 {
            masteryLevel = 1  // Just encountered
        } else if accuracyRate < 0.5 {
            masteryLevel = 2  // Recognizing but not mastering
        } else if accuracyRate < 0.7 {
            masteryLevel = 3  // Understanding
        } else if accuracyRate < 0.9 {
            masteryLevel = 4  // Proficient
        } else {
            masteryLevel = 5  // Mastered
        }
    }
    
    /**
     * Enhanced mastery calculation with multiple dimensions
     * Provides more accurate assessment considering recognition, comprehension, usage, and context
     */
    mutating func updateMasteryEnhanced(context: String? = nil, difficulty: Int? = nil) {
        // Dimension 1: Recognition (can identify the word)
        let recognitionScore = encounters > 0 ? 1.0 : 0.0
        
        // Dimension 2: Comprehension (understands meaning)
        let accuracyRate = encounters > 0 ? Double(correctUses) / Double(encounters) : 0.0
        let comprehensionScore = accuracyRate
        
        // Dimension 3: Usage (can use in context)
        let usageScore = contexts.count > 1 ? min(Double(contexts.count) / 3.0, 1.0) : (contexts.count > 0 ? 0.5 : 0.0)
        
        // Dimension 4: Context Awareness (understands in different contexts)
        let contextScore = contexts.count >= 2 ? 1.0 : (contexts.count == 1 ? 0.5 : 0.0)
        
        // Dimension 5: Difficulty Adjustment
        let difficultyFactor: Double
        if let difficulty = difficulty {
            // Harder words require more encounters to master
            let requiredEncounters = max(3, difficulty * 2)
            difficultyFactor = min(Double(encounters) / Double(requiredEncounters), 1.0)
        } else {
            difficultyFactor = min(Double(encounters) / 5.0, 1.0)
        }
        
        // Weighted mastery calculation
        let weightedMastery = (
            recognitionScore * 0.2 +
            comprehensionScore * 0.3 +
            usageScore * 0.2 +
            contextScore * 0.15 +
            difficultyFactor * 0.15
        )
        
        // Convert to 0-5 scale
        if weightedMastery < 0.2 {
            masteryLevel = 0  // New word
        } else if weightedMastery < 0.4 {
            masteryLevel = 1  // Encountered
        } else if weightedMastery < 0.6 {
            masteryLevel = 2  // Learning
        } else if weightedMastery < 0.75 {
            masteryLevel = 3  // Practicing
        } else if weightedMastery < 0.9 {
            masteryLevel = 4  // Proficient
        } else {
            masteryLevel = 5  // Mastered
        }
    }
    
    /**
     * Get mastery breakdown by dimension
     */
    func getMasteryBreakdown() -> (recognition: Double, comprehension: Double, usage: Double, context: Double) {
        let recognition = encounters > 0 ? 1.0 : 0.0
        let comprehension = encounters > 0 ? Double(correctUses) / Double(encounters) : 0.0
        let usage = contexts.count > 1 ? min(Double(contexts.count) / 3.0, 1.0) : (contexts.count > 0 ? 0.5 : 0.0)
        let context = contexts.count >= 2 ? 1.0 : (contexts.count == 1 ? 0.5 : 0.0)
        
        return (recognition, comprehension, usage, context)
    }
    
    mutating func addEncounter(isCorrect: Bool, context: String? = nil) {
        encounters += 1
        if isCorrect {
            correctUses += 1
        }
        lastSeen = Date()
        if firstSeen == Date() && encounters == 1 {
            firstSeen = Date()
        }
        if let context = context, !contexts.contains(context) {
            contexts.append(context)
        }
        updateMastery()
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, word, pinyin, meaning, masteryLevel, encounters, correctUses, lastSeen, firstSeen, contexts
    }
}

// MARK: - 📊 Vocabulary Statistics
struct VocabularyStats {
    var totalWords: Int
    var masteredWords: Int  // Level 5
    var proficientWords: Int  // Level 4
    var learningWords: Int  // Level 1-3
    var newWords: Int  // Level 0
    
    var masteryRate: Double {
        guard totalWords > 0 else { return 0.0 }
        return Double(masteredWords + proficientWords) / Double(totalWords)
    }
}

