import Foundation

/**
 * INTERVENTION ENGINE - Automatic Identification and Recommendations
 * 
 * Features:
 * - Automatic identification of struggling areas
 * - Targeted practice recommendations
 * - Process-specific intervention strategies
 * - Vocabulary support for weak areas
 * - Reading purpose adjustment suggestions
 */
// MARK: - 🎯 INTERVENTION ENGINE
class InterventionEngine {
    static let shared = InterventionEngine()
    
    private init() {}
    
    // MARK: - Identify Struggling Areas
    /**
     * Automatically identifies areas where student is struggling.
     * Returns list of intervention needs sorted by priority.
     */
    func identifyStrugglingAreas(_ profile: StudentProfile) -> [InterventionNeed] {
        var needs: [InterventionNeed] = []
        let analytics = PIRLSAnalytics.shared
        
        // Check PIRLS processes
        for process in PIRLSProcess.allCases {
            if let performance = profile.pirlsAssessment.processPerformance[process] {
                if performance.masteryLevel < 0.5 {
                    needs.append(InterventionNeed(
                        type: .process,
                        target: process.rawValue,
                        severity: performance.masteryLevel < 0.3 ? .high : .medium,
                        currentLevel: performance.masteryLevel,
                        targetLevel: 0.7
                    ))
                }
            }
        }
        
        // Check vocabulary
        if profile.vocabularyMastery < 0.5 {
            needs.append(InterventionNeed(
                type: .vocabulary,
                target: "vocabulary",
                severity: profile.vocabularyMastery < 0.3 ? .high : .medium,
                currentLevel: profile.vocabularyMastery,
                targetLevel: 0.7
            ))
        }
        
        // Check reading purpose balance
        let balance = ReadingPurposeTracker.shared.calculateBalance(profile)
        if !balance.isBalanced {
            let difference = abs(balance.literary - balance.informational)
            needs.append(InterventionNeed(
                type: .readingPurpose,
                target: balance.literary < balance.informational ? "literary" : "informational",
                severity: difference > 0.4 ? .high : .medium,
                currentLevel: min(balance.literary, balance.informational),
                targetLevel: 0.4
            ))
        }
        
        // Sort by severity
        needs.sort { $0.severity.rawValue > $1.severity.rawValue }
        
        return needs
    }
    
    // MARK: - Generate Targeted Practice Recommendations
    /**
     * Generates specific practice recommendations for struggling areas.
     */
    func generateTargetedPractice(_ needs: [InterventionNeed]) -> [PracticeRecommendation] {
        var recommendations: [PracticeRecommendation] = []
        
        for need in needs.prefix(5) {  // Top 5 needs
            switch need.type {
            case .process:
                if let process = PIRLSProcess.allCases.first(where: { $0.rawValue == need.target }) {
                    recommendations.append(createProcessPracticeRecommendation(process, need: need))
                }
            case .vocabulary:
                recommendations.append(createVocabularyPracticeRecommendation(need: need))
            case .readingPurpose:
                recommendations.append(createReadingPurposeRecommendation(need: need))
            }
        }
        
        return recommendations
    }
    
    // MARK: - Process-Specific Intervention Strategies
    /**
     * Provides intervention strategies for specific PIRLS processes.
     */
    func getProcessInterventionStrategy(_ process: PIRLSProcess) -> InterventionStrategy {
        let strategies: [PIRLSProcess: InterventionStrategy] = [
            .retrieving: InterventionStrategy(
                process: process,
                focusAreas: [
                    "練習快速定位文本中的關鍵資訊",
                    "注意問題中的關鍵詞",
                    "練習找出明確說明的答案"
                ],
                practiceTypes: ["檢索練習", "關鍵詞識別", "快速定位"],
                estimatedTime: "每天15-20分鐘",
                passages: ["passage1", "passage2", "passage4"]
            ),
            .inferring: InterventionStrategy(
                process: process,
                focusAreas: [
                    "練習根據文本線索進行推論",
                    "注意文本中的暗示和隱含意思",
                    "練習連接文本中的不同資訊"
                ],
                practiceTypes: ["推論練習", "線索識別", "資訊連接"],
                estimatedTime: "每天20-25分鐘",
                passages: ["passage3", "passage5", "passage6"]
            ),
            .interpreting: InterventionStrategy(
                process: process,
                focusAreas: [
                    "練習理解文本的整體意義",
                    "練習整合不同段落的信息",
                    "練習解釋文本中的概念和想法"
                ],
                practiceTypes: ["詮釋練習", "整體理解", "概念解釋"],
                estimatedTime: "每天25-30分鐘",
                passages: ["passage6", "passage7", "passage8"]
            ),
            .evaluating: InterventionStrategy(
                process: process,
                focusAreas: [
                    "練習評價文本的內容和觀點",
                    "練習判斷文本的可靠性和有效性",
                    "練習比較不同文本的觀點"
                ],
                practiceTypes: ["評價練習", "批判思考", "觀點比較"],
                estimatedTime: "每天25-30分鐘",
                passages: ["passage7", "passage8"]
            )
        ]
        
        return strategies[process] ?? InterventionStrategy(
            process: process,
            focusAreas: [],
            practiceTypes: [],
            estimatedTime: "每天20分鐘",
            passages: []
        )
    }
    
