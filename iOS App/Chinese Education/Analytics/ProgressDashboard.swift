import Foundation
import SwiftUI

// MARK: - 📊 PROGRESS DASHBOARD - Data Model for Progress Visualization
struct ProgressDashboardData {
    let pirlsProcessScores: [PIRLSProcess: Double]
    let vocabularyStats: VocabularyStats
    let readingPurposeBalance: (literary: Double, informational: Double)
    let recentTrends: ReadingTrends
    let recommendations: [Recommendation]
    let levelProgression: LevelProgressionData
}

struct LevelProgressionData {
    let currentLevel: Int
    let progressToNextLevel: Double  // 0.0 to 1.0
    let xpRequired: Int
    let xpCurrent: Int
}

// MARK: - Progress Dashboard Helper
class ProgressDashboard {
    static func generateDashboardData() -> ProgressDashboardData {
        let profile = StudentProfile.shared
        let analytics = PIRLSAnalytics.shared
        let vocabStats = VocabularyManager.shared.getStatistics()
        
        // Get PIRLS process scores
        var processScores: [PIRLSProcess: Double] = [:]
        for process in PIRLSProcess.allCases {
            if let performance = profile.pirlsAssessment.processPerformance[process] {
                processScores[process] = performance.masteryLevel
            }
        }
        
        // Get reading purpose balance
        let readingPurposeBalance = (
            literary: profile.literaryPerformance,
            informational: profile.informationalPerformance
        )
        
        // Get recent trends
        let recentTrends = analytics.analyzeReadingTrends(profile.performanceHistory, days: 30)
        
        // Get recommendations
        let recommendations = analytics.generateRecommendations(profile)
        
        // Calculate level progression
        let levelProgression = LevelProgressionData(
            currentLevel: profile.currentLevel,
            progressToNextLevel: profile.pirlsAssessment.overallScore,
            xpRequired: profile.currentLevel * 100,
            xpCurrent: PlayerProgress.shared.xp
        )
        
        return ProgressDashboardData(
            pirlsProcessScores: processScores,
            vocabularyStats: vocabStats,
            readingPurposeBalance: readingPurposeBalance,
            recentTrends: recentTrends,
            recommendations: recommendations,
            levelProgression: levelProgression
        )
    }
}

