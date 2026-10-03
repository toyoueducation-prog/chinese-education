import Foundation

/// Append-only log of every submitted answer on this device, keyed by `studentID`, for analysis and content review.
/// Stored in `UserDefaults` separate from `StudentProfile` so it is not truncated with the in-profile performance tail.
final class AnswerHistoryStore {
    static let shared = AnswerHistoryStore()
    
    private let defaultsKey = "studentAnswerHistoryLog_v1"
    private let maxRecords = 4000
    private let queue = DispatchQueue(label: "AnswerHistoryStore.queue")
    
    private init() {}
    
    func append(
        studentID: String,
        studentName: String?,
        passageKey: String,
        question: Question,
        studentAnswer: String,
        isCorrect: Bool,
        responseTime: TimeInterval
    ) {
        let previewLimit = 160
        let qText = question.question
        let preview = qText.count <= previewLimit ? qText : String(qText.prefix(previewLimit)) + "…"
        
        let record = StudentAnswerLogRecord(
            id: UUID().uuidString,
            studentID: studentID,
            studentName: studentName,
            date: Date(),
            passageKey: passageKey,
            questionKey: question.key,
            questionType: question.type,
            questionPreview: preview,
            studentAnswer: studentAnswer,
            correctAnswer: question.answer,
            isCorrect: isCorrect,
            responseTimeSeconds: responseTime,
            pirlsProcessRaw: question.pirlsProcess?.rawValue,
            readingPurposeRaw: question.readingPurpose?.rawValue
        )
        
        queue.async { [defaultsKey, maxRecords] in
            var items = Self.loadRaw(from: defaultsKey)
            items.append(record)
            if items.count > maxRecords {
                items.removeFirst(items.count - maxRecords)
            }
            Self.saveRaw(items, key: defaultsKey)
        }
    }
    
    func allRecords() -> [StudentAnswerLogRecord] {
        queue.sync { Self.loadRaw(from: defaultsKey) }
    }
    
    func records(forStudentID id: String) -> [StudentAnswerLogRecord] {
        allRecords().filter { $0.studentID == id }
    }
    
    /// Recent per-process miss counts from local answer log (offline), used to bias adaptive selection.
    func recentProcessMissCounts(forStudentID id: String, limit: Int = 40) -> [PIRLSProcess: Int] {
        let recent = Array(records(forStudentID: id).suffix(limit))
        var misses: [PIRLSProcess: Int] = [:]
        for record in recent where !record.isCorrect {
            guard let raw = record.pirlsProcessRaw,
                  let process = PIRLSProcess(rawValue: raw) else { continue }
            misses[process, default: 0] += 1
        }
        return misses
    }
    
    /// CSV with header; fields quoted when needed.
    func buildCSV() -> String {
        let records = allRecords()
        var lines: [String] = []
        lines.append("timestamp,studentID,studentName,passageKey,questionKey,questionType,isCorrect,responseTimeSeconds,pirlsProcess,readingPurpose,questionPreview,studentAnswer,correctAnswer")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for r in records {
            let ts = formatter.string(from: r.date)
            let row = [
                Self.csvEscape(ts),
                Self.csvEscape(r.studentID),
                Self.csvEscape(r.studentName ?? ""),
                Self.csvEscape(r.passageKey),
                Self.csvEscape(r.questionKey),
                Self.csvEscape(r.questionType),
                r.isCorrect ? "1" : "0",
                String(format: "%.2f", r.responseTimeSeconds),
                Self.csvEscape(r.pirlsProcessRaw ?? ""),
                Self.csvEscape(r.readingPurposeRaw ?? ""),
                Self.csvEscape(r.questionPreview),
                Self.csvEscape(r.studentAnswer),
                Self.csvEscape(r.correctAnswer)
            ].joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }
    
    private static func csvEscape(_ field: String) -> String {
        let needsQuote = field.contains(",") || field.contains("\n") || field.contains("\"") || field.contains("\r")
        let doubled = field.replacingOccurrences(of: "\"", with: "\"\"")
        if needsQuote { return "\"\(doubled)\"" }
        return doubled
    }
    
    private static func loadRaw(from key: String) -> [StudentAnswerLogRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([StudentAnswerLogRecord].self, from: data) else {
            return []
        }
        return decoded
    }
    
    private static func saveRaw(_ records: [StudentAnswerLogRecord], key: String) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

struct StudentAnswerLogRecord: Codable, Equatable {
    let id: String
    let studentID: String
    let studentName: String?
    let date: Date
    let passageKey: String
    let questionKey: String
    let questionType: String
    let questionPreview: String
    let studentAnswer: String
    let correctAnswer: String
    let isCorrect: Bool
    let responseTimeSeconds: TimeInterval
    let pirlsProcessRaw: String?
    let readingPurposeRaw: String?
}
