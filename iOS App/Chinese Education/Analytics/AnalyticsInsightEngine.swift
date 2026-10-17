import Foundation

// MARK: - Insight models

struct AnalyticsInsight: Equatable {
    enum Kind: String, Equatable {
        case strength
        case weakness
        case recommendation
        case atRisk
        case trend
        case info
    }

    let kind: Kind
    let title: String
    let detail: String
    let action: String?
}

struct StudentAnalyticsSnapshot: Equatable {
    let studentID: String
    let studentName: String
    let totalAnswers: Int
    let accuracy: Double
    let averageResponseTime: TimeInterval
    let currentStreak: Int
    let bestStreak: Int
    let accuracyBySkill: [String: Double]
    let weakestSkills: [String]
    let weakestQuestionTypes: [String]
    let weakestPassages: [String]
    let recentTrendDelta: Double
    let insights: [AnalyticsInsight]
}

struct ClassAnalyticsSnapshot: Equatable {
    let studentCount: Int
    let totalAnswers: Int
    let classAccuracy: Double
    let averageResponseTime: TimeInterval
    let accuracyBySkill: [String: Double]
    let weakestSkills: [String]
    let atRiskStudentIDs: [String]
    let atRiskStudentNames: [String]
    let insights: [AnalyticsInsight]
    let perStudent: [StudentAnalyticsSnapshot]
}

/// Pluggable analysis surface — rule-based today; swap in an LLM provider later.
protocol AnalyticsInsightProviding {
    func analyzeStudent(studentID: String, studentName: String?, records: [StudentAnswerLogRecord]) -> StudentAnalyticsSnapshot
    func analyzeClass(roster: [(id: String, name: String)], records: [StudentAnswerLogRecord]) -> ClassAnalyticsSnapshot
}

/// Optional future LLM hook. Implementations should return plain-language insights
/// without changing the dashboard layout contract.
protocol LLMAnalyticsInsightProviding: AnalyticsInsightProviding {
    /// When true, `analyzeStudent` / `analyzeClass` may call a remote model.
    var isLLMEnabled: Bool { get }
}

// MARK: - Rule-based engine

final class RuleBasedAnalyticsInsightEngine: AnalyticsInsightProviding {
    static let shared = RuleBasedAnalyticsInsightEngine()

    /// Accuracy below this (with enough samples) flags a student as at-risk.
    var atRiskAccuracyThreshold: Double = 0.45
    var atRiskMinimumAnswers: Int = 6
    var skillSampleFloor: Int = 2

    func analyzeStudent(studentID: String, studentName: String?, records: [StudentAnswerLogRecord]) -> StudentAnalyticsSnapshot {
        let mine = records
            .filter { $0.studentID == studentID }
            .sorted { $0.date < $1.date }
        let name = studentName ?? mine.last?.studentName ?? studentID
        let total = mine.count
        let correct = mine.filter(\.isCorrect).count
        let accuracy = total > 0 ? Double(correct) / Double(total) : 0
        let avgTime = averageTime(mine)
        let (currentStreak, bestStreak) = streaks(mine)
        let bySkill = accuracyByGrouping(mine) { skillKey(for: $0) }
        let byType = accuracyByGrouping(mine) { $0.questionType.isEmpty ? "未分類" : $0.questionType }
        let byPassage = accuracyByGrouping(mine) { $0.passageKey }
        let weakSkills = weakestKeys(bySkill, limit: 3)
        let weakTypes = weakestKeys(byType, limit: 3)
        let weakPassages = weakestKeys(byPassage, limit: 3)
        let trend = recentTrendDelta(mine)
        let insights = buildStudentInsights(
            name: name,
            total: total,
            accuracy: accuracy,
            avgTime: avgTime,
            currentStreak: currentStreak,
            weakSkills: weakSkills,
            weakTypes: weakTypes,
            weakPassages: weakPassages,
            trend: trend,
            bySkill: bySkill
        )
        return StudentAnalyticsSnapshot(
            studentID: studentID,
            studentName: name,
            totalAnswers: total,
            accuracy: accuracy,
            averageResponseTime: avgTime,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            accuracyBySkill: bySkill,
            weakestSkills: weakSkills,
            weakestQuestionTypes: weakTypes,
            weakestPassages: weakPassages,
            recentTrendDelta: trend,
            insights: insights
        )
    }

