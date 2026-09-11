import Foundation

/**
 * ENHANCED PIRLS FRAMEWORK - Improved Classification & Evaluation
 * 
 * This enhanced version addresses the following improvements:
 * 1. Multi-factor question classification (not just keywords)
 * 2. Answer validation for Retrieving questions
 * 3. Better keyword detection with priority ordering
 * 4. Classification confidence scoring
 * 5. Enhanced vocabulary extraction with difficulty levels
 */

// MARK: - 🎯 Enhanced Question Classification
extension PIRLSQuestionClassifier {
    
    /**
     * Enhanced classification with multi-factor analysis
     * Priority order: Evaluating > Retrieving > Interpreting > Inferring
     */
    static func classifyQuestionEnhanced(_ questionText: String, passageText: String, answer: String? = nil) -> (process: PIRLSProcess, confidence: Double) {
        let lowerQuestion = questionText.lowercased()
        let lowerPassage = passageText.lowercased()
        var confidence: Double = 0.5  // Default confidence
        
        // ========== STEP 1: Check for Evaluating (Personal Judgment) ==========
        // Evaluating questions require personal opinion/judgment beyond the text
        let evaluatingPatterns = [
            "你認為", "你覺得", "你會", "你的看法", "你的想法",
            "如何", "怎樣", "評價", "判斷", "比較", "選擇",
            "如果.*你會", "假如.*你會"
        ]
        
        for pattern in evaluatingPatterns {
            if lowerQuestion.range(of: pattern, options: .regularExpression) != nil {
                // High confidence if question explicitly asks for personal opinion
                confidence = 0.9
                return (.evaluating, confidence)
            }
        }
        
        // ========== STEP 2: Check for Retrieving (Explicit Information) ==========
        // Retrieving questions have answers directly stated in passage
        let retrievingPatterns = [
            "文中提到", "文章說", "文章提到", "文中說",
            "哪一項", "什麼", "誰", "哪裡", "何時", "多少", "幾個"
        ]
        
        var retrievingScore = 0.0
        for pattern in retrievingPatterns {
            if lowerQuestion.contains(pattern) {
                retrievingScore += 0.2
            }
        }
        
        // Check if answer is explicitly in passage (if answer provided)
        if let answer = answer {
            let answerKeywords = extractKeywords(from: answer)
            let passageKeywords = extractKeywords(from: passageText)
            let matchCount = answerKeywords.filter { passageKeywords.contains($0) }.count
            let matchRatio = answerKeywords.isEmpty ? 0.0 : Double(matchCount) / Double(answerKeywords.count)
            
            if matchRatio > 0.7 {  // 70% of answer keywords found in passage
                retrievingScore += 0.5
                confidence = 0.85
            }
        }
        
        if retrievingScore > 0.3 {
            return (.retrieving, min(confidence + retrievingScore, 1.0))
        }
        
        // ========== STEP 3: Check for Interpreting (Multi-step Reasoning) ==========
        // Interpreting questions require understanding relationships and synthesis
        let interpretingPatterns = [
            "主要想說明", "想要表達", "想要告訴", "主要目的",
            "意味", "表示", "說明", "原因", "為什麼", "為何",
            "根據.*可以", "從.*可以看出", "從.*可以知道"
        ]
        
        var interpretingScore = 0.0
        for pattern in interpretingPatterns {
            if lowerQuestion.range(of: pattern, options: .regularExpression) != nil {
                interpretingScore += 0.25
            }
        }
        
        // Check for multi-step reasoning indicators
        if lowerQuestion.contains("主要") || lowerQuestion.contains("目的") || lowerQuestion.contains("意義") {
            interpretingScore += 0.2
        }
        
        if interpretingScore > 0.3 {
            confidence = 0.75
            return (.interpreting, min(confidence + interpretingScore * 0.2, 1.0))
        }
        
        // ========== STEP 4: Check for Inferring (Single-step Inference) ==========
        // Inferring questions require connecting information within text
        let inferringPatterns = [
            "可以推測", "可以推斷", "可以知道", "可以了解",
            "從文中可以", "從文章可以", "可能", "應該", "會"
        ]
        
        var inferringScore = 0.0
        for pattern in inferringPatterns {
            if lowerQuestion.contains(pattern) {
                inferringScore += 0.3
            }
        }
        
        if inferringScore > 0.3 {
            confidence = 0.7
            return (.inferring, min(confidence + inferringScore * 0.2, 1.0))
        }
        
        // ========== DEFAULT: Inferring (most common for reasoning questions) ==========
        return (.inferring, 0.5)
    }
    
