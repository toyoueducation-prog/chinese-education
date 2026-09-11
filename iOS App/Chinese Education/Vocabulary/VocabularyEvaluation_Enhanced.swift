import Foundation

/**
 * ENHANCED VOCABULARY EVALUATION SYSTEM
 * 
 * Improvements:
 * 1. Difficulty-based vocabulary assessment (P1-P6)
 * 2. Semantic importance scoring
 * 3. Context-aware mastery evaluation
 * 4. PIRLS process linkage
 * 5. Multi-dimensional mastery assessment
 */

// MARK: - 📊 Enhanced Vocabulary Word
extension VocabularyWord {
    
    /**
     * Enhanced mastery calculation with multiple dimensions
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
}

// MARK: - 📚 Enhanced Vocabulary Manager
extension VocabularyManager {
    
    /**
     * Extract vocabulary with difficulty assessment
     */
    func extractVocabularyEnhanced(from passageText: String, maxWords: Int = 15, targetDifficulty: Int? = nil) -> [VocabularyWord] {
        // Use enhanced extraction with difficulty levels
        let extractedWords = PIRLSQuestionClassifier.extractKeyVocabularyEnhanced(
            passageText,
            maxWords: maxWords * 2,
            difficultyLevel: targetDifficulty
        )
        
        var vocabularyList: [VocabularyWord] = []
        for (word, difficulty, importance) in extractedWords {
            if let existingWord = vocabularyWords[word] {
                var updatedWord = existingWord
                // Update with enhanced mastery if needed
                updatedWord.updateMasteryEnhanced(difficulty: difficulty)
                vocabularyWords[word] = updatedWord
                vocabularyList.append(updatedWord)
            } else {
                // Create new vocabulary word with difficulty info
                var newWord = VocabularyWord(
                    word: word,
                    pinyin: "",  // Can be filled by AI or dictionary lookup
                    meaning: "",  // Can be filled by AI or dictionary lookup
                    masteryLevel: 0,
                    encounters: 0,
                    correctUses: 0
                )
                // Store difficulty as metadata (would need to extend VocabularyWord struct)
                vocabularyWords[word] = newWord
                vocabularyList.append(newWord)
            }
        }
        
        // Sort by importance and difficulty relevance
        vocabularyList.sort { word1, word2 in
            // Prioritize words at target difficulty level
            if let target = targetDifficulty {
                // This would require storing difficulty in VocabularyWord
                // For now, sort by mastery (lower mastery = more important to learn)
                return word1.masteryLevel < word2.masteryLevel
            }
            return word1.masteryLevel < word2.masteryLevel
        }
        
        saveVocabulary()
        return Array(vocabularyList.prefix(maxWords))
    }
    
    /**
     * Evaluate vocabulary mastery in context
     */
    func evaluateVocabularyInContext(_ word: String, passageText: String, questionProcess: PIRLSProcess) -> VocabularyEvaluation {
        guard let vocabularyWord = vocabularyWords[word] else {
            return VocabularyEvaluation(
                word: word,
                masteryLevel: 0,
                recognitionScore: 0.0,
                comprehensionScore: 0.0,
                usageScore: 0.0,
                contextScore: 0.0,
                processRelevance: 0.0
            )
        }
        
        let breakdown = vocabularyWord.getMasteryBreakdown()
        
        // Calculate process relevance
        let processRelevance = calculateProcessRelevance(word, passageText: passageText, process: questionProcess)
        
        return VocabularyEvaluation(
            word: word,
            masteryLevel: vocabularyWord.masteryLevel,
            recognitionScore: breakdown.recognition,
            comprehensionScore: breakdown.comprehension,
            usageScore: breakdown.usage,
            contextScore: breakdown.context,
            processRelevance: processRelevance
        )
    }
    
    /**
     * Calculate how relevant a word is to a PIRLS process
     */
    private func calculateProcessRelevance(_ word: String, passageText: String, process: PIRLSProcess) -> Double {
        // Check if word appears in process-relevant contexts
        let wordContext = getWordContext(word, in: passageText)
        
        switch process {
        case .retrieving:
            // Words that appear in factual statements
            if wordContext.contains("是") || wordContext.contains("有") || wordContext.contains("在") {
                return 0.8
            }
        case .inferring:
            // Words that appear in inference contexts
            if wordContext.contains("可以") || wordContext.contains("可能") || wordContext.contains("應該") {
                return 0.8
            }
        case .interpreting:
            // Words that appear in explanation contexts
            if wordContext.contains("說明") || wordContext.contains("表示") || wordContext.contains("意味") {
                return 0.8
            }
        case .evaluating:
            // Words that appear in judgment contexts
            if wordContext.contains("認為") || wordContext.contains("覺得") || wordContext.contains("評價") {
                return 0.8
            }
        }
        
        return 0.5  // Default relevance
    }
    
    /**
     * Get context around a word
     */
    private func getWordContext(_ word: String, in passageText: String, contextLength: Int = 10) -> String {
        if let range = passageText.range(of: word) {
            let start = max(passageText.distance(from: passageText.startIndex, to: range.lowerBound) - contextLength, 0)
            let end = min(passageText.distance(from: passageText.startIndex, to: range.upperBound) + contextLength, passageText.count)
            
            let startIndex = passageText.index(passageText.startIndex, offsetBy: start)
            let endIndex = passageText.index(passageText.startIndex, offsetBy: end)
            
            return String(passageText[startIndex..<endIndex])
        }
        return ""
    }
    
    /**
     * Get vocabulary by difficulty level
     */
    func getVocabularyByDifficulty(_ level: Int) -> [VocabularyWord] {
        // This would require storing difficulty in VocabularyWord
        // For now, return all vocabulary (would need enhancement)
        return getAllVocabulary()
    }
    
    /**
     * Get vocabulary statistics by difficulty
     */
    func getStatisticsByDifficulty() -> [Int: VocabularyStats] {
        var statsByLevel: [Int: VocabularyStats] = [:]
        
        // This would require difficulty tracking in VocabularyWord
        // For now, return overall stats for all levels
        for level in 1...6 {
            statsByLevel[level] = getStatistics()
        }
        
        return statsByLevel
    }
}

// MARK: - 📊 Vocabulary Evaluation Result
struct VocabularyEvaluation {
    let word: String
    let masteryLevel: Int
    let recognitionScore: Double
    let comprehensionScore: Double
    let usageScore: Double
    let contextScore: Double
    let processRelevance: Double
    
    var overallScore: Double {
        return (
            recognitionScore * 0.2 +
            comprehensionScore * 0.3 +
            usageScore * 0.2 +
            contextScore * 0.15 +
            processRelevance * 0.15
        )
    }
}