    func analyzeClass(roster: [(id: String, name: String)], records: [StudentAnswerLogRecord]) -> ClassAnalyticsSnapshot {
        let ids: [(String, String)]
        if roster.isEmpty {
            let grouped = Dictionary(grouping: records, by: \.studentID)
            ids = grouped.keys.sorted().map { id in
                (id, grouped[id]?.last?.studentName ?? id)
            }
        } else {
            ids = roster.map { ($0.id, $0.name) }
        }

        let perStudent = ids.map { analyzeStudent(studentID: $0.0, studentName: $0.1, records: records) }
        let all = records
        let total = all.count
        let classAccuracy = total > 0 ? Double(all.filter(\.isCorrect).count) / Double(total) : 0
        let avgTime = averageTime(all)
        let bySkill = accuracyByGrouping(all) { skillKey(for: $0) }
        let weakSkills = weakestKeys(bySkill, limit: 3)
        let atRisk = perStudent.filter {
            $0.totalAnswers >= atRiskMinimumAnswers && $0.accuracy < atRiskAccuracyThreshold
        }
        var insights: [AnalyticsInsight] = []
        if total == 0 {
            insights.append(AnalyticsInsight(
                kind: .info,
                title: "尚無作答紀錄",
                detail: "學生開始作答後，這裡會顯示班級正確率、弱項與風險提醒。",
                action: nil
            ))
        } else {
            insights.append(AnalyticsInsight(
                kind: .info,
                title: "班級總覽",
                detail: String(format: "共 %d 筆作答，班級正確率 %.0f%%，平均作答 %.1f 秒。", total, classAccuracy * 100, avgTime),
                action: nil
            ))
            if !weakSkills.isEmpty {
                insights.append(AnalyticsInsight(
                    kind: .weakness,
                    title: "班級較弱技能",
                    detail: "正確率偏低：\(weakSkills.joined(separator: "、"))。",
                    action: "下一堂課優先安排相關短篇與引導練習。"
                ))
            }
            if !atRisk.isEmpty {
                insights.append(AnalyticsInsight(
                    kind: .atRisk,
                    title: "需關注學生",
                    detail: atRisk.map { "\($0.studentName)（\(Int($0.accuracy * 100))%）" }.joined(separator: "、"),
                    action: "建議一對一複習弱項篇章，並縮短單次題量。"
                ))
            } else if perStudent.contains(where: { $0.totalAnswers >= atRiskMinimumAnswers }) {
                insights.append(AnalyticsInsight(
                    kind: .strength,
                    title: "班級穩定",
                    detail: "目前沒有低於風險門檻的學生。",
                    action: "可逐步提高推論與評鑑題比例。"
                ))
            }
        }
        return ClassAnalyticsSnapshot(
            studentCount: ids.count,
            totalAnswers: total,
            classAccuracy: classAccuracy,
            averageResponseTime: avgTime,
            accuracyBySkill: bySkill,
            weakestSkills: weakSkills,
            atRiskStudentIDs: atRisk.map(\.studentID),
            atRiskStudentNames: atRisk.map(\.studentName),
            insights: insights,
            perStudent: perStudent
        )
    }

    // MARK: - Helpers

    func skillKey(for record: StudentAnswerLogRecord) -> String {
        if let raw = record.pirlsProcessRaw, let process = PIRLSProcess(rawValue: raw) {
            return process.displayName
        }
        if !record.questionType.isEmpty { return record.questionType }
        return "未分類"
    }

    func averageTime(_ records: [StudentAnswerLogRecord]) -> TimeInterval {
        guard !records.isEmpty else { return 0 }
        return records.map(\.responseTimeSeconds).reduce(0, +) / Double(records.count)
    }

    func streaks(_ records: [StudentAnswerLogRecord]) -> (current: Int, best: Int) {
        var best = 0
        var run = 0
        for r in records {
            if r.isCorrect {
                run += 1
                best = max(best, run)
            } else {
                run = 0
            }
        }
        var current = 0
        for r in records.reversed() {
            if r.isCorrect { current += 1 } else { break }
        }
        return (current, best)
    }

    func accuracyByGrouping(_ records: [StudentAnswerLogRecord], key: (StudentAnswerLogRecord) -> String) -> [String: Double] {
        let grouped = Dictionary(grouping: records, by: key)
        var out: [String: Double] = [:]
        for (k, items) in grouped where items.count >= skillSampleFloor {
            let correct = items.filter(\.isCorrect).count
            out[k] = Double(correct) / Double(items.count)
        }
        return out
    }