    /**
     * Extract keywords from text (simplified version)
     */
    private static func extractKeywords(from text: String) -> [String] {
        // Remove punctuation and split by common delimiters
        let cleaned = text.components(separatedBy: CharacterSet.punctuationCharacters.union(.whitespaces))
            .joined()
        
        // Extract 2-character words (common in Chinese)
        var keywords: [String] = []
        let chars = Array(cleaned)
        for i in 0..<(chars.count - 1) {
            if chars[i].unicodeScalars.first?.properties.isIdeographic == true &&
               chars[i + 1].unicodeScalars.first?.properties.isIdeographic == true {
                let word = String(chars[i]) + String(chars[i + 1])
                keywords.append(word)
            }
        }
        
        return Array(Set(keywords))  // Remove duplicates
    }
    
    /**
     * Validate question classification against passage content
     */
    static func validateClassification(_ question: String, passage: String, process: PIRLSProcess, answer: String?) -> Bool {
        switch process {
        case .retrieving:
            // For retrieving, answer should be explicitly in passage
            if let answer = answer {
                let answerKeywords = extractKeywords(from: answer)
                let passageKeywords = extractKeywords(from: passage)
                let matchCount = answerKeywords.filter { passageKeywords.contains($0) }.count
                return matchCount > 0 && Double(matchCount) / Double(max(answerKeywords.count, 1)) > 0.5
            }
            return true  // Can't validate without answer
            
        case .inferring, .interpreting:
            // For inferring/interpreting, answer should not be directly stated
            if let answer = answer {
                let answerKeywords = extractKeywords(from: answer)
                let passageKeywords = extractKeywords(from: passage)
                let matchCount = answerKeywords.filter { passageKeywords.contains($0) }.count
                // Some overlap is OK, but not too much (should require reasoning)
                return Double(matchCount) / Double(max(answerKeywords.count, 1)) < 0.8
            }
            return true
            
        case .evaluating:
            // For evaluating, answer requires personal judgment (hard to validate automatically)
            return question.contains("你") || question.contains("認為") || question.contains("覺得")
        }
    }
}

// MARK: - 📚 Enhanced Vocabulary Extraction
extension PIRLSQuestionClassifier {
    
    /**
     * Enhanced vocabulary extraction with difficulty levels and importance scoring
     */
    static func extractKeyVocabularyEnhanced(_ passageText: String, maxWords: Int = 15, difficultyLevel: Int? = nil) -> [(word: String, difficulty: Int, importance: Double)] {
        // Get base vocabulary
        let baseVocabulary = extractKeyVocabulary(passageText, maxWords: maxWords * 2)
        
        // Score each word
        var scoredVocabulary: [(word: String, difficulty: Int, importance: Double)] = []
        
        for word in baseVocabulary {
            let difficulty = estimateWordDifficulty(word)
            let importance = calculateWordImportance(word, in: passageText)
            
            scoredVocabulary.append((word: word, difficulty: difficulty, importance: importance))
        }
        
        // Filter by difficulty if specified
        if let targetDifficulty = difficultyLevel {
            scoredVocabulary = scoredVocabulary.filter { word in
                // Include words at target level ± 1
                abs(word.difficulty - targetDifficulty) <= 1
            }
        }
        
        // Sort by importance (descending), then by difficulty relevance
        scoredVocabulary.sort { word1, word2 in
            if abs(word1.importance - word2.importance) > 0.1 {
                return word1.importance > word2.importance
            }
            // If importance is similar, prefer words closer to target difficulty
            if let targetDifficulty = difficultyLevel {
                let diff1 = abs(word1.difficulty - targetDifficulty)
                let diff2 = abs(word2.difficulty - targetDifficulty)
                return diff1 < diff2
            }
            return word1.difficulty < word2.difficulty
        }
        
        return Array(scoredVocabulary.prefix(maxWords))
    }
    
