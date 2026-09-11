import Foundation

// MARK: - 📊 PIRLS ANALYTICS - Comprehensive Reading Comprehension Analytics
class PIRLSAnalytics {
    static let shared = PIRLSAnalytics()  // Singleton pattern
    
    private init() {}
    
    // MARK: - Process-Level Performance Analysis
    func analyzeProcessPerformance(_ assessment: PIRLSAssessment) -> ProcessAnalysis {
        var processScores: [PIRLSProcess: Double] = [:]
        var processTrends: [PIRLSProcess: [Double]] = [:]
        
        for process in PIRLSProcess.allCases {
            if let performance = assessment.processPerformance[process] {
                processScores[process] = performance.masteryLevel
            }
        }
        
        return ProcessAnalysis(
            processScores: processScores,
            strongestProcess: assessment.getStrongestProcess(),
            weakestProcess: assessment.getWeakestProcess(),
            averageScore: assessment.overallScore
        )
    }
    
    // MARK: - Difficulty Progression Analysis
    func analyzeDifficultyProgression(_ history: [PerformanceRecord]) -> DifficultyProgression {
        var difficultyScores: [Int: (correct: Int, total: Int)] = [:]
        
        // Group by difficulty level (would need to track this in records)
        for record in history {
            // For now, estimate difficulty from response time
            let estimatedDifficulty = estimateDifficultyFromResponseTime(record.responseTime)
            if difficultyScores[estimatedDifficulty] == nil {
                difficultyScores[estimatedDifficulty] = (0, 0)
            }
            difficultyScores[estimatedDifficulty]?.total += 1
            if record.isCorrect {
                difficultyScores[estimatedDifficulty]?.correct += 1
            }
        }
        
        var progression: [Int: Double] = [:]
        for (level, scores) in difficultyScores {
            progression[level] = Double(scores.correct) / Double(scores.total)
        }
        
        return DifficultyProgression(
            levelPerformance: progression,
            recommendedNextLevel: calculateRecommendedLevel(progression)
        )
    }
    
    // MARK: - Vocabulary Growth Metrics
    func analyzeVocabularyGrowth(_ stats: VocabularyStats, previousStats: VocabularyStats?) -> VocabularyGrowth {
        let newWords = previousStats != nil ? stats.totalWords - previousStats!.totalWords : stats.totalWords
        let newMastered = previousStats != nil ? stats.masteredWords - previousStats!.masteredWords : stats.masteredWords
        
        return VocabularyGrowth(
            totalWords: stats.totalWords,
            masteredWords: stats.masteredWords,
            masteryRate: stats.masteryRate,
            newWordsThisPeriod: newWords,
            newMasteredThisPeriod: newMastered,
            growthRate: previousStats != nil ? (stats.masteryRate - previousStats!.masteryRate) : stats.masteryRate
        )
    }
    