    func weakestKeys(_ map: [String: Double], limit: Int) -> [String] {
        map.sorted { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key < rhs.key }
            return lhs.value < rhs.value
        }
        .prefix(limit)
        .map(\.key)
    }

    func recentTrendDelta(_ records: [StudentAnswerLogRecord]) -> Double {
        guard records.count >= 6 else { return 0 }
        let half = records.count / 2
        let older = Array(records.prefix(half))
        let newer = Array(records.suffix(records.count - half))
        let olderAcc = older.isEmpty ? 0 : Double(older.filter(\.isCorrect).count) / Double(older.count)
        let newerAcc = newer.isEmpty ? 0 : Double(newer.filter(\.isCorrect).count) / Double(newer.count)
        return newerAcc - olderAcc
    }

    private func buildStudentInsights(
        name: String,
        total: Int,
        accuracy: Double,
        avgTime: TimeInterval,
        currentStreak: Int,
        weakSkills: [String],
        weakTypes: [String],
        weakPassages: [String],
        trend: Double,
        bySkill: [String: Double]
    ) -> [AnalyticsInsight] {
        var insights: [AnalyticsInsight] = []
        if total == 0 {
            return [AnalyticsInsight(
                kind: .info,
                title: "尚無資料",
                detail: "\(name) 還沒有作答紀錄。",
                action: "請先完成一篇閱讀測驗。"
            )]
        }

        let strong = bySkill.filter { $0.value >= 0.75 }.sorted { $0.value > $1.value }.prefix(2).map(\.key)
        if !strong.isEmpty {
            insights.append(AnalyticsInsight(
                kind: .strength,
                title: "優勢技能",
                detail: "\(name) 在\(strong.joined(separator: "、"))表現較穩（正確率 ≥ 75%）。",
                action: "可作為同儕互助或示範題型。"
            ))
        }
        if !weakSkills.isEmpty {
            insights.append(AnalyticsInsight(
                kind: .weakness,
                title: "需加強技能",
                detail: "較弱：\(weakSkills.joined(separator: "、"))。",
                action: "建議下一篇聚焦這些 PIRLS 過程的短文練習。"
            ))
        }
        if !weakTypes.isEmpty {
            insights.append(AnalyticsInsight(
                kind: .weakness,
                title: "題型弱點",
                detail: "題型正確率偏低：\(weakTypes.joined(separator: "、"))。",
                action: "先用選擇題熱身，再過渡到開放作答。"
            ))
        }
        if !weakPassages.isEmpty {
            let suggested = suggestedNextPassages(avoiding: weakPassages, preferringSkills: weakSkills)
            insights.append(AnalyticsInsight(
                kind: .recommendation,
                title: "建議下一篇",
                detail: "薄弱篇章：\(weakPassages.joined(separator: "、"))。可改練：\(suggested.joined(separator: "、"))。",
                action: "從建議篇章中選一篇做引導閱讀。"
            ))
        }
        if trend >= 0.08 {
            insights.append(AnalyticsInsight(
                kind: .trend,
                title: "近期進步",
                detail: String(format: "後半段正確率比前半段高 %.0f 個百分點。", trend * 100),
                action: "維持目前節奏與題量。"
            ))
        } else if trend <= -0.08 {
            insights.append(AnalyticsInsight(
                kind: .trend,
                title: "近期下滑",
                detail: String(format: "後半段正確率比前半段低 %.0f 個百分點。", abs(trend) * 100),
                action: "縮短練習時段，並複習錯題說明。"
            ))
        }
        if currentStreak >= 3 {
            insights.append(AnalyticsInsight(
                kind: .strength,
                title: "連續答對",
                detail: "目前連續答對 \(currentStreak) 題。",
                action: nil
            ))
        }
        if total >= atRiskMinimumAnswers && accuracy < atRiskAccuracyThreshold {
            insights.append(AnalyticsInsight(
                kind: .atRisk,
                title: "風險提醒",
                detail: String(format: "%@ 正確率僅 %.0f%%（%d 題），平均 %.1f 秒。", name, accuracy * 100, total, avgTime),
                action: "建議教師個別關心，並降低難度一階。"
            ))
        }
        insights.append(AnalyticsInsight(
            kind: .info,
            title: "作答節奏",
            detail: String(format: "平均作答時間 %.1f 秒；累計 %d 題，正確率 %.0f%%。", avgTime, total, accuracy * 100),
            action: nil
        ))
        return insights
    }

    /// Prefer intervention passages for weak skills; fall back to later bank passages.
    func suggestedNextPassages(avoiding weak: [String], preferringSkills skills: [String], limit: Int = 3) -> [String] {
        var candidates: [String] = []
        for skillName in skills {
            if let process = PIRLSProcess.allCases.first(where: { $0.displayName == skillName }) {
                let passages = InterventionEngine.shared.getProcessInterventionStrategy(process).passages
                candidates.append(contentsOf: passages)
            }
        }
        if candidates.isEmpty {
            candidates = (1...18).map { "passage\($0)" }
        }
        let weakSet = Set(weak)
        let filtered = candidates.filter { !weakSet.contains($0) }
        var seen = Set<String>()
        var unique: [String] = []
        for key in filtered + candidates {
            if seen.insert(key).inserted {
                unique.append(key)
            }
            if unique.count >= limit { break }
        }
        return unique
    }
}

/// Facade used by the teacher dashboard. Default provider is rule-based;
/// assign `provider` to an LLM adapter when one is available.
enum AnalyticsInsightEngine {
    static var provider: AnalyticsInsightProviding = RuleBasedAnalyticsInsightEngine.shared

    static func studentSnapshot(studentID: String, studentName: String? = nil) -> StudentAnalyticsSnapshot {
        provider.analyzeStudent(
            studentID: studentID,
            studentName: studentName,
            records: AnswerHistoryStore.shared.allRecords()
        )
    }

    static func classSnapshot(roster: [(id: String, name: String)]) -> ClassAnalyticsSnapshot {
        provider.analyzeClass(roster: roster, records: AnswerHistoryStore.shared.allRecords())
    }
}
