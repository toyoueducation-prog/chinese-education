import Foundation

/**
 * LEARNING PATH MANAGER - Personalized Learning Recommendations
 * 
 * Features:
 * - AI-recommended passage selection based on weak PIRLS processes
 * - Adaptive difficulty adjustment per process
 * - Personalized vocabulary review lists
 * - Reading purpose balance recommendations
 * - Progress-based content unlocking
 */
// MARK: - 🎯 LEARNING PATH MANAGER
class LearningPathManager {
    static let shared = LearningPathManager()
    
    private init() {}
    
    // MARK: - Get Recommended Passages
    /**
     * Recommends passages based on student's weak PIRLS processes.
     * Prioritizes passages with questions targeting weak areas.
     */
    func getRecommendedPassages(_ profile: StudentProfile, count: Int = 3) -> [String] {
        var recommendations: [String] = []
        
        // Identify weak processes
        let weakProcesses = getWeakProcesses(profile)
        
        // Get all available passages
        let allPassageKeys = ["passage1", "passage2", "passage3", "passage4", "passage5", "passage6", "passage7", "passage8"]
        
        // Score passages based on relevance to weak processes
        var passageScores: [(key: String, score: Int)] = []
        
        for passageKey in allPassageKeys {
            var score = 0
            
            // Get questions for this passage
            if let passageSet = QuestionBank.shared.getPassageSet(for: passageKey) {
                for questionKey in passageSet.questionKeys {
                    if let question = QuestionBank.shared.getQuestion(forKey: questionKey) {
                        let enriched = QuestionBank.shared.enrichQuestionWithPIRLS(question, passageText: passageSet.passage)
                        
                        // Higher score if question targets weak process
                        if weakProcesses.contains(enriched.pirlsProcess) {
                            score += 3
                        } else {
                            score += 1
                        }
                    }
                }
            }
            
            passageScores.append((key: passageKey, score: score))
        }
        
        // Sort by score and return top recommendations
        passageScores.sort { $0.score > $1.score }
        recommendations = Array(passageScores.prefix(count).map { $0.key })
        
        return recommendations
    }
    
    // MARK: - Get Weak Processes
    private func getWeakProcesses(_ profile: StudentProfile) -> [PIRLSProcess] {
        var weakProcesses: [PIRLSProcess] = []
        let threshold: Double = 0.6
        
        for process in PIRLSProcess.allCases {
            if let performance = profile.pirlsAssessment.processPerformance[process],
               performance.masteryLevel < threshold {
                weakProcesses.append(process)
            }
        }
        
        return weakProcesses
    }
    
    // MARK: - Get Adaptive Difficulty
    /**
     * Adjusts difficulty based on student's performance in each process.
     * Returns recommended difficulty level (1-6) for each process.
     */
    func getAdaptiveDifficulty(_ profile: StudentProfile) -> [PIRLSProcess: Int] {
        var difficultyMap: [PIRLSProcess: Int] = [:]
        
        for process in PIRLSProcess.allCases {
            if let performance = profile.pirlsAssessment.processPerformance[process] {
                let mastery = performance.masteryLevel
                
                // Adjust difficulty based on mastery
                var recommendedLevel = profile.currentLevel
                
                if mastery >= 0.8 {
                    // High mastery - can try next level
                    recommendedLevel = min(6, profile.currentLevel + 1)
                } else if mastery >= 0.6 {
                    // Good mastery - stay at current level
                    recommendedLevel = profile.currentLevel
                } else if mastery >= 0.4 {
                    // Moderate mastery - try slightly easier
                    recommendedLevel = max(1, profile.currentLevel - 1)
                } else {
                    // Low mastery - go back to basics
                    recommendedLevel = max(1, profile.currentLevel - 2)
                }
                
                difficultyMap[process] = recommendedLevel
            } else {
                // No data - default to current level
                difficultyMap[process] = profile.currentLevel
            }
        }
        
        return difficultyMap
    }
    
