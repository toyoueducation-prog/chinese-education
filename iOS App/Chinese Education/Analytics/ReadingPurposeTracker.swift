import Foundation

/**
 * READING PURPOSE TRACKER - Balance and Performance Analysis
 * 
 * Features:
 * - Recommendations for balanced reading
 * - Purpose-specific performance metrics
 * - Content suggestions to improve balance
 */
// MARK: - 📊 READING PURPOSE TRACKER
class ReadingPurposeTracker {
    static let shared = ReadingPurposeTracker()
    
    private init() {}
    
    // MARK: - Calculate Reading Purpose Balance
    func calculateBalance(_ profile: StudentProfile) -> ReadingPurposeBalance {
        let literaryCount = profile.performanceHistory.filter { $0.readingPurpose == .literary }.count
        let informationalCount = profile.performanceHistory.filter { $0.readingPurpose == .informational }.count
        let total = literaryCount + informationalCount
        
        let literaryRatio = total > 0 ? Double(literaryCount) / Double(total) : 0.5
        let informationalRatio = total > 0 ? Double(informationalCount) / Double(total) : 0.5
        
        return ReadingPurposeBalance(
            literary: literaryRatio,
            informational: informationalRatio,
            literaryCount: literaryCount,
            informationalCount: informationalCount,
            isBalanced: abs(literaryRatio - informationalRatio) <= 0.2
        )
    }
    
    // MARK: - Get Balance Recommendations
    func getBalanceRecommendations(_ balance: ReadingPurposeBalance) -> [String] {
        var recommendations: [String] = []
        
        if !balance.isBalanced {
            let difference = abs(balance.literary - balance.informational)
            let weakerType = balance.literary < balance.informational ? ReadingPurpose.literary : ReadingPurpose.informational
            
            if difference > 0.4 {
                recommendations.append("建議大幅增加\(weakerType.displayName)類型的閱讀練習")
                recommendations.append("目標：達到40-60%的閱讀比例")
            } else if difference > 0.2 {
                recommendations.append("建議適度增加\(weakerType.displayName)類型的閱讀練習")
                recommendations.append("目標：達到更平衡的閱讀比例")
            }
        } else {
            recommendations.append("閱讀類型平衡良好，繼續保持！")
        }
        
        return recommendations
    }
    
    // MARK: - Get Purpose-Specific Performance
    func getPurposePerformance(_ profile: StudentProfile) -> PurposePerformance {
        let literaryRecords = profile.performanceHistory.filter { $0.readingPurpose == .literary }
        let informationalRecords = profile.performanceHistory.filter { $0.readingPurpose == .informational }
        
        let literaryCorrect = literaryRecords.filter { $0.isCorrect }.count
        let informationalCorrect = informationalRecords.filter { $0.isCorrect }.count
        
        let literaryAccuracy = literaryRecords.isEmpty ? 0.0 : Double(literaryCorrect) / Double(literaryRecords.count)
        let informationalAccuracy = informationalRecords.isEmpty ? 0.0 : Double(informationalCorrect) / Double(informationalRecords.count)
        
        let literaryAvgTime = literaryRecords.isEmpty ? 0.0 : literaryRecords.map { $0.responseTime }.reduce(0, +) / Double(literaryRecords.count)
        let informationalAvgTime = informationalRecords.isEmpty ? 0.0 : informationalRecords.map { $0.responseTime }.reduce(0, +) / Double(informationalRecords.count)
        
        return PurposePerformance(
            literaryAccuracy: literaryAccuracy,
            informationalAccuracy: informationalAccuracy,
            literaryAverageTime: literaryAvgTime,
            informationalAverageTime: informationalAvgTime,
            literaryCount: literaryRecords.count,
            informationalCount: informationalRecords.count
        )
    }
    
    // MARK: - Suggest Content for Balance
    func suggestContentForBalance(_ balance: ReadingPurposeBalance) -> [String] {
        var suggestions: [String] = []
        
        if balance.literary < 0.4 {
            // Need more literary content
            suggestions.append("passage1")  // 小兔子的派對 (Literary)
            suggestions.append("passage4")  // 小貓咪的冒險 (Literary)
            suggestions.append("passage6")  // 小明的圖書館之旅 (Literary)
        }
        
        if balance.informational < 0.4 {
            // Need more informational content
            suggestions.append("passage2")  // 四季變化 (Informational)
            suggestions.append("passage3")  // 小鳥的遷徙 (Informational)
            suggestions.append("passage5")  // 植物的生長 (Informational)
            suggestions.append("passage7")  // 太陽系的行星 (Informational)
            suggestions.append("passage8")  // 傳統節日 (Informational)
        }
        
        return suggestions
    }
}

// MARK: - Data Structures
struct ReadingPurposeBalance {
    let literary: Double
    let informational: Double
    let literaryCount: Int
    let informationalCount: Int
    let isBalanced: Bool
}

struct PurposePerformance {
    let literaryAccuracy: Double
    let informationalAccuracy: Double
    let literaryAverageTime: TimeInterval
    let informationalAverageTime: TimeInterval
    let literaryCount: Int
    let informationalCount: Int
}

