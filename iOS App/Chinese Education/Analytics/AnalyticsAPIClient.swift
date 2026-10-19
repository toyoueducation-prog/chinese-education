import Foundation

/// Configurable Alibaba ECS analytics backend. Empty base URL keeps the app fully offline.
enum AnalyticsServerConfig {
    static var baseURLString: String {
        get { UserDefaults.standard.string(forKey: "analyticsServerBaseURL") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "analyticsServerBaseURL") }
    }

    static var authToken: String {
        get { UserDefaults.standard.string(forKey: "analyticsServerToken") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "analyticsServerToken") }
    }

    static var isConfigured: Bool {
        guard let url = URL(string: baseURLString), url.scheme != nil, !authToken.isEmpty else { return false }
        return true
    }
}

/// Offline queue + retry for per-answer events destined for the ECS analytics API.
final class AnalyticsAPIClient {
    static let shared = AnalyticsAPIClient()

    private let queueKey = "analyticsPendingAnswerEvents_v1"
    private let queue = DispatchQueue(label: "AnalyticsAPIClient.queue")
    private var isFlushing = false

    private init() {}

    struct OutboundAnswerEvent: Codable, Equatable {
        let client_event_id: String
        let student_external_id: String
        let student_name: String?
        let passage_key: String
        let question_key: String
        let question_type: String
        let question_preview: String
        let student_answer: String
        let correct_answer: String
        let is_correct: Bool
        let response_time_seconds: Double
        let attempt_number: Int
        let pirls_process: String?
        let reading_purpose: String?
        let answered_at: String
    }

    struct StudentMetricsDTO: Codable {
        let student_external_id: String
        let student_name: String
        let total_answers: Int
        let accuracy: Double
        let average_response_time: Double
        let current_streak: Int
        let best_streak: Int
        let accuracy_by_skill: [String: Double]
        let weakest_skills: [String]
        let weakest_question_types: [String]
        let insights: [InsightDTO]
        let source: String?
    }

    struct ClassMetricsDTO: Codable {
        let class_id: Int
        let class_name: String
        let student_count: Int
        let total_answers: Int
        let class_accuracy: Double
        let average_response_time: Double
        let accuracy_by_skill: [String: Double]
        let weakest_skills: [String]
        let at_risk_students: [String]
        let insights: [InsightDTO]
        let source: String?
    }

    struct InsightDTO: Codable {
        let kind: String
        let title: String
        let detail: String
        let action: String?
    }

    func enqueue(record: StudentAnswerLogRecord) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let event = OutboundAnswerEvent(
            client_event_id: record.id,
            student_external_id: record.studentID,
            student_name: record.studentName,
            passage_key: record.passageKey,
            question_key: record.questionKey,
            question_type: record.questionType,
            question_preview: record.questionPreview,
            student_answer: record.studentAnswer,
            correct_answer: record.correctAnswer,
            is_correct: record.isCorrect,
            response_time_seconds: record.responseTimeSeconds,
            attempt_number: record.attemptNumber,
            pirls_process: record.pirlsProcessRaw,
            reading_purpose: record.readingPurposeRaw,
            answered_at: formatter.string(from: record.date)
        )
        queue.async {
            var pending = self.loadPending()
            pending.append(event)
            if pending.count > 500 {
                pending.removeFirst(pending.count - 500)
            }
            self.savePending(pending)
            self.flushIfNeeded()
        }
    }

    func flushIfNeeded() {
        queue.async {
            guard !self.isFlushing, AnalyticsServerConfig.isConfigured else { return }
            let pending = self.loadPending()
            guard !pending.isEmpty else { return }
            self.isFlushing = true
            let batch = Array(pending.prefix(50))
            self.postBatch(batch) { success in
                self.queue.async {
                    if success {
                        var remaining = self.loadPending()
                        let ids = Set(batch.map(\.client_event_id))
                        remaining.removeAll { ids.contains($0.client_event_id) }
                        self.savePending(remaining)
                    }
                    self.isFlushing = false
                    if success, !self.loadPending().isEmpty {
                        self.flushIfNeeded()
                    }
                }
            }
        }
    }

    func fetchStudentMetrics(externalID: String, completion: @escaping (StudentMetricsDTO?) -> Void) {
        guard AnalyticsServerConfig.isConfigured,
              let base = URL(string: AnalyticsServerConfig.baseURLString) else {
            completion(nil)
            return
        }
        let url = base.appendingPathComponent("analytics/students/\(externalID)")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(AnalyticsServerConfig.authToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { data, response, _ in
            guard let data,
                  let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let dto = try? JSONDecoder().decode(StudentMetricsDTO.self, from: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(dto) }
        }.resume()
    }

    func fetchClassMetrics(classID: Int, completion: @escaping (ClassMetricsDTO?) -> Void) {
        guard AnalyticsServerConfig.isConfigured,
              let base = URL(string: AnalyticsServerConfig.baseURLString) else {
            completion(nil)
            return
        }
        let url = base.appendingPathComponent("analytics/classes/\(classID)")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(AnalyticsServerConfig.authToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { data, response, _ in
            guard let data,
                  let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let dto = try? JSONDecoder().decode(ClassMetricsDTO.self, from: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(dto) }
        }.resume()
    }

    private func postBatch(_ events: [OutboundAnswerEvent], completion: @escaping (Bool) -> Void) {
        guard let base = URL(string: AnalyticsServerConfig.baseURLString) else {
            completion(false)
            return
        }
        let url = base.appendingPathComponent("answers/batch")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(AnalyticsServerConfig.authToken)", forHTTPHeaderField: "Authorization")
        struct BatchBody: Encodable { let events: [OutboundAnswerEvent] }
        req.httpBody = try? JSONEncoder().encode(BatchBody(events: events))
        URLSession.shared.dataTask(with: req) { _, response, _ in
            let ok = (response as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
            completion(ok)
        }.resume()
    }

    private func loadPending() -> [OutboundAnswerEvent] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let decoded = try? JSONDecoder().decode([OutboundAnswerEvent].self, from: data) else {
            return []
        }
        return decoded
    }

    private func savePending(_ events: [OutboundAnswerEvent]) {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }
}
