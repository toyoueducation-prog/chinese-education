import Foundation

/**
 * PIRLS FRAMEWORK - Reading Comprehension Assessment System
 * 
 * Implements the PIRLS (Progress in International Reading Literacy Study) framework
 * for assessing and improving Chinese reading comprehension in primary school students (ages 6-12).
 * 
 * PIRLS Reading Comprehension Processes:
 * 1. Retrieving (檢索理解) - Finding explicitly stated information
 * 2. Inferring (推論理解) - Drawing straightforward inferences
 * 3. Interpreting (詮釋理解) - Interpreting and integrating ideas
 * 4. Evaluating (評價理解) - Examining and evaluating content
 * 
 * Reading Purposes:
 * - Literary: Stories, narratives, character-driven texts
 * - Informational: Expository, factual, informational texts
 * 
 * Key Components:
 * - PIRLSProcess enum: Defines the four reading comprehension processes
 * - ReadingPurpose enum: Classifies texts by purpose
 * - PIRLSProcessPerformance: Tracks performance metrics for each process
 * - PIRLSAssessment: Overall assessment summary
 * - PIRLSQuestionClassifier: Classifies questions and extracts vocabulary
 * 
 * Usage:
 * - Questions are automatically classified by PIRLS process
 * - Passages are classified by reading purpose
 * - Student performance tracked per process and purpose
 * - Vocabulary extracted from passages for tracking
 */
// MARK: - 📚 PIRLS FRAMEWORK - Reading Comprehension Assessment System
// PIRLS (Progress in International Reading Literacy Study) Framework Implementation
// Designed for primary school students (ages 6-12, levels 1-6)

// MARK: - 🔍 PIRLS Reading Comprehension Processes
enum PIRLSProcess: String, Codable, CaseIterable {
    case retrieving = "retrieving"      // Finding explicitly stated information
    case inferring = "inferring"         // Drawing straightforward inferences
    case interpreting = "interpreting"   // Interpreting and integrating ideas
    case evaluating = "evaluating"       // Examining and evaluating content
    
    var displayName: String {
        switch self {
        case .retrieving: return "檢索理解"
        case .inferring: return "推論理解"
        case .interpreting: return "詮釋理解"
        case .evaluating: return "評價理解"
        }
    }
    
    var description: String {
        switch self {
        case .retrieving:
            return "直接從文本中找到明確說明的資訊"
        case .inferring:
            return "根據文本內容進行合理的推論"
        case .interpreting:
            return "解釋和整合文本中的想法與資訊"
        case .evaluating:
            return "檢視和評價文本的內容與形式"
        }
    }
}

// MARK: - 📖 Reading Purpose Classification
enum ReadingPurpose: String, Codable, CaseIterable {
    case literary = "literary"           // Literary texts (stories, narratives)
    case informational = "informational" // Informational texts (expository, factual)
    
    var displayName: String {
        switch self {
        case .literary: return "文學類"
        case .informational: return "資訊類"
        }
    }
    
    var description: String {
        switch self {
        case .literary:
            return "故事、敘述性文本，注重情節和角色"
        case .informational:
            return "說明性、事實性文本，注重資訊傳達"
        }
    }
}

// MARK: - 📊 PIRLS Process Performance Metrics
struct PIRLSProcessPerformance: Codable {
    var process: PIRLSProcess
    var totalQuestions: Int = 0
    var correctAnswers: Int = 0
    var averageResponseTime: TimeInterval = 0
    var masteryLevel: Double = 0.0  // 0.0 to 1.0
    
    var accuracyRate: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }
    
    mutating func updatePerformance(isCorrect: Bool, responseTime: TimeInterval) {
        totalQuestions += 1
        if isCorrect {
            correctAnswers += 1
        }
        
        // Update average response time
        let totalTime = averageResponseTime * Double(totalQuestions - 1) + responseTime
        averageResponseTime = totalTime / Double(totalQuestions)
        
        // Calculate mastery level (weighted by accuracy and speed)
        let speedFactor = min(1.0, 30.0 / max(responseTime, 1.0))  // Faster = better
        masteryLevel = accuracyRate * 0.7 + speedFactor * 0.3
    }
}

// MARK: - 📈 PIRLS Assessment Summary
struct PIRLSAssessment: Codable {
    var studentLevel: Int  // 1-6 (Primary 1-6)
    var processPerformance: [PIRLSProcess: PIRLSProcessPerformance]
    var readingPurposePerformance: [ReadingPurpose: Double]  // Accuracy rates
    var overallScore: Double
    var assessmentDate: Date
    var vocabularyMastery: Double
    
    init(studentLevel: Int) {
        self.studentLevel = studentLevel
        self.processPerformance = [:]
        self.readingPurposePerformance = [:]
        self.overallScore = 0.0
        self.assessmentDate = Date()
        self.vocabularyMastery = 0.0
        
        // Initialize all processes
        for process in PIRLSProcess.allCases {
            processPerformance[process] = PIRLSProcessPerformance(process: process)
        }
        
        // Initialize reading purposes
        for purpose in ReadingPurpose.allCases {
            readingPurposePerformance[purpose] = 0.0
        }
    }
    
    mutating func updateOverallScore() {
        let processScores = processPerformance.values.map { $0.masteryLevel }
        overallScore = processScores.isEmpty ? 0.0 : processScores.reduce(0, +) / Double(processScores.count)
    }
    
    func getWeakestProcess() -> PIRLSProcess? {
        return processPerformance.min(by: { $0.value.masteryLevel < $1.value.masteryLevel })?.key
    }
    
