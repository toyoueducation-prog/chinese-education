import Foundation

/**
 * TREND ANALYZER - Performance Trend Analysis
 * 
 * Features:
 * - Identify improvement trends
 * - Detect learning plateaus
 * - Predict future performance
 * - Compare performance across time periods
 * - Generate insights from patterns
 */
// MARK: - 📈 TREND ANALYZER
class TrendAnalyzer {
    static let shared = TrendAnalyzer()
    
    private init() {}
    
    // MARK: - Identify Improvement Trends
    /**
     * Analyzes performance history to identify improvement or decline trends.
     */
    func identifyTrends(_ history: [PerformanceRecord], days: Int = 30) -> PerformanceTrend {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentRecords = history.filter { $0.date >= cutoffDate }
        
        guard recentRecords.count >= 5 else {
            return PerformanceTrend(
                trend: .insufficientData,
                changeRate: 0.0,
                description: "數據不足，無法分析趨勢"
            )
        }
        
        // Split into early and late periods
        let midPoint = recentRecords.count / 2
        let earlyPeriod = Array(recentRecords.prefix(midPoint))
        let latePeriod = Array(recentRecords.suffix(recentRecords.count - midPoint))
        
        let earlyAccuracy = calculateAccuracy(earlyPeriod)
        let lateAccuracy = calculateAccuracy(latePeriod)
        
        let changeRate = lateAccuracy - earlyAccuracy
        let threshold: Double = 0.05  // 5% change threshold
        
        var trend: TrendDirection
        var description: String
        
        if changeRate > threshold {
            trend = .improving
            description = "表現正在改善，正確率提升了\(String(format: "%.1f", changeRate * 100))%"
        } else if changeRate < -threshold {
            trend = .declining
            description = "表現有所下降，正確率降低了\(String(format: "%.1f", abs(changeRate) * 100))%"
        } else {
            trend = .stable
            description = "表現穩定，保持當前水平"
        }
        
        return PerformanceTrend(
            trend: trend,
            changeRate: changeRate,
            description: description
        )
    }
    
    // MARK: - Detect Learning Plateaus
    /**
     * Detects if student has reached a learning plateau.
     */
    func detectPlateau(_ history: [PerformanceRecord], days: Int = 14) -> PlateauAnalysis {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentRecords = history.filter { $0.date >= cutoffDate }
        
        guard recentRecords.count >= 7 else {
            return PlateauAnalysis(
                isPlateau: false,
                duration: 0,
                averageScore: 0.0,
                recommendation: "數據不足"
            )
        }
        
        // Calculate weekly averages
        var weeklyAverages: [Double] = []
        let recordsPerWeek = max(1, recentRecords.count / 2)
        
        for i in 0..<2 {
            let start = i * recordsPerWeek
            let end = min((i + 1) * recordsPerWeek, recentRecords.count)
            let weekRecords = Array(recentRecords[start..<end])
            weeklyAverages.append(calculateAccuracy(weekRecords))
        }
        
        // Check if scores are similar (plateau)
        let difference = abs(weeklyAverages[0] - weeklyAverages[1])
        let isPlateau = difference < 0.03  // Less than 3% change
        
        let averageScore = weeklyAverages.reduce(0, +) / Double(weeklyAverages.count)
        
        var recommendation: String
        if isPlateau {
            if averageScore < 0.6 {
                recommendation = "檢測到學習停滯，建議調整學習策略或增加難度"
            } else {
                recommendation = "表現穩定，可以嘗試更具挑戰性的內容"
            }
        } else {
            recommendation = "持續進步中，保持當前學習節奏"
        }
        
        return PlateauAnalysis(
            isPlateau: isPlateau,
            duration: days,
            averageScore: averageScore,
            recommendation: recommendation
        )
    }
    
    // MARK: - Predict Future Performance
    /**
     * Predicts future performance based on current trends.
     */
    func predictPerformance(_ history: [PerformanceRecord], daysAhead: Int = 7) -> PerformancePrediction {
        let trend = identifyTrends(history, days: 30)
        let recentAccuracy = calculateAccuracy(history.suffix(10))
        
        var predictedAccuracy: Double
        var confidence: Double
        
        switch trend.trend {
        case .improving:
            // Extrapolate improvement
            predictedAccuracy = min(1.0, recentAccuracy + (trend.changeRate * Double(daysAhead) / 7.0))
            confidence = 0.7
        case .declining:
            // Extrapolate decline
            predictedAccuracy = max(0.0, recentAccuracy + (trend.changeRate * Double(daysAhead) / 7.0))
            confidence = 0.6
        case .stable:
            // Maintain current level
            predictedAccuracy = recentAccuracy
            confidence = 0.8
        case .insufficientData:
            predictedAccuracy = recentAccuracy
            confidence = 0.3
        }
        
        return PerformancePrediction(
            predictedAccuracy: predictedAccuracy,
            confidence: confidence,
            daysAhead: daysAhead,
            basedOnTrend: trend.trend
        )
    }
    
