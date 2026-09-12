import Foundation

/**
 * VOCABULARY MANAGER - Vocabulary Tracking & Mastery System
 * 
 * Manages student vocabulary acquisition and mastery tracking.
 * This singleton class handles:
 * - Extracting vocabulary from reading passages
 * - Tracking word encounters and correct usage
 * - Calculating mastery levels (0-5 scale)
 * - Persisting vocabulary data locally
 * - Syncing with Alibaba ECS backend
 * 
 * Mastery Levels:
 * - 0: New word (never encountered)
 * - 1-2: Learning (encountered but not mastered)
 * - 3: Practicing (somewhat familiar)
 * - 4: Proficient (mostly mastered)
 * - 5: Mastered (fully learned)
 * 
 * Vocabulary Extraction:
 * - Extracts individual Chinese characters and 2-character words
 * - Filters out common particles (的, 了, 在, etc.)
 * - Prioritizes meaningful words over single characters
 * - Uses PIRLSQuestionClassifier for extraction
 * 
 * Data Persistence:
 * - Stores vocabulary in UserDefaults
 * - Automatically saves after each update
 * - Can sync to/from Alibaba ECS backend
 */
// MARK: - 📚 VOCABULARY MANAGER - Vocabulary Tracking & Mastery System
class VocabularyManager {
    static let shared = VocabularyManager()  // Singleton pattern
    
    // MARK: - 🔑 USER DEFAULTS KEYS
    private let vocabularyKey = "studentVocabulary"
    
    // MARK: - 📖 VOCABULARY STORAGE
    private var vocabularyWords: [String: VocabularyWord] = [:]  // Dictionary for quick lookup
    
    private init() {
        loadVocabulary()
        enrichStoredVocabularyFromGlossary()
    }
    
    // MARK: - Load & Save Vocabulary
    private func loadVocabulary() {
        guard let data = UserDefaults.standard.data(forKey: vocabularyKey),
              let decoded = try? JSONDecoder().decode([String: VocabularyWord].self, from: data) else {
            vocabularyWords = [:]
            return
        }
        vocabularyWords = decoded
    }
    
    private func saveVocabulary() {
        if let encoded = try? JSONEncoder().encode(vocabularyWords) {
            UserDefaults.standard.set(encoded, forKey: vocabularyKey)
        }
    }

    /// Fill empty pinyin/meaning from the offline glossary without wiping progress.
    private func enrichStoredVocabularyFromGlossary() {
        var changed = false
        for (key, var word) in vocabularyWords {
            let beforePinyin = word.pinyin
            let beforeMeaning = word.meaning
            word.applyGlossaryIfNeeded()
            if word.pinyin != beforePinyin || word.meaning != beforeMeaning {
                vocabularyWords[key] = word
                changed = true
            }
        }
        if changed {
            saveVocabulary()
        }
    }

    /// Small offline starter set so practice works before/without empty extractions.
    private static let seedPracticeWords: [String] = [
        "派對", "花園", "分享", "快樂", "季節", "春天", "秋天", "遷徙",
        "氣候", "冒險", "溫暖", "植物", "生長", "陽光", "閱讀", "圖書館",
        "行星", "地球", "春節", "傳統", "回收", "分類", "環保", "合作"
    ]

    /// Persist a compact curated seed only when nothing is practice-ready.
    func ensureSeedVocabularyIfNeeded() {
        let practiceReadyCount = vocabularyWords.values.filter { $0.isPracticeReady }.count
        guard practiceReadyCount == 0 else { return }

        for word in Self.seedPracticeWords {
            guard let entry = VocabularyGlossary.lookup(word) else { continue }
            if var existing = vocabularyWords[word] {
                existing.applyGlossaryIfNeeded()
                vocabularyWords[word] = existing
            } else {
                vocabularyWords[word] = VocabularyWord(
                    word: word,
                    pinyin: entry.pinyin,
                    meaning: entry.meaning,
                    masteryLevel: 0,
                    encounters: 0,
                    correctUses: 0
                )
            }
        }
        saveVocabulary()
    }
    
