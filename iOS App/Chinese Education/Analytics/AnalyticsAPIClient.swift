import Foundation

/// Configurable Alibaba ECS analytics backend (Insight Meter).
/// Default base URL is `https://api.insightmeter.site/api` (no trailing slash).
/// Tokens live in the Keychain — never hardcode real secrets.
enum AnalyticsServerConfig {
    static let defaultBaseURLString = "https://api.insightmeter.site/api"

    private static let baseURLKey = "analyticsServerBaseURL"
    private static let classIDKey = "analyticsServerClassID"
    private static let inviteCodeKey = "studentClassInviteCode"
    private static let legacyTokenKey = "analyticsServerToken"
    private static let ingestAccount = "analyticsIngestToken"
    private static let adminAccount = "analyticsAdminToken"

    /// Analytics API root, e.g. `https://api.insightmeter.site/api` (no trailing slash).
    static var baseURLString: String {
        get {
            let raw = UserDefaults.standard.string(forKey: baseURLKey)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if raw.isEmpty { return defaultBaseURLString }
            return Self.normalizedBaseURL(raw)
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                UserDefaults.standard.set(defaultBaseURLString, forKey: baseURLKey)
            } else {
                UserDefaults.standard.set(Self.normalizedBaseURL(trimmed), forKey: baseURLKey)
            }
        }
    }

    /// Device / ingest bearer token — used for student upsert and answer batch upload.
    static var ingestToken: String {
        get {
            migrateLegacyTokenIfNeeded()
            return KeychainStore.get(account: ingestAccount)
        }
        set { KeychainStore.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), account: ingestAccount) }
    }

    /// Teacher / admin bearer token — used for class create and analytics reads.
    static var adminToken: String {
        get {
            migrateLegacyTokenIfNeeded()
            return KeychainStore.get(account: adminAccount)
        }
        set { KeychainStore.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), account: adminAccount) }
    }

    /// Back-compat alias used by older code paths; maps to ingest token.
    static var authToken: String {
        get { ingestToken }
        set { ingestToken = newValue }
    }

    static var classID: Int? {
        get {
            let value = UserDefaults.standard.object(forKey: classIDKey)
            if let int = value as? Int { return int }
            if let num = value as? NSNumber { return num.intValue }
            return nil
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: classIDKey)
            } else {
                UserDefaults.standard.removeObject(forKey: classIDKey)
            }
        }
    }

    /// Invite code the student entered to join a class (also sent on batch upload).
    static var studentClassInviteCode: String {
        get {
            UserDefaults.standard.string(forKey: inviteCodeKey)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        set {
            UserDefaults.standard.set(
                newValue.trimmingCharacters(in: .whitespacesAndNewlines),
                forKey: inviteCodeKey
            )
        }
    }

    static var isIngestConfigured: Bool {
        guard let url = URL(string: baseURLString), url.scheme == "https" || url.scheme == "http" else {
            return false
        }
        return !ingestToken.isEmpty
    }

    static var isAdminConfigured: Bool {
        guard let url = URL(string: baseURLString), url.scheme == "https" || url.scheme == "http" else {
            return false
        }
        return !adminToken.isEmpty
    }

    /// True when either ingest or admin can talk to the server.
    static var isConfigured: Bool {
        isIngestConfigured || isAdminConfigured
    }

    /// Percent-encode path segments so `/` in a student id cannot break URL paths.
    static func pathEncodedID(_ raw: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/?#")
        return raw.addingPercentEncoding(withAllowedCharacters: allowed) ?? raw
            .replacingOccurrences(of: "/", with: "%2F")
    }

    static func normalizedBaseURL(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while s.hasSuffix("/") {
            s.removeLast()
        }
        return s
    }

    private static func migrateLegacyTokenIfNeeded() {
        guard let legacy = UserDefaults.standard.string(forKey: legacyTokenKey),
              !legacy.isEmpty else { return }
        if KeychainStore.get(account: ingestAccount).isEmpty {
            KeychainStore.set(legacy, account: ingestAccount)
        }
        if KeychainStore.get(account: adminAccount).isEmpty {
            KeychainStore.set(legacy, account: adminAccount)
        }
        UserDefaults.standard.removeObject(forKey: legacyTokenKey)
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

    struct ClassDTO: Codable {
        let id: Int
        let name: String
        let invite_code: String
    }

    struct UpsertResultDTO: Codable {
        let id: Int?
        let external_id: String?
        let class_id: Int?
    }

    // MARK: - Queue

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
            guard !self.isFlushing, AnalyticsServerConfig.isIngestConfigured else { return }
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

    // MARK: - Student membership

    /// Register / update the student on the analytics server (ingest token).
    /// Failures are swallowed so offline play continues.
    func upsertStudent(
        externalID: String,
        displayName: String,
        classInviteCode: String?,
        completion: ((UpsertResultDTO?) -> Void)? = nil
    ) {
        guard AnalyticsServerConfig.isIngestConfigured,
              let url = endpointURL(path: "students/upsert") else {
            completion?(nil)
            return
        }
        var body: [String: Any] = [
            "external_id": externalID,
            "display_name": displayName
        ]
        let code = (classInviteCode ?? AnalyticsServerConfig.studentClassInviteCode)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !code.isEmpty {
            body["class_invite_code"] = code
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(AnalyticsServerConfig.ingestToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 20
        URLSession.shared.dataTask(with: req) { data, response, _ in
            let dto: UpsertResultDTO?
            if let data,
               let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                dto = try? JSONDecoder().decode(UpsertResultDTO.self, from: data)
            } else {
                dto = nil
            }
            DispatchQueue.main.async { completion?(dto) }
        }.resume()
    }

    /// Convenience: upsert the current local profile using the stored invite code.
    func upsertCurrentStudentIfPossible(completion: ((UpsertResultDTO?) -> Void)? = nil) {
        let profile = StudentProfile.shared
        let name = profile.studentName ?? profile.studentID
        upsertStudent(
            externalID: profile.studentID,
            displayName: name,
            classInviteCode: AnalyticsServerConfig.studentClassInviteCode,
            completion: completion
        )
    }

    // MARK: - Classes (admin)

    func createClass(name: String, inviteCode: String? = nil, completion: @escaping (ClassDTO?) -> Void) {
        guard AnalyticsServerConfig.isAdminConfigured,
              let url = endpointURL(path: "classes") else {
            completion(nil)
            return
        }
        var body: [String: Any] = ["name": name]
        if let inviteCode, !inviteCode.isEmpty {
            body["invite_code"] = inviteCode
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(AnalyticsServerConfig.adminToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 20
        URLSession.shared.dataTask(with: req) { data, response, _ in
            let dto: ClassDTO?
            if let data,
               let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                dto = try? JSONDecoder().decode(ClassDTO.self, from: data)
            } else {
                dto = nil
            }
            DispatchQueue.main.async { completion(dto) }
        }.resume()
    }

    func listClasses(completion: @escaping ([ClassDTO]) -> Void) {
        guard AnalyticsServerConfig.isAdminConfigured,
              let url = endpointURL(path: "classes") else {
            completion([])
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(AnalyticsServerConfig.adminToken)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 20
        URLSession.shared.dataTask(with: req) { data, response, _ in
            var result: [ClassDTO] = []
            if let data,
               let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                if let list = try? JSONDecoder().decode([ClassDTO].self, from: data) {
                    result = list
                } else if let wrapped = try? JSONDecoder().decode([String: [ClassDTO]].self, from: data),
                          let classes = wrapped["classes"] {
                    result = classes
                }
            }
            DispatchQueue.main.async { completion(result) }
        }.resume()
    }

    // MARK: - Analytics reads (admin)

    func fetchStudentMetrics(externalID: String, completion: @escaping (StudentMetricsDTO?) -> Void) {
        guard AnalyticsServerConfig.isAdminConfigured else {
            completion(nil)
            return
        }
        let encoded = AnalyticsServerConfig.pathEncodedID(externalID)
        guard let url = endpointURL(path: "analytics/students/\(encoded)") else {
            completion(nil)
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(AnalyticsServerConfig.adminToken)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 20
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
        guard AnalyticsServerConfig.isAdminConfigured,
              let url = endpointURL(path: "analytics/classes/\(classID)") else {
            completion(nil)
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(AnalyticsServerConfig.adminToken)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 20
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

    func fetchHealth(completion: @escaping (Bool) -> Void) {
        guard let url = endpointURL(path: "analytics/health")
                ?? endpointURL(path: "health") else {
            completion(false)
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 12
        URLSession.shared.dataTask(with: req) { _, response, _ in
            let ok = (response as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
            DispatchQueue.main.async { completion(ok) }
        }.resume()
    }

    // MARK: - Private

    private func postBatch(_ events: [OutboundAnswerEvent], completion: @escaping (Bool) -> Void) {
        guard AnalyticsServerConfig.isIngestConfigured,
              let url = endpointURL(path: "answers/batch") else {
            completion(false)
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(AnalyticsServerConfig.ingestToken)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 30

        struct BatchBody: Encodable {
            let events: [OutboundAnswerEvent]
            let class_invite_code: String?
        }
        let invite = AnalyticsServerConfig.studentClassInviteCode
        let body = BatchBody(
            events: events,
            class_invite_code: invite.isEmpty ? nil : invite
        )
        req.httpBody = try? JSONEncoder().encode(body)
        URLSession.shared.dataTask(with: req) { _, response, _ in
            let ok = (response as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
            completion(ok)
        }.resume()
    }

    /// Build `base/path` without letting `URL.appendingPathComponent` re-encode intentional `%2F`.
    private func endpointURL(path: String) -> URL? {
        let base = AnalyticsServerConfig.normalizedBaseURL(AnalyticsServerConfig.baseURLString)
        let trimmedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: "\(base)/\(trimmedPath)")
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

    #if DEBUG
    func pendingEventCountForTesting() -> Int {
        loadPending().count
    }

    func clearPendingForTesting() {
        UserDefaults.standard.removeObject(forKey: queueKey)
    }
    #endif
}