    // MARK: - Vocabulary Support for Weak Areas
    /**
     * Identifies vocabulary words that are relevant to weak PIRLS processes.
     */
    func getVocabularySupport(_ process: PIRLSProcess) -> [VocabularyWord] {
        // Get vocabulary from passages that test this process
        var relevantWords: [VocabularyWord] = []
        
        let allPassageKeys = ["passage1", "passage2", "passage3", "passage4", "passage5", "passage6", "passage7", "passage8", "passage9"]
        
        for passageKey in allPassageKeys {
            if let passageSet = QuestionBank.shared.getPassageSet(for: passageKey) {
                // Check if this passage has questions for the target process
                var hasProcessQuestions = false
                for questionKey in passageSet.questionKeys {
                    if let question = QuestionBank.shared.getQuestion(forKey: questionKey) {
                        let enriched = QuestionBank.shared.enrichQuestionWithPIRLS(question, passageText: passageSet.passage)
                        if enriched.pirlsProcess == process {
                            hasProcessQuestions = true
                            break
                        }
                    }
                }
                
                if hasProcessQuestions {
                    let vocab = VocabularyManager.shared.extractVocabulary(from: passageSet.passage, maxWords: 10)
                    relevantWords.append(contentsOf: vocab)
                }
            }
        }
        
        // Remove duplicates and return
        var uniqueWords: [String: VocabularyWord] = [:]
        for word in relevantWords {
            uniqueWords[word.word] = word
        }
        
        return Array(uniqueWords.values)
    }
    
    // MARK: - Reading Purpose Adjustment Suggestions
    /**
     * Suggests adjustments to reading purpose balance.
     */
    func suggestReadingPurposeAdjustment(_ profile: StudentProfile) -> ReadingPurposeAdjustment {
        let tracker = ReadingPurposeTracker.shared
        let balance = tracker.calculateBalance(profile)
        let performance = tracker.getPurposePerformance(profile)
        
        var adjustment: ReadingPurposeAdjustment
        
        if !balance.isBalanced {
            let weakerType = balance.literary < balance.informational ? ReadingPurpose.literary : ReadingPurpose.informational
            let suggestedPassages = tracker.suggestContentForBalance(balance)
            
            adjustment = ReadingPurposeAdjustment(
                needsAdjustment: true,
                weakerPurpose: weakerType,
                currentRatio: weakerType == .literary ? balance.literary : balance.informational,
                targetRatio: 0.4,
                suggestedPassages: suggestedPassages,
                practiceFrequency: "每週3-4次"
            )
        } else {
            adjustment = ReadingPurposeAdjustment(
                needsAdjustment: false,
                weakerPurpose: nil,
                currentRatio: 0.5,
                targetRatio: 0.5,
                suggestedPassages: [],
                practiceFrequency: "維持現有頻率"
            )
        }
        
        return adjustment
    }
    
    // MARK: - Helper Methods
    private func createProcessPracticeRecommendation(_ process: PIRLSProcess, need: InterventionNeed) -> PracticeRecommendation {
        let strategy = getProcessInterventionStrategy(process)
        
        return PracticeRecommendation(
            type: .process,
            title: "加強 \(process.displayName) 練習",
            description: "你的\(process.displayName)能力需要加強。建議按照以下策略進行練習。",
            priority: need.severity == .high ? .high : .medium,
            suggestedActions: strategy.focusAreas,
            estimatedTime: strategy.estimatedTime,
            targetPassages: strategy.passages
        )
    }
    
    private func createVocabularyPracticeRecommendation(need: InterventionNeed) -> PracticeRecommendation {
        return PracticeRecommendation(
            type: .vocabulary,
            title: "詞彙強化練習",
            description: "詞彙掌握率較低，建議加強詞彙學習和複習。",
            priority: need.severity == .high ? .high : .medium,
            suggestedActions: [
                "每天學習10個新詞彙",
                "使用詞彙卡片進行複習",
                "在閱讀中注意新詞彙的上下文"
            ],
            estimatedTime: "每天10-15分鐘",
            targetPassages: []
        )
    }
    
    private func createReadingPurposeRecommendation(need: InterventionNeed) -> PracticeRecommendation {
        let purposeName = need.target == "literary" ? "文學類" : "資訊類"
        return PracticeRecommendation(
            type: .readingPurpose,
            title: "平衡 \(purposeName) 閱讀",
            description: "建議增加\(purposeName)類型的閱讀練習以達到平衡。",
            priority: need.severity == .high ? .high : .medium,
            suggestedActions: [
                "每週閱讀2-3篇\(purposeName)文章",
                "專注於\(purposeName)類型的問題練習"
            ],
            estimatedTime: "每週30-45分鐘",
            targetPassages: []
        )
    }
}

// MARK: - Data Structures
struct InterventionNeed {
    enum InterventionType {
        case process
        case vocabulary
        case readingPurpose
    }
    
    enum Severity: Int {
        case low = 1
        case medium = 2
        case high = 3
    }
    
    let type: InterventionType
    let target: String
    let severity: Severity
    let currentLevel: Double
    let targetLevel: Double
}

struct PracticeRecommendation {
    enum RecommendationType {
        case process
        case vocabulary
        case readingPurpose
    }
    
    enum Priority: Int {
        case low = 1
        case medium = 2
        case high = 3
    }
    
    let type: RecommendationType
    let title: String
    let description: String
    let priority: Priority
    let suggestedActions: [String]
    let estimatedTime: String
    let targetPassages: [String]
}

struct InterventionStrategy {
    let process: PIRLSProcess
    let focusAreas: [String]
    let practiceTypes: [String]
    let estimatedTime: String
    let passages: [String]
}

struct ReadingPurposeAdjustment {
    let needsAdjustment: Bool
    let weakerPurpose: ReadingPurpose?
    let currentRatio: Double
    let targetRatio: Double
    let suggestedPassages: [String]
    let practiceFrequency: String
}