    // MARK: - Compare Time Periods
    /**
     * Compares performance across different time periods.
     */
    func comparePeriods(_ history: [PerformanceRecord], period1Days: Int, period2Days: Int) -> PeriodComparison {
        let now = Date()
        let period1Start = Calendar.current.date(byAdding: .day, value: -period1Days, to: now) ?? now
        let period2Start = Calendar.current.date(byAdding: .day, value: -period2Days, to: now) ?? now
        
        let period1Records = history.filter { $0.date >= period1Start && $0.date < period2Start }
        let period2Records = history.filter { $0.date >= period2Start }
        
        let period1Accuracy = calculateAccuracy(period1Records)
        let period2Accuracy = calculateAccuracy(period2Records)
        
        let period1AvgTime = calculateAverageTime(period1Records)
        let period2AvgTime = calculateAverageTime(period2Records)
        
        let improvement = period2Accuracy - period1Accuracy
        let speedImprovement = period1AvgTime - period2AvgTime  // Negative means faster (better)
        
        return PeriodComparison(
            period1Accuracy: period1Accuracy,
            period2Accuracy: period2Accuracy,
            period1AverageTime: period1AvgTime,
            period2AverageTime: period2AvgTime,
            accuracyImprovement: improvement,
            speedImprovement: speedImprovement,
            isImproving: improvement > 0.05
        )
    }
    
    // MARK: - Generate Insights
    /**
     * Generates actionable insights from performance patterns.
     */
    func generateInsights(_ profile: StudentProfile) -> [TrendInsight] {
        var insights: [TrendInsight] = []
        
        // Analyze overall trend
        let trend = identifyTrends(profile.performanceHistory, days: 30)
        if trend.trend == .improving {
            insights.append(TrendInsight(
                type: .positive,
                title: "持續進步",
                description: trend.description,
                action: "保持當前學習節奏"
            ))
        } else if trend.trend == .declining {
            insights.append(TrendInsight(
                type: .warning,
                title: "表現下降",
                description: trend.description,
                action: "建議增加練習時間或調整學習方法"
            ))
        }
        
        // Check for plateaus
        let plateau = detectPlateau(profile.performanceHistory, days: 14)
        if plateau.isPlateau {
            insights.append(TrendInsight(
                type: .info,
                title: "學習停滯",
                description: plateau.recommendation,
                action: "嘗試更具挑戰性的內容或新的學習方式"
            ))
        }
        
        // Process-specific trends
        for process in PIRLSProcess.allCases {
            if let performance = profile.pirlsAssessment.processPerformance[process] {
                if performance.masteryLevel < 0.5 {
                    insights.append(TrendInsight(
                        type: .action,
                        title: "\(process.displayName)需要加強",
                        description: "此過程的掌握程度較低",
                        action: "專注練習\(process.displayName)類型的問題"
                    ))
                }
            }
        }
        
        return insights
    }
    
    // MARK: - Helper Methods
    private func calculateAccuracy(_ records: [PerformanceRecord]) -> Double {
        guard !records.isEmpty else { return 0.0 }
        let correct = records.filter { $0.isCorrect }.count
        return Double(correct) / Double(records.count)
    }
    
    private func calculateAverageTime(_ records: [PerformanceRecord]) -> TimeInterval {
        guard !records.isEmpty else { return 0.0 }
        return records.map { $0.responseTime }.reduce(0, +) / Double(records.count)
    }
}

// MARK: - Data Structures
struct PerformanceTrend {
    let trend: TrendDirection
    let changeRate: Double
    let description: String
}

enum TrendDirection {
    case improving
    case declining
    case stable
    case insufficientData
}

struct PlateauAnalysis {
    let isPlateau: Bool
    let duration: Int
    let averageScore: Double
    let recommendation: String
}

struct PerformancePrediction {
    let predictedAccuracy: Double
    let confidence: Double
    let daysAhead: Int
    let basedOnTrend: TrendDirection
}

struct PeriodComparison {
    let period1Accuracy: Double
    let period2Accuracy: Double
    let period1AverageTime: TimeInterval
    let period2AverageTime: TimeInterval
    let accuracyImprovement: Double
    let speedImprovement: TimeInterval
    let isImproving: Bool
}

struct TrendInsight {
    enum InsightType {
        case positive
        case warning
        case info
        case action
    }
    
    let type: InsightType
    let title: String
    let description: String
    let action: String
}

