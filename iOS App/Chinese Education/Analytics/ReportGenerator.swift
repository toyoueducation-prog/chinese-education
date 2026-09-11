import Foundation
import UIKit

// MARK: - 📄 REPORT GENERATOR - Generate PDF Reports for Teachers/Parents
class ReportGenerator {
    static let shared = ReportGenerator()
    
    private init() {}
    
    // MARK: - Generate PDF Report
    func generatePDFReport(completion: @escaping (URL?) -> Void) {
        let profile = StudentProfile.shared
        let analytics = PIRLSAnalytics.shared
        let vocabStats = VocabularyManager.shared.getStatistics()
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Chinese Education App",
            kCGPDFContextAuthor: "Student Progress Report",
            kCGPDFContextTitle: "PIRLS Reading Comprehension Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var currentY: CGFloat = 50
            
            // Title
            currentY = drawTitle("學生閱讀理解進度報告", y: currentY, context: context, pageRect: pageRect)
            currentY += 20
            
            // Student Information
            currentY = drawSection("學生資訊", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("姓名: \(profile.studentName ?? "未設定")", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("年級: 小學 \(profile.currentLevel) 年級", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("報告日期: \(formatDate(Date()))", y: currentY, context: context, pageRect: pageRect)
            currentY += 20
            
            // PIRLS Process Breakdown
            currentY = drawSection("PIRLS 閱讀理解能力分析", y: currentY, context: context, pageRect: pageRect)
            for process in PIRLSProcess.allCases {
                if let performance = profile.pirlsAssessment.processPerformance[process] {
                    let score = Int(performance.masteryLevel * 100)
                    currentY = drawText("\(process.displayName): \(score)% (正確率: \(Int(performance.accuracyRate * 100))%)", y: currentY, context: context, pageRect: pageRect)
                }
            }
            currentY += 20
            
            // Vocabulary Mastery Summary
            currentY = drawSection("詞彙掌握摘要", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("總詞彙數: \(vocabStats.totalWords)", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("已掌握: \(vocabStats.masteredWords)", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("熟練: \(vocabStats.proficientWords)", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("掌握率: \(Int(vocabStats.masteryRate * 100))%", y: currentY, context: context, pageRect: pageRect)
            currentY += 20
            
            // Reading Comprehension Trends
            currentY = drawSection("閱讀理解趨勢", y: currentY, context: context, pageRect: pageRect)
            let trends = analytics.analyzeReadingTrends(profile.performanceHistory, days: 30)
            currentY = drawText("近30天答題數: \(trends.totalQuestions)", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("正確率: \(Int(trends.accuracyRate * 100))%", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("平均答題時間: \(String(format: "%.1f", trends.averageResponseTime))秒", y: currentY, context: context, pageRect: pageRect)
            currentY += 20
            
            // Recommendations
            currentY = drawSection("學習建議", y: currentY, context: context, pageRect: pageRect)
            let recommendations = analytics.generateRecommendations(profile)
            for (index, rec) in recommendations.enumerated() {
                currentY = drawText("\(index + 1). \(rec.title)", y: currentY, context: context, pageRect: pageRect)
                currentY = drawText("   \(rec.description)", y: currentY, context: context, pageRect: pageRect)
            }
            
            // Benchmark Comparison (Phase 1.3)
            currentY += 10
            currentY = drawSection("年級水平比較", y: currentY, context: context, pageRect: pageRect)
            let benchmark = analytics.benchmarkAgainstGradeLevel(profile)
            currentY = drawText("百分位排名: \(benchmark.percentile)th", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("水平評估: \(benchmark.isAboveGradeLevel ? "高於" : (benchmark.isAtGradeLevel ? "達到" : "低於"))年級標準", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("25th百分位: \(Int(benchmark.benchmark25th * 100))% | 50th百分位: \(Int(benchmark.benchmark50th * 100))% | 75th百分位: \(Int(benchmark.benchmark75th * 100))%", y: currentY, context: context, pageRect: pageRect)
            
            // Process-specific benchmarks
            currentY += 10
            currentY = drawText("各過程水平:", y: currentY, context: context, pageRect: pageRect)
            for process in PIRLSProcess.allCases {
                if let status = benchmark.processBenchmarks[process] {
                    let statusText = status == .aboveBenchmark ? "高於" : (status == .atBenchmark ? "達到" : "低於")
                    currentY = drawText("  \(process.displayName): \(statusText)標準", y: currentY, context: context, pageRect: pageRect)
                }
            }
            
            // Vocabulary Growth Chart Data (Phase 1.3)
            currentY += 20
            currentY = drawSection("詞彙成長趨勢", y: currentY, context: context, pageRect: pageRect)
            let vocabGrowth = analytics.analyzeVocabularyGrowth(vocabStats, previousStats: nil)
            currentY = drawText("本週新增詞彙: \(vocabGrowth.newWordsThisPeriod)", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("本週掌握詞彙: \(vocabGrowth.newMasteredThisPeriod)", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("成長率: \(String(format: "%.1f", vocabGrowth.growthRate * 100))%", y: currentY, context: context, pageRect: pageRect)
            
            // Reading Purpose Balance (Phase 1.3)
            currentY += 20
            currentY = drawSection("閱讀類型平衡", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("文學類表現: \(Int(profile.literaryPerformance * 100))%", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("資訊類表現: \(Int(profile.informationalPerformance * 100))%", y: currentY, context: context, pageRect: pageRect)
            let balance = abs(profile.literaryPerformance - profile.informationalPerformance)
            if balance > 0.3 {
                let weaker = profile.literaryPerformance < profile.informationalPerformance ? "文學類" : "資訊類"
                currentY = drawText("建議: 增加\(weaker)閱讀練習以達到平衡", y: currentY, context: context, pageRect: pageRect)
            } else {
                currentY = drawText("閱讀類型平衡良好", y: currentY, context: context, pageRect: pageRect)
            }
        }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("progress_report_\(Date().timeIntervalSince1970).pdf")
        
        do {
            try data.write(to: tempURL)
            completion(tempURL)
        } catch {
            print("Error writing PDF: \(error)")
            completion(nil)
        }
    }
    
    // MARK: - Helper Methods
    private func drawTitle(_ text: String, y: CGFloat, context: UIGraphicsPDFRendererContext, pageRect: CGRect) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textRect = CGRect(x: 50, y: y, width: pageRect.width - 100, height: 30)
        attributedString.draw(in: textRect)
        return y + 30
    }
    
    private func drawSection(_ text: String, y: CGFloat, context: UIGraphicsPDFRendererContext, pageRect: CGRect) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textRect = CGRect(x: 50, y: y, width: pageRect.width - 100, height: 25)
        attributedString.draw(in: textRect)
        return y + 25
    }
    
    private func drawText(_ text: String, y: CGFloat, context: UIGraphicsPDFRendererContext, pageRect: CGRect) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textRect = CGRect(x: 50, y: y, width: pageRect.width - 100, height: 20)
        attributedString.draw(in: textRect)
        return y + 20
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
    
    // MARK: - Generate Weekly Progress Summary (Phase 5.2)
    func generateWeeklySummary(completion: @escaping (URL?) -> Void) {
        let profile = StudentProfile.shared
        let analytics = PIRLSAnalytics.shared
        let trends = analytics.analyzeReadingTrends(profile.performanceHistory, days: 7)
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Chinese Education App",
            kCGPDFContextAuthor: "Weekly Progress Summary",
            kCGPDFContextTitle: "週進度摘要"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var currentY: CGFloat = 50
            
            currentY = drawTitle("本週學習進度摘要", y: currentY, context: context, pageRect: pageRect)
            currentY += 20
            
            currentY = drawText("週期: 過去7天", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("答題總數: \(trends.totalQuestions)", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("正確率: \(Int(trends.accuracyRate * 100))%", y: currentY, context: context, pageRect: pageRect)
            currentY = drawText("平均答題時間: \(String(format: "%.1f", trends.averageResponseTime))秒", y: currentY, context: context, pageRect: pageRect)
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("weekly_summary_\(Date().timeIntervalSince1970).pdf")
        
        do {
            try data.write(to: tempURL)
            completion(tempURL)
        } catch {
            print("Error writing PDF: \(error)")
            completion(nil)
        }
    }
    
    // MARK: - Generate Process Breakdown Report (Phase 5.2)
    func generateProcessBreakdownReport(completion: @escaping (URL?) -> Void) {
        let profile = StudentProfile.shared
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Chinese Education App",
            kCGPDFContextAuthor: "PIRLS Process Breakdown",
            kCGPDFContextTitle: "PIRLS過程詳細分析"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var currentY: CGFloat = 50
            
            currentY = drawTitle("PIRLS過程詳細分析報告", y: currentY, context: context, pageRect: pageRect)
            currentY += 20
            
            for process in PIRLSProcess.allCases {
                if let performance = profile.pirlsAssessment.processPerformance[process] {
                    currentY = drawSection("\(process.displayName)", y: currentY, context: context, pageRect: pageRect)
                    currentY = drawText("掌握程度: \(Int(performance.masteryLevel * 100))%", y: currentY, context: context, pageRect: pageRect)
                    currentY = drawText("正確率: \(Int(performance.accuracyRate * 100))%", y: currentY, context: context, pageRect: pageRect)
                    currentY = drawText("總題數: \(performance.totalQuestions)", y: currentY, context: context, pageRect: pageRect)
                    currentY = drawText("平均答題時間: \(String(format: "%.1f", performance.averageResponseTime))秒", y: currentY, context: context, pageRect: pageRect)
                    currentY = drawText("說明: \(process.description)", y: currentY, context: context, pageRect: pageRect)
                    currentY += 10
                }
            }
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("process_breakdown_\(Date().timeIntervalSince1970).pdf")
        
        do {
            try data.write(to: tempURL)
            completion(tempURL)
        } catch {
            print("Error writing PDF: \(error)")
            completion(nil)
        }
    }
    
    // MARK: - Export to Alibaba ECS
    func exportReportToServer(completion: @escaping (Bool) -> Void) {
        generatePDFReport { url in
            guard let url = url,
                  let pdfData = try? Data(contentsOf: url),
                  let uploadURL = QuestionBankAPI.studentProgressURL() else {
                completion(false)
                return
            }
            
            var request = URLRequest(url: uploadURL)
            request.httpMethod = "POST"
            request.setValue("application/pdf", forHTTPHeaderField: "Content-Type")
            request.httpBody = pdfData
            
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
    }
}