    // MARK: - Extract Vocabulary from Passage
    func extractVocabulary(from passageText: String, maxWords: Int = 15) -> [VocabularyWord] {
        // Use enhanced extraction with default difficulty
        return extractVocabularyEnhanced(from: passageText, maxWords: maxWords, targetDifficulty: nil)
    }
    
    /**
     * Extract vocabulary with difficulty assessment
     * Enhanced version with difficulty levels and importance scoring
     */
    func extractVocabularyEnhanced(from passageText: String, maxWords: Int = 15, targetDifficulty: Int? = nil) -> [VocabularyWord] {
        // Use enhanced extraction with difficulty levels
        let extractedWords = PIRLSQuestionClassifier.extractKeyVocabularyEnhanced(
            passageText,
            maxWords: maxWords * 2,
            difficultyLevel: targetDifficulty
        )
        
        var vocabularyList: [VocabularyWord] = []
        for (word, difficulty, _) in extractedWords {
            let gloss = VocabularyGlossary.gloss(for: word)
            if var existingWord = vocabularyWords[word] {
                existingWord.applyGlossaryIfNeeded()
                // Update with enhanced mastery if needed
                existingWord.updateMasteryEnhanced(difficulty: difficulty)
                vocabularyWords[word] = existingWord
                vocabularyList.append(existingWord)
            } else {
                // Create new vocabulary word; only glossary-backed glosses are practice-ready
                var newWord = VocabularyWord(
                    word: word,
                    pinyin: gloss.pinyin,
                    meaning: gloss.meaning,
                    masteryLevel: 0,
                    encounters: 0,
                    correctUses: 0
                )
                // Initialize with enhanced mastery calculation
                newWord.updateMasteryEnhanced(difficulty: difficulty)
                vocabularyWords[word] = newWord
                vocabularyList.append(newWord)
            }
        }
        
        // Sort by importance and difficulty relevance
        vocabularyList.sort { word1, word2 in
            // Prioritize words at target difficulty level
            if let target = targetDifficulty {
                // Sort by mastery (lower mastery = more important to learn)
                return word1.masteryLevel < word2.masteryLevel
            }
            return word1.masteryLevel < word2.masteryLevel
        }
        
        saveVocabulary()
        return Array(vocabularyList.prefix(maxWords))
    }
    
    // MARK: - Link Vocabulary to PIRLS Processes (Phase 4.2)
    /**
     * Links vocabulary words to specific PIRLS processes based on passage context.
     */
    func linkVocabularyToProcess(_ word: String, process: PIRLSProcess, passageKey: String) {
        if var vocabularyWord = vocabularyWords[word] {
            // Store process associations (in real implementation, this would be more sophisticated)
            // For now, we track which processes the word appears in
            vocabularyWords[word] = vocabularyWord
            saveVocabulary()
        }
    }
    
    // MARK: - Get Vocabulary by Process (Phase 4.2)
    /**
     * Returns vocabulary words relevant to a specific PIRLS process.
     * This is based on which passages (and their questions) use the word.
     */
    func getVocabularyByProcess(_ process: PIRLSProcess) -> [VocabularyWord] {
        // In a more sophisticated implementation, we would track process associations
        // For now, return all vocabulary (can be enhanced with actual process tracking)
        return Array(vocabularyWords.values)
    }
    
    // MARK: - Get Vocabulary by Reading Purpose (Phase 4.2)
    /**
     * Returns vocabulary from passages of a specific reading purpose.
     */
    func getVocabularyByReadingPurpose(_ purpose: ReadingPurpose) -> [VocabularyWord] {
        // Get vocabulary from passages matching the reading purpose
        var relevantWords: [VocabularyWord] = []
        let allPassageKeys = ["passage1", "passage2", "passage3", "passage4", "passage5", "passage6", "passage7", "passage8", "passage9"]
        
        for passageKey in allPassageKeys {
            if let passageSet = QuestionBank.shared.getPassageSet(for: passageKey) {
                let passagePurpose = PIRLSQuestionClassifier.classifyReadingPurpose(passageSet.passage)
                if passagePurpose == purpose {
                    let vocab = extractVocabulary(from: passageSet.passage, maxWords: 10)
                    relevantWords.append(contentsOf: vocab)
                }
            }
        }
        
        // Remove duplicates
        var uniqueWords: [String: VocabularyWord] = [:]
        for word in relevantWords {
            uniqueWords[word.word] = word
        }
        
        return Array(uniqueWords.values)
    }
    