    // MARK: - Reading Comprehension Trends
    func analyzeReadingTrends(_ history: [PerformanceRecord], days: Int = 30) -> ReadingTrends {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentRecords = history.filter { $0.date >= cutoffDate }
        
        let totalQuestions = recentRecords.count
        let correctAnswers = recentRecords.filter { $0.isCorrect }.count
        let averageResponseTime = recentRecords.map { $0.responseTime }.reduce(0, +) / Double(max(recentRecords.count, 1))
        
        // Process distribution
        var processDistribution: [PIRLSProcess: Int] = [:]
        for record in recentRecords {
            if let process = record.pirlsProcess {
                processDistribution[process, default: 0] += 1
            }
        }
        
        // Reading purpose distribution
        var purposeDistribution: [ReadingPurpose: Int] = [:]
        for record in recentRecords {
            if let purpose = record.readingPurpose {
                purposeDistribution[purpose, default: 0] += 1
            }
        }
        
        return ReadingTrends(
            period: days,
            totalQuestions: totalQuestions,
            accuracyRate: totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) : 0.0,
            averageResponseTime: averageResponseTime,
            processDistribution: processDistribution,
            purposeDistribution: purposeDistribution
        )
    }
    
    // MARK: - Generate Recommendations
    func generateRecommendations(_ profile: StudentProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Check weakest process
        if let weakest = profile.weakestProcess {
            recommendations.append(Recommendation(
                type: .focusArea,
                title: "加強 \(weakest.displayName)",
                description: "建議多練習 \(weakest.displayName) 類型的問題，以提高整體閱讀理解能力。",
                priority: .high
            ))
        }
        
        // Check vocabulary
        if profile.vocabularyMastery < 0.6 {
            recommendations.append(Recommendation(
                type: .vocabulary,
                title: "擴充詞彙量",
                description: "建議多閱讀不同類型的文章，學習新詞彙。",
                priority: .medium
            ))
        }
        
        // Check reading purpose balance
        let purposeBalance = abs(profile.literaryPerformance - profile.informationalPerformance)
        if purposeBalance > 0.3 {
            let weakerPurpose = profile.literaryPerformance < profile.informationalPerformance ? ReadingPurpose.literary : ReadingPurpose.informational
            recommendations.append(Recommendation(
                type: .readingPurpose,
                title: "平衡閱讀類型",
                description: "建議多閱讀 \(weakerPurpose.displayName) 類型的文章。",
                priority: .medium
            ))
        }
        
        // Check response time
        let recentTrends = analyzeReadingTrends(profile.performanceHistory, days: 7)
        if recentTrends.averageResponseTime > 30.0 {
            recommendations.append(Recommendation(
                type: .practice,
                title: "提高閱讀速度",
                description: "建議多練習，提高閱讀理解和答題速度。",
                priority: .low
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    private func estimateDifficultyFromResponseTime(_ time: TimeInterval) -> Int {
        if time < 10 {
            return 1
        } else if time < 20 {
            return 2
        } else if time < 30 {
            return 3
        } else if time < 40 {
            return 4
        } else if time < 50 {
            return 5
        } else {
            return 6
        }
    }
    
    private func calculateRecommendedLevel(_ progression: [Int: Double]) -> Int {
        // Find the highest level with >70% accuracy
        let sortedLevels = progression.keys.sorted(by: >)
        for level in sortedLevels {
            if let accuracy = progression[level], accuracy >= 0.7 {
                return min(6, level + 1)  // Recommend next level
            }
        }
        return 1  // Default to level 1
    }
    
    // MARK: - Class Performance Analysis (Phase 1.2)
    /**
     * Analyzes performance across multiple students for class-wide insights.
     * Compares students across PIRLS processes to identify class strengths and weaknesses.
     */
    func analyzeClassPerformance(_ studentProfiles: [StudentProfile]) -> ClassPerformanceAnalysis {
        var processAverages: [PIRLSProcess: Double] = [:]
        var processCounts: [PIRLSProcess: Int] = [:]
        var studentScores: [String: [PIRLSProcess: Double]] = [:]
        
        // Calculate averages for each process
        for process in PIRLSProcess.allCases {
            var totalScore: Double = 0
            var count = 0
            
            for profile in studentProfiles {
                if let performance = profile.pirlsAssessment.processPerformance[process] {
                    let score = performance.masteryLevel
                    totalScore += score
                    count += 1
                    
                    // Store individual student scores
                    if studentScores[profile.studentID] == nil {
                        studentScores[profile.studentID] = [:]
                    }
                    studentScores[profile.studentID]?[process] = score
                }
            }
            
            if count > 0 {
                processAverages[process] = totalScore / Double(count)
                processCounts[process] = count
            }
        }
        
        // Find strongest and weakest processes for the class
        let strongestProcess = processAverages.max(by: { $0.value < $1.value })?.key
        let weakestProcess = processAverages.min(by: { $0.value < $1.value })?.key
        
        return ClassPerformanceAnalysis(
            processAverages: processAverages,
            processCounts: processCounts,
            studentScores: studentScores,
            strongestProcess: strongestProcess,
            weakestProcess: weakestProcess,
            totalStudents: studentProfiles.count
        )
    }
    
    // MARK: - At-Risk Student Identification (Phase 1.2)
    /**
     * Identifies students who are performing below benchmarks.
     * Flags students who need intervention based on PIRLS process performance.
     */
    func identifyAtRiskStudents(_ studentProfiles: [StudentProfile], benchmarkThreshold: Double = 0.5) -> [AtRiskStudent] {
        var atRiskStudents: [AtRiskStudent] = []
        
        for profile in studentProfiles {
            var weakProcesses: [PIRLSProcess] = []
            var overallScore = 0.0
            var processCount = 0
            
            for process in PIRLSProcess.allCases {
                if let performance = profile.pirlsAssessment.processPerformance[process] {
                    overallScore += performance.masteryLevel
                    processCount += 1
                    
                    if performance.masteryLevel < benchmarkThreshold {
                        weakProcesses.append(process)
                    }
                }
            }
            
            let averageScore = processCount > 0 ? overallScore / Double(processCount) : 0.0
            
            if averageScore < benchmarkThreshold || !weakProcesses.isEmpty {
                atRiskStudents.append(AtRiskStudent(
                    studentID: profile.studentID,
                    studentName: profile.studentName ?? "未命名",
                    currentLevel: profile.currentLevel,
                    overallScore: averageScore,
                    weakProcesses: weakProcesses,
                    vocabularyMastery: profile.vocabularyMastery,
                    riskLevel: calculateRiskLevel(averageScore: averageScore, weakProcessCount: weakProcesses.count)
                ))
            }
        }
        
        return atRiskStudents.sorted { $0.riskLevel.rawValue > $1.riskLevel.rawValue }
    }
    
    // MARK: - Intervention Recommendations (Phase 1.2)
    /**
     * Generates targeted practice recommendations for students based on their weak areas.
     * Provides process-specific intervention strategies.
     */
    func generateInterventionRecommendations(_ profile: StudentProfile) -> [InterventionRecommendation] {
        var recommendations: [InterventionRecommendation] = []
        
        // Process-specific recommendations
        for process in PIRLSProcess.allCases {
            if let performance = profile.pirlsAssessment.processPerformance[process],
               performance.masteryLevel < 0.6 {
                recommendations.append(InterventionRecommendation(
                    type: .processFocus,
                    targetProcess: process,
                    priority: performance.masteryLevel < 0.4 ? .high : .medium,
                    title: "加強 \(process.displayName) 練習",
                    description: getProcessInterventionDescription(process),
                    suggestedActions: getProcessSuggestedActions(process),
                    estimatedTime: "每天15-20分鐘"
                ))
            }
        }
        
        // Vocabulary support
        if profile.vocabularyMastery < 0.5 {
            recommendations.append(InterventionRecommendation(
                type: .vocabulary,
                targetProcess: nil,
                priority: .high,
                title: "詞彙強化練習",
                description: "詞彙掌握率較低，建議加強詞彙學習和複習。",
                suggestedActions: [
                    "每天學習10個新詞彙",
                    "使用詞彙卡片進行複習",
                    "在閱讀中注意新詞彙的上下文"
                ],
                estimatedTime: "每天10-15分鐘"
            ))
        }
        
        // Reading purpose balance
        let purposeBalance = abs(profile.literaryPerformance - profile.informationalPerformance)
        if purposeBalance > 0.3 {
            let weakerPurpose = profile.literaryPerformance < profile.informationalPerformance ? ReadingPurpose.literary : ReadingPurpose.informational
            recommendations.append(InterventionRecommendation(
                type: .readingPurpose,
                targetProcess: nil,
                priority: .medium,
                title: "平衡 \(weakerPurpose.displayName) 閱讀",
                description: "建議增加 \(weakerPurpose.displayName) 類型的閱讀練習。",
                suggestedActions: [
                    "每週閱讀2-3篇\(weakerPurpose.displayName)文章",
                    "專注於\(weakerPurpose.displayName)類型的問題練習"
                ],
                estimatedTime: "每週30-45分鐘"
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // MARK: - Process Gap Calculation (Phase 1.2)
    /**
     * Identifies the weakest areas per student by calculating gaps between processes.
     * Helps identify which PIRLS process needs the most attention.
     */
    func calculateProcessGaps(_ profile: StudentProfile) -> ProcessGapAnalysis {
        var processScores: [PIRLSProcess: Double] = [:]
        var maxScore: Double = 0
        var minScore: Double = 1.0
        
        for process in PIRLSProcess.allCases {
            if let performance = profile.pirlsAssessment.processPerformance[process] {
                let score = performance.masteryLevel
                processScores[process] = score
                maxScore = max(maxScore, score)
                minScore = min(minScore, score)
            }
        }
        
        let gap = maxScore - minScore
        let weakestProcess = processScores.min(by: { $0.value < $1.value })?.key
        let strongestProcess = processScores.max(by: { $0.value < $1.value })?.key
        
        return ProcessGapAnalysis(
            processScores: processScores,
            gapSize: gap,
            weakestProcess: weakestProcess,
            strongestProcess: strongestProcess,
            needsIntervention: gap > 0.3 || minScore < 0.5
        )
    }
    
    // MARK: - Grade Level Benchmarking (Phase 1.2)
    /**
     * Compares student performance to PIRLS international benchmarks for their grade level.
     * Provides percentile rankings and benchmark comparisons.
     */
    func benchmarkAgainstGradeLevel(_ profile: StudentProfile) -> BenchmarkAnalysis {
        // PIRLS benchmark data (approximate percentiles for reference)
        // These would ideally come from actual PIRLS data
        let benchmarkData: [Int: (p25: Double, p50: Double, p75: Double)] = [
            1: (0.3, 0.5, 0.7),
            2: (0.4, 0.6, 0.75),
            3: (0.5, 0.65, 0.8),
            4: (0.55, 0.7, 0.85),
            5: (0.6, 0.75, 0.9),
            6: (0.65, 0.8, 0.95)
        ]
        
        let level = profile.currentLevel
        let benchmarks = benchmarkData[level] ?? (0.5, 0.7, 0.85)
        let overallScore = profile.pirlsAssessment.overallScore
        
        // Calculate percentile
        var percentile: Int
        if overallScore >= benchmarks.p75 {
            percentile = 75
        } else if overallScore >= benchmarks.p50 {
            percentile = 50
        } else if overallScore >= benchmarks.p25 {
            percentile = 25
        } else {
            percentile = 10
        }
        
        // Process-specific benchmarks
        var processBenchmarks: [PIRLSProcess: BenchmarkStatus] = [:]
        for process in PIRLSProcess.allCases {
            if let performance = profile.pirlsAssessment.processPerformance[process] {
                let score = performance.masteryLevel
                let status: BenchmarkStatus
                if score >= benchmarks.p75 {
                    status = .aboveBenchmark
                } else if score >= benchmarks.p50 {
                    status = .atBenchmark
                } else {
                    status = .belowBenchmark
                }
                processBenchmarks[process] = status
            }
        }
        
        return BenchmarkAnalysis(
            studentLevel: level,
            overallScore: overallScore,
            percentile: percentile,
            benchmark25th: benchmarks.p25,
            benchmark50th: benchmarks.p50,
            benchmark75th: benchmarks.p75,
            processBenchmarks: processBenchmarks,
            isAboveGradeLevel: overallScore >= benchmarks.p75,
            isAtGradeLevel: overallScore >= benchmarks.p50 && overallScore < benchmarks.p75,
            isBelowGradeLevel: overallScore < benchmarks.p50
        )
    }
    
    // MARK: - Helper Methods for Interventions
    private func calculateRiskLevel(averageScore: Double, weakProcessCount: Int) -> RiskLevel {
        if averageScore < 0.3 || weakProcessCount >= 3 {
            return .high
        } else if averageScore < 0.5 || weakProcessCount >= 2 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func getProcessInterventionDescription(_ process: PIRLSProcess) -> String {
        switch process {
        case .retrieving:
            return "檢索理解能力需要加強。建議多練習從文本中直接找到明確資訊的問題。"
        case .inferring:
            return "推論理解能力需要加強。建議多練習需要根據文本內容進行合理推論的問題。"
        case .interpreting:
            return "詮釋理解能力需要加強。建議多練習需要解釋和整合文本中想法與資訊的問題。"
        case .evaluating:
            return "評價理解能力需要加強。建議多練習需要檢視和評價文本內容與形式的問題。"
        }
    }
    
    private func getProcessSuggestedActions(_ process: PIRLSProcess) -> [String] {
        switch process {
        case .retrieving:
            return [
                "練習找出文本中的關鍵資訊",
                "注意問題中的關鍵詞",
                "練習快速定位答案位置"
            ]
        case .inferring:
            return [
                "練習根據文本線索進行推論",
                "注意文本中的暗示和隱含意思",
                "練習連接文本中的不同資訊"
            ]
        case .interpreting:
            return [
                "練習理解文本的整體意義",
                "練習整合不同段落的信息",
                "練習解釋文本中的概念和想法"
            ]
        case .evaluating:
            return [
                "練習評價文本的內容和觀點",
                "練習判斷文本的可靠性和有效性",
                "練習比較不同文本的觀點"
            ]
        }
    }
}

// MARK: - Analytics Data Structures
struct ProcessAnalysis {
    let processScores: [PIRLSProcess: Double]
    let strongestProcess: PIRLSProcess?
    let weakestProcess: PIRLSProcess?
    let averageScore: Double
}

struct DifficultyProgression {
    let levelPerformance: [Int: Double]  // Level -> Accuracy rate
    let recommendedNextLevel: Int
}

struct VocabularyGrowth {
    let totalWords: Int
    let masteredWords: Int
    let masteryRate: Double
    let newWordsThisPeriod: Int
    let newMasteredThisPeriod: Int
    let growthRate: Double
}

struct ReadingTrends {
    let period: Int  // Days
    let totalQuestions: Int
    let accuracyRate: Double
    let averageResponseTime: TimeInterval
    let processDistribution: [PIRLSProcess: Int]
    let purposeDistribution: [ReadingPurpose: Int]
}

struct Recommendation {
    enum RecommendationType {
        case focusArea
        case vocabulary
        case readingPurpose
        case practice
    }
    
    enum Priority {
        case high
        case medium
        case low
    }
    
    let type: RecommendationType
    let title: String
    let description: String
    let priority: Priority
}

// MARK: - Enhanced Analytics Data Structures (Phase 1.2)
struct ClassPerformanceAnalysis {
    let processAverages: [PIRLSProcess: Double]
    let processCounts: [PIRLSProcess: Int]
    let studentScores: [String: [PIRLSProcess: Double]]
    let strongestProcess: PIRLSProcess?
    let weakestProcess: PIRLSProcess?
    let totalStudents: Int
}

struct AtRiskStudent {
    let studentID: String
    let studentName: String
    let currentLevel: Int
    let overallScore: Double
    let weakProcesses: [PIRLSProcess]
    let vocabularyMastery: Double
    let riskLevel: RiskLevel
}

enum RiskLevel: Int {
    case low = 1
    case medium = 2
    case high = 3
}

struct InterventionRecommendation {
    enum InterventionType {
        case processFocus
        case vocabulary
        case readingPurpose
        case general
    }
    
    enum Priority: Int {
        case low = 1
        case medium = 2
        case high = 3
    }
    
    let type: InterventionType
    let targetProcess: PIRLSProcess?
    let priority: Priority
    let title: String
    let description: String
    let suggestedActions: [String]
    let estimatedTime: String
}

struct ProcessGapAnalysis {
    let processScores: [PIRLSProcess: Double]
    let gapSize: Double
    let weakestProcess: PIRLSProcess?
    let strongestProcess: PIRLSProcess?
    let needsIntervention: Bool
}

struct BenchmarkAnalysis {
    let studentLevel: Int
    let overallScore: Double
    let percentile: Int
    let benchmark25th: Double
    let benchmark50th: Double
    let benchmark75th: Double
    let processBenchmarks: [PIRLSProcess: BenchmarkStatus]
    let isAboveGradeLevel: Bool
    let isAtGradeLevel: Bool
    let isBelowGradeLevel: Bool
}

enum BenchmarkStatus {
    case aboveBenchmark
    case atBenchmark
    case belowBenchmark
}