    // MARK: - Get Personalized Vocabulary Review
    /**
     * Generates vocabulary review list based on:
     * - Words from upcoming recommended passages
     * - Words with low mastery levels
     * - Words relevant to weak PIRLS processes
     */
    func getPersonalizedVocabularyReview(_ profile: StudentProfile, count: Int = 20) -> [VocabularyWord] {
        var reviewWords: [VocabularyWord] = []
        
        // Get words with low mastery
        let allVocab = VocabularyManager.shared.getAllVocabulary()
        let lowMasteryWords = allVocab.filter { $0.masteryLevel < 3 }.sorted { $0.masteryLevel < $1.masteryLevel }
        reviewWords.append(contentsOf: Array(lowMasteryWords.prefix(count / 2)))
        
        // Get words from recommended passages
        let recommendedPassages = getRecommendedPassages(profile, count: 2)
        for passageKey in recommendedPassages {
            if let passageSet = QuestionBank.shared.getPassageSet(for: passageKey) {
                let vocab = VocabularyManager.shared.extractVocabulary(from: passageSet.passage, maxWords: 10)
                reviewWords.append(contentsOf: vocab)
            }
        }
        
        // Remove duplicates and limit count
        var uniqueWords: [String: VocabularyWord] = [:]
        for word in reviewWords {
            uniqueWords[word.word] = word
        }
        
        return Array(uniqueWords.values.prefix(count))
    }
    
    // MARK: - Get Reading Purpose Recommendations
    /**
     * Recommends reading purpose balance adjustments.
     */
    func getReadingPurposeRecommendations(_ profile: StudentProfile) -> ReadingPurposeRecommendation {
        let tracker = ReadingPurposeTracker.shared
        let balance = tracker.calculateBalance(profile)
        let performance = tracker.getPurposePerformance(profile)
        
        var recommendation: ReadingPurposeRecommendation
        
        if !balance.isBalanced {
            let weakerType = balance.literary < balance.informational ? ReadingPurpose.literary : ReadingPurpose.informational
            let suggestedPassages = tracker.suggestContentForBalance(balance)
            
            recommendation = ReadingPurposeRecommendation(
                needsBalance: true,
                weakerPurpose: weakerType,
                recommendedPassages: suggestedPassages,
                targetRatio: 0.5,
                currentRatio: weakerType == .literary ? balance.literary : balance.informational
            )
        } else {
            recommendation = ReadingPurposeRecommendation(
                needsBalance: false,
                weakerPurpose: nil,
                recommendedPassages: [],
                targetRatio: 0.5,
                currentRatio: 0.5
            )
        }
        
        return recommendation
    }
    
    // MARK: - Check Content Unlocking
    /**
     * Determines which content should be unlocked based on progress.
     */
    func checkContentUnlocking(_ profile: StudentProfile) -> [String] {
        var unlockedContent: [String] = []
        
        // Unlock based on level
        let level = profile.currentLevel
        let allPassageKeys = ["passage1", "passage2", "passage3", "passage4", "passage5", "passage6", "passage7", "passage8"]
        
        // Simple unlocking: level 1-2 get passages 1-2, level 3-4 get 3-5, level 5-6 get all
        if level >= 1 {
            unlockedContent.append(contentsOf: ["passage1", "passage2"])
        }
        if level >= 3 {
            unlockedContent.append(contentsOf: ["passage3", "passage4", "passage5"])
        }
        if level >= 5 {
            unlockedContent.append(contentsOf: ["passage6", "passage7", "passage8"])
        }
        
        // Unlock based on process mastery
        for process in PIRLSProcess.allCases {
            if let performance = profile.pirlsAssessment.processPerformance[process],
               performance.masteryLevel >= 0.7 {
                // Unlock advanced content for this process
                // In a more sophisticated system, this would unlock specific advanced passages
            }
        }
        
        return unlockedContent
    }
}

// MARK: - Data Structures
struct ReadingPurposeRecommendation {
    let needsBalance: Bool
    let weakerPurpose: ReadingPurpose?
    let recommendedPassages: [String]
    let targetRatio: Double
    let currentRatio: Double
}