    // MARK: - Get Vocabulary for Current Level (Phase 4.2)
    /**
     * Returns vocabulary relevant to student's current reading level.
     */
    func getVocabularyForLevel(_ level: Int) -> [VocabularyWord] {
        // Get vocabulary from passages appropriate for this level
        var relevantWords: [VocabularyWord] = []
        let allPassageKeys = ["passage1", "passage2", "passage3", "passage4", "passage5", "passage6", "passage7", "passage8", "passage9"]
        
        // Map passage keys to approximate difficulty levels based on known passage structure
        let passageLevelMap: [String: Int] = [
            "passage1": 1,  // 小兔子的派對 (P1-P2)
            "passage2": 2,  // 四季變化 (P2-P3)
            "passage3": 3,  // 小鳥的遷徙 (P3-P4)
            "passage4": 2,  // 小貓咪的冒險 (P2-P3)
            "passage5": 3,  // 植物的生長 (P3-P4)
            "passage6": 4,  // 小明的圖書館之旅 (P4-P5)
            "passage7": 5,  // 太陽系的行星 (P5-P6)
            "passage8": 4,  // 傳統節日 (P4-P5)
            "passage9": 2   // 學校的回收日 (P2-P3)
        ]
        
        for passageKey in allPassageKeys {
            if let passageSet = QuestionBank.shared.getPassageSet(for: passageKey) {
                // Check if passage is appropriate for this level
                let passageLevel = passageLevelMap[passageKey] ?? level
                if abs(passageLevel - level) <= 1 {  // Within 1 level
                    let vocab = extractVocabulary(from: passageSet.passage, maxWords: 10)
                    relevantWords.append(contentsOf: vocab)
                }
            }
        }
        
        // Remove duplicates and sort by mastery
        var uniqueWords: [String: VocabularyWord] = [:]
        for word in relevantWords {
            uniqueWords[word.word] = word
        }
        
        return Array(uniqueWords.values).sorted { $0.masteryLevel < $1.masteryLevel }
    }
    
    // MARK: - Suggest Vocabulary Review (Phase 4.2)
    /**
     * Suggests vocabulary words to review based on upcoming passages.
     */
    func suggestVocabularyReview(upcomingPassageKeys: [String]) -> [VocabularyWord] {
        var reviewWords: [VocabularyWord] = []
        
        for passageKey in upcomingPassageKeys {
            if let passageSet = QuestionBank.shared.getPassageSet(for: passageKey) {
                let vocab = extractVocabulary(from: passageSet.passage, maxWords: 15)
                reviewWords.append(contentsOf: vocab)
            }
        }
        
        // Prioritize words with low mastery
        let sortedWords = reviewWords.sorted { word1, word2 in
            if word1.masteryLevel != word2.masteryLevel {
                return word1.masteryLevel < word2.masteryLevel
            }
            return word1.encounters < word2.encounters
        }
        
        return Array(sortedWords.prefix(20))
    }
    
    // MARK: - Track Word Encounter
    func trackWordEncounter(_ word: String, isCorrect: Bool, context: String? = nil) {
        if var vocabularyWord = vocabularyWords[word] {
            vocabularyWord.applyGlossaryIfNeeded()
            vocabularyWord.addEncounter(isCorrect: isCorrect, context: context)
            vocabularyWords[word] = vocabularyWord
        } else {
            // Create new word entry and apply offline gloss when available
            var newWord = VocabularyWord(word: word)
            newWord.applyGlossaryIfNeeded()
            newWord.addEncounter(isCorrect: isCorrect, context: context)
            vocabularyWords[word] = newWord
        }
        saveVocabulary()
    }
    
    // MARK: - Get Vocabulary Word
    func getVocabularyWord(_ word: String) -> VocabularyWord? {
        return vocabularyWords[word]
    }
    