    func getStrongestProcess() -> PIRLSProcess? {
        return processPerformance.max(by: { $0.value.masteryLevel < $1.value.masteryLevel })?.key
    }
}

// MARK: - 🎯 Question Classification Helper
class PIRLSQuestionClassifier {
    /**
     * Enhanced classification with multi-factor analysis
     * Priority order: Evaluating > Retrieving > Interpreting > Inferring
     * Falls back to original method if answer is not provided
     */
    static func classifyQuestion(_ questionText: String, passageText: String) -> PIRLSProcess {
        // Use enhanced classification if possible, fall back to basic
        let (process, _) = classifyQuestionEnhanced(questionText, passageText: passageText, answer: nil)
        return process
    }
    
    /**
     * Enhanced classification with multi-factor analysis and confidence scoring
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
     * Extract keywords from text (helper for classification)
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
    
    static func classifyReadingPurpose(_ passageText: String) -> ReadingPurpose {
        let lowerPassage = passageText.lowercased()
        
        // Literary indicators
        let literaryKeywords = ["故事", "角色", "主角", "情節", "對話", "敘述", "描述", "發生", "一天", "早晨", "派對", "朋友"]
        let literaryCount = literaryKeywords.filter { lowerPassage.contains($0) }.count
        
        // Informational indicators
        let informationalKeywords = ["說明", "介紹", "解釋", "原因", "方法", "特徵", "特點", "功能", "作用", "季節", "變化"]
        let informationalCount = informationalKeywords.filter { lowerPassage.contains($0) }.count
        
        return literaryCount >= informationalCount ? .literary : .informational
    }
    
    static func extractKeyVocabulary(_ passageText: String, maxWords: Int = 10) -> [String] {
        // Use enhanced extraction with default difficulty
        let enhanced = extractKeyVocabularyEnhanced(passageText, maxWords: maxWords, difficultyLevel: nil)
        return enhanced.map { $0.word }
    }
    
    /**
     * Enhanced vocabulary extraction with difficulty levels and importance scoring
     */
    static func extractKeyVocabularyEnhanced(_ passageText: String, maxWords: Int = 15, difficultyLevel: Int? = nil) -> [(word: String, difficulty: Int, importance: Double)] {
        // ✅ Extract individual Chinese characters and 2-character words
        // For Chinese text, we need to split by characters and identify meaningful words
        
        // ✅ Remove punctuation and whitespace
        let cleanedText = passageText.components(separatedBy: CharacterSet.punctuationCharacters.union(.whitespaces))
            .joined()
        
        // ✅ Extract individual Chinese characters (excluding common particles)
        let commonParticles = ["的", "了", "在", "是", "和", "有", "就", "也", "都", "與", "及", "或", "。", "，", "！", "？", "：", "；"]
        var charCounts: [String: Int] = [:]
        
        // ✅ Count individual characters
        for char in cleanedText {
            let charStr = String(char)
            // Only count Chinese characters (CJK Unified Ideographs)
            if char.unicodeScalars.first?.properties.isIdeographic == true {
                if !commonParticles.contains(charStr) {
                    charCounts[charStr, default: 0] += 1
                }
            }
        }
        
        // ✅ Extract 2-character words (common Chinese word patterns)
        var wordCounts: [String: Int] = [:]
        let chars = Array(cleanedText)
        for i in 0..<(chars.count - 1) {
            let char1 = String(chars[i])
            let char2 = String(chars[i + 1])
            // Check if both are Chinese characters
            if chars[i].unicodeScalars.first?.properties.isIdeographic == true &&
               chars[i + 1].unicodeScalars.first?.properties.isIdeographic == true {
                let word = char1 + char2
                // Exclude if either character is a common particle
                if !commonParticles.contains(char1) && !commonParticles.contains(char2) {
                    wordCounts[word, default: 0] += 1
                }
            }
        }
        
        // ✅ Combine and score vocabulary
        var scoredVocabulary: [(word: String, difficulty: Int, importance: Double)] = []
        
        // Add 2-character words
        for (word, count) in wordCounts {
            let difficulty = estimateWordDifficulty(word)
            let importance = calculateWordImportance(word, in: passageText, count: count)
            scoredVocabulary.append((word: word, difficulty: difficulty, importance: importance))
        }
        
        // Add single characters
        for (char, count) in charCounts {
            let difficulty = estimateWordDifficulty(char)
            let importance = calculateWordImportance(char, in: passageText, count: count)
            scoredVocabulary.append((word: char, difficulty: difficulty, importance: importance))
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
        
        // Remove duplicates (if a 2-char word contains a single char, prefer the word)
        var finalVocabulary: [(word: String, difficulty: Int, importance: Double)] = []
        var usedChars: Set<String> = []
        
        for item in scoredVocabulary {
            if item.word.count == 2 {
                // 2-character word - add it and mark both chars as used
                finalVocabulary.append(item)
                usedChars.insert(String(item.word.first!))
                usedChars.insert(String(item.word.last!))
            } else if item.word.count == 1 && !usedChars.contains(item.word) {
                // Single character - only add if not part of a word we already added
                finalVocabulary.append(item)
                usedChars.insert(item.word)
            }
            
            if finalVocabulary.count >= maxWords {
                break
            }
        }
        
        return finalVocabulary
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
    private static func calculateWordImportance(_ word: String, in passageText: String, count: Int) -> Double {
        var importance: Double = 0.0
        
        // Factor 1: Frequency (normalized)
        let totalWords = passageText.count / 2  // Rough estimate
        let frequency = Double(count) / Double(max(totalWords, 1))
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
}