    /**
     * Estimate word difficulty level (1-6 for Primary 1-6)
     * This is a simplified heuristic - in production, use a vocabulary database
     */
    private static func estimateWordDifficulty(_ word: String) -> Int {
        // Common words (P1-P2)
        let p1p2Words: Set<String> = [
            "小", "大", "好", "多", "少", "來", "去", "看", "聽", "說",
            "朋友", "家人", "學校", "老師", "學生", "書本", "花園", "早晨"
        ]
        
        // Intermediate words (P3-P4)
        let p3p4Words: Set<String> = [
            "遷徙", "生長", "變化", "季節", "植物", "動物", "圖書館", "冒險"
        ]
        
        // Advanced words (P5-P6)
        let p5p6Words: Set<String> = [
            "太陽系", "行星", "探索", "傳統", "文化", "傳承", "意義", "特徵"
        ]
        
        if p1p2Words.contains(word) {
            return Int.random(in: 1...2)  // P1-P2
        } else if p3p4Words.contains(word) {
            return Int.random(in: 3...4)  // P3-P4
        } else if p5p6Words.contains(word) {
            return Int.random(in: 5...6)  // P5-P6
        }
        
        // Default: estimate based on character complexity
        // Longer words or less common characters = higher difficulty
        if word.count >= 3 {
            return Int.random(in: 4...6)
        } else if word.count == 2 {
            return Int.random(in: 2...4)
        } else {
            return Int.random(in: 1...3)
        }
    }
    
    /**
     * Calculate word importance in passage
     * Factors: frequency, position, context, uniqueness
     */
    private static func calculateWordImportance(_ word: String, in passageText: String) -> Double {
        var importance: Double = 0.0
        
        // Factor 1: Frequency (normalized)
        let wordCount = passageText.components(separatedBy: word).count - 1
        let totalWords = passageText.count / 2  // Rough estimate
        let frequency = Double(wordCount) / Double(max(totalWords, 1))
        importance += min(frequency * 10, 0.4)  // Cap at 0.4
        
        // Factor 2: Position (words near beginning/title are more important)
        if let firstIndex = passageText.range(of: word) {
            let position = passageText.distance(from: passageText.startIndex, to: firstIndex.lowerBound)
            let positionRatio = 1.0 - Double(position) / Double(max(passageText.count, 1))
            importance += positionRatio * 0.3  // Up to 0.3
        }
        
        // Factor 3: Uniqueness (less common words are more important)
        let commonWords: Set<String> = ["的", "了", "在", "是", "和", "有", "就", "也", "都"]
        if !commonWords.contains(word) {
            importance += 0.2
        }
        
        // Factor 4: Length (longer words often more important)
        if word.count >= 2 {
            importance += 0.1
        }
        
        return min(importance, 1.0)  // Cap at 1.0
    }
    
    /**
     * Link vocabulary to PIRLS processes based on passage context
     */
    static func linkVocabularyToProcess(_ vocabulary: [String], passageText: String, questionProcess: PIRLSProcess) -> [String: PIRLSProcess] {
        var vocabularyProcessMap: [String: PIRLSProcess] = [:]
        
        for word in vocabulary {
            // Check word context in passage
            let wordContext = getWordContext(word, in: passageText)
            
            // Assign process based on context and question process
            if wordContext.contains("認為") || wordContext.contains("覺得") {
                vocabularyProcessMap[word] = .evaluating
            } else if wordContext.contains("推測") || wordContext.contains("可能") {
                vocabularyProcessMap[word] = .inferring
            } else if wordContext.contains("說明") || wordContext.contains("表示") {
                vocabularyProcessMap[word] = .interpreting
            } else {
                // Default to question's process
                vocabularyProcessMap[word] = questionProcess
            }
        }
        
        return vocabularyProcessMap
    }
    
    /**
     * Get context around a word in passage
     */
    private static func getWordContext(_ word: String, in passageText: String, contextLength: Int = 10) -> String {
        if let range = passageText.range(of: word) {
            let start = max(passageText.distance(from: passageText.startIndex, to: range.lowerBound) - contextLength, 0)
            let end = min(passageText.distance(from: passageText.startIndex, to: range.upperBound) + contextLength, passageText.count)
            
            let startIndex = passageText.index(passageText.startIndex, offsetBy: start)
            let endIndex = passageText.index(passageText.startIndex, offsetBy: end)
            
            return String(passageText[startIndex..<endIndex])
        }
        return ""
    }
}