    // MARK: - Get All Vocabulary
    func getAllVocabulary() -> [VocabularyWord] {
        return Array(vocabularyWords.values).sorted { $0.lastSeen > $1.lastSeen }
    }

    // MARK: - Practice-Ready Vocabulary
    /// Words with usable meanings only — never practice empty-gloss extractions.
    func getPracticeVocabulary(limit: Int = 20) -> [VocabularyWord] {
        enrichStoredVocabularyFromGlossary()
        if vocabularyWords.values.filter({ $0.isPracticeReady }).isEmpty {
            ensureSeedVocabularyIfNeeded()
        }

        func accuracy(_ w: VocabularyWord) -> Double {
            guard w.encounters > 0 else { return 0 }
            return Double(w.correctUses) / Double(w.encounters)
        }

        let ready = vocabularyWords.values.filter { $0.isPracticeReady }
        let needsReview = ready.filter { $0.masteryLevel < 4 }
            .sorted { a, b in
                if a.masteryLevel != b.masteryLevel { return a.masteryLevel < b.masteryLevel }
                if accuracy(a) != accuracy(b) { return accuracy(a) < accuracy(b) }
                return a.encounters > b.encounters
            }

        let ordered = needsReview.isEmpty
            ? ready.sorted { a, b in
                if a.masteryLevel != b.masteryLevel { return a.masteryLevel < b.masteryLevel }
                return accuracy(a) < accuracy(b)
            }
            : needsReview

        return Array(ordered.prefix(limit))
    }
    
    // MARK: - Get Vocabulary by Mastery Level
    func getVocabularyByMastery(_ level: Int) -> [VocabularyWord] {
        return vocabularyWords.values.filter { $0.masteryLevel == level }
    }
    
    // MARK: - Get Vocabulary Statistics
    func getStatistics() -> VocabularyStats {
        let allWords = Array(vocabularyWords.values)
        return VocabularyStats(
            totalWords: allWords.count,
            masteredWords: allWords.filter { $0.masteryLevel == 5 }.count,
            proficientWords: allWords.filter { $0.masteryLevel == 4 }.count,
            learningWords: allWords.filter { (1...3).contains($0.masteryLevel) }.count,
            newWords: allWords.filter { $0.masteryLevel == 0 }.count
        )
    }
    
    // MARK: - Get Words Needing Review
    func getWordsNeedingReview(maxDays: Int = 7) -> [VocabularyWord] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -maxDays, to: Date()) ?? Date()
        return vocabularyWords.values.filter { word in
            word.lastSeen < cutoffDate && word.masteryLevel < 5
        }.sorted { $0.lastSeen < $1.lastSeen }
    }
    
    // MARK: - Sync with Alibaba ECS
    func syncVocabularyToServer(completion: @escaping (Bool) -> Void) {
        guard let url = QuestionBankAPI.vocabularyTrackingURL() else {
            completion(false)
            return
        }
        
        let vocabularyData = Array(vocabularyWords.values)
        guard let jsonData = try? JSONEncoder().encode(vocabularyData) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  error == nil else {
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }
    
    // MARK: - Update Vocabulary from Server
    func updateVocabularyFromServer(completion: @escaping (Bool) -> Void) {
        guard let url = QuestionBankAPI.vocabularyTrackingURL() else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  error == nil,
                  let serverVocabulary = try? JSONDecoder().decode([VocabularyWord].self, from: data) else {
                completion(false)
                return
            }
            
            // Merge server data with local data
            for word in serverVocabulary {
                if let localWord = self?.vocabularyWords[word.word] {
                    // Merge: keep higher mastery level and more encounters
                    var mergedWord = localWord
                    if word.masteryLevel > localWord.masteryLevel {
                        mergedWord.masteryLevel = word.masteryLevel
                    }
                    if word.encounters > localWord.encounters {
                        mergedWord.encounters = word.encounters
                        mergedWord.correctUses = word.correctUses
                    }
                    self?.vocabularyWords[word.word] = mergedWord
                } else {
                    self?.vocabularyWords[word.word] = word
                }
            }
            
            self?.saveVocabulary()
            completion(true)
        }.resume()
    }
}

