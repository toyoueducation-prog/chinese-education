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
     * Uses the local QuestionBank only (offline-first).
     */
    func getRecommendedPassages(_ profile: StudentProfile, count: Int = 3) -> [String] {
        let weakProcesses = getWeakProcesses(profile)
        let allPassageKeys = QuestionBank.shared.getAllPassageKeys()
        
        var passageScores: [(key: String, score: Int)] = []
        
        for passageKey in allPassageKeys {
            var score = 0
            
            if let passageSet = QuestionBank.shared.getPassageSet(for: passageKey) {
                for questionKey in passageSet.questionKeys {
                    if let question = QuestionBank.shared.getQuestion(forKey: questionKey) {
                        let enriched = QuestionBank.shared.enrichQuestionWithPIRLS(question, passageText: passageSet.passage)
                        
                        if let process = enriched.pirlsProcess, weakProcesses.contains(process) {
                            score += 3
                        } else {
                            score += 1
                        }
                    }
                }
            }
            
            passageScores.append((key: passageKey, score: score))
        }
        
        passageScores.sort { $0.score > $1.score }
        return Array(passageScores.prefix(count).map { $0.key })
    }
    
    // MARK: - Live Quiz Encounter Selection
    /**
     * Picks the next map-flow quiz encounter using DifficultyManager,
     * InterventionEngine, and weak-process / answer-history signals.
     * Falls back to the first incomplete local passage when profile data is sparse.
     */
    func selectNextEncounter(
        profile: StudentProfile = .shared,
        completedPassageTexts: [String] = [],
        questionCount: Int = 4
    ) -> AdaptiveEncounterSelection? {
        let bank = QuestionBank.shared
        let allSets = bank.getAllPassageSets()
        guard !allSets.isEmpty else { return nil }
        
        let completed = Set(completedPassageTexts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        var candidates = allSets.filter {
            !completed.contains($0.passage.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        // If every passage is complete, allow recycling the full bank (caller may also clear completions).
        if candidates.isEmpty {
            candidates = allSets
        }
        
        let targetDifficulty = DifficultyManager.shared.calculateOptimalDifficulty(for: profile)
        let weakProcesses = getWeakProcesses(profile)
        let interventionNeeds = InterventionEngine.shared.identifyStrugglingAreas(profile)
        let focusProcesses = focusProcesses(from: weakProcesses, needs: interventionNeeds, profile: profile)
        let historyMisses = AnswerHistoryStore.shared.recentProcessMissCounts(forStudentID: profile.studentID)
        let unlocked = Set(checkContentUnlocking(profile))
        let recommended = Set(getRecommendedPassages(profile, count: max(3, candidates.count)))
        let interventionPassages = Set(
            focusProcesses.flatMap { InterventionEngine.shared.getProcessInterventionStrategy($0).passages }
        )
        
        var scored: [(set: PassageQuestionSet, score: Int, questions: [Question])] = []
        
        for passageSet in candidates {
            let enrichedQuestions = passageSet.questionKeys.compactMap { key -> Question? in
                guard let question = bank.getQuestion(forKey: key) else { return nil }
                return bank.enrichQuestionWithPIRLS(question, passageText: passageSet.passage)
            }
            guard !enrichedQuestions.isEmpty else { continue }
            
            var score = 0
            
            // Difficulty proximity (±1 preferred, ±2 still useful)
            let difficulties = enrichedQuestions.compactMap { $0.difficultyLevel }
            if let closest = difficulties.min(by: { abs($0 - targetDifficulty) < abs($1 - targetDifficulty) }) {
                let delta = abs(closest - targetDifficulty)
                if delta == 0 { score += 8 }
                else if delta == 1 { score += 5 }
                else if delta == 2 { score += 2 }
            }
            
            // Weak / intervention process coverage
            for question in enrichedQuestions {
                guard let process = question.pirlsProcess else { continue }
                if focusProcesses.contains(process) {
                    score += 6
                }
                if let misses = historyMisses[process], misses > 0 {
                    score += min(4, misses)  // recent wrong answers on this process
                }
            }
            
            if unlocked.contains(passageSet.passageKey) {
                score += 3
            }
            if recommended.contains(passageSet.passageKey) {
                score += 4
            }
            if interventionPassages.contains(passageSet.passageKey) {
                score += 5
            }
            
            // Light preference for unread content already handled by candidate filter
            scored.append((set: passageSet, score: score, questions: enrichedQuestions))
        }
        
        guard !scored.isEmpty else { return nil }
        
        scored.sort { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.set.passageKey < rhs.set.passageKey
        }
        
        let best = scored[0]
        let orderedQuestions = orderQuestionsForEncounter(
            best.questions,
            targetDifficulty: targetDifficulty,
            focusProcesses: focusProcesses,
            count: questionCount
        )
        
        let reason = selectionReason(
            passageKey: best.set.passageKey,
            score: best.score,
            targetDifficulty: targetDifficulty,
            focusProcesses: focusProcesses
        )
        
        return AdaptiveEncounterSelection(
            passageKey: best.set.passageKey,
            passageText: best.set.passage,
            questions: orderedQuestions,
            targetDifficulty: targetDifficulty,
            focusProcesses: focusProcesses,
            selectionReason: reason
        )
    }
    
    /// Orders (and lightly filters) a passage's questions for the live quiz.
    func orderQuestionsForEncounter(
        _ questions: [Question],
        targetDifficulty: Int,
        focusProcesses: [PIRLSProcess],
        count: Int = 4
    ) -> [Question] {
        // Prefer difficulty band first, then keep remaining so the encounter stays complete.
        var selected = DifficultyManager.shared.selectQuestionsByDifficulty(
            questions,
            targetDifficulty: targetDifficulty,
            count: count
        )
        
        let selectedKeys = Set(selected.map { $0.key })
        for question in questions where !selectedKeys.contains(question.key) {
            selected.append(question)
            if selected.count >= max(count, questions.count) { break }
        }
        
        // Surface focus-process items earlier without dropping others.
        selected.sort { lhs, rhs in
            let lFocus = lhs.pirlsProcess.map { focusProcesses.contains($0) } ?? false
            let rFocus = rhs.pirlsProcess.map { focusProcesses.contains($0) } ?? false
            if lFocus != rFocus { return lFocus && !rFocus }
            let lDiff = abs((lhs.difficultyLevel ?? targetDifficulty) - targetDifficulty)
            let rDiff = abs((rhs.difficultyLevel ?? targetDifficulty) - targetDifficulty)
            if lDiff != rDiff { return lDiff < rDiff }
            return lhs.key < rhs.key
        }
        
        return Array(selected.prefix(max(count, 1)))
    }
    
    // MARK: - Get Weak Processes
    /// Processes with recorded attempts and mastery below threshold.
    func getWeakProcesses(_ profile: StudentProfile) -> [PIRLSProcess] {
        var weakProcesses: [PIRLSProcess] = []
        let threshold: Double = 0.6
        
        for process in PIRLSProcess.allCases {
            if let performance = profile.pirlsAssessment.processPerformance[process],
               performance.totalQuestions > 0,
               performance.masteryLevel < threshold {
                weakProcesses.append(process)
            }
        }
        
        return weakProcesses
    }
    
    private func focusProcesses(
        from weakProcesses: [PIRLSProcess],
        needs: [InterventionNeed],
        profile: StudentProfile
    ) -> [PIRLSProcess] {
        var ordered: [PIRLSProcess] = []
        
        for need in needs where need.type == .process {
            if let process = PIRLSProcess(rawValue: need.target), !ordered.contains(process) {
                ordered.append(process)
            }
        }
        
        for process in weakProcesses where !ordered.contains(process) {
            ordered.append(process)
        }
        
        if ordered.isEmpty, let weakest = profile.weakestProcess,
           let perf = profile.pirlsAssessment.processPerformance[weakest],
           perf.totalQuestions > 0 {
            ordered.append(weakest)
        }
        
        return ordered
    }
    
    private func selectionReason(
        passageKey: String,
        score: Int,
        targetDifficulty: Int,
        focusProcesses: [PIRLSProcess]
    ) -> String {
        let processNames = focusProcesses.map { $0.rawValue }.joined(separator: ",")
        let focusPart = processNames.isEmpty ? "none" : processNames
        return "passage=\(passageKey) score=\(score) difficulty=\(targetDifficulty) focus=[\(focusPart)]"
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
        let allPassageKeys = QuestionBank.shared.getAllPassageKeys()
        
        // Simple unlocking: level 1-2 get early passages, mid levels expand, 5-6 unlock all
        if level >= 1 {
            unlockedContent.append(contentsOf: allPassageKeys.filter { ["passage1", "passage2", "passage9", "passage10", "passage11", "passage12"].contains($0) })
        }
        if level >= 3 {
            unlockedContent.append(contentsOf: allPassageKeys.filter { ["passage3", "passage4", "passage5", "passage13", "passage14"].contains($0) })
        }
        if level >= 4 {
            unlockedContent.append(contentsOf: allPassageKeys.filter { ["passage6", "passage8", "passage15", "passage16"].contains($0) })
        }
        if level >= 5 {
            unlockedContent.append(contentsOf: allPassageKeys)
        }
        
        // Deduplicate while preserving order
        var seen = Set<String>()
        return unlockedContent.filter { seen.insert($0).inserted }
    }
}

// MARK: - Data Structures
struct AdaptiveEncounterSelection {
    let passageKey: String
    let passageText: String
    let questions: [Question]
    let targetDifficulty: Int
    let focusProcesses: [PIRLSProcess]
    let selectionReason: String
}

struct ReadingPurposeRecommendation {
    let needsBalance: Bool
    let weakerPurpose: ReadingPurpose?
    let recommendedPassages: [String]
    let targetRatio: Double
    let currentRatio: Double
}

