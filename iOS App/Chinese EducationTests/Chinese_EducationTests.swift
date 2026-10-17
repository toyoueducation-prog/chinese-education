//
//  Chinese_EducationTests.swift
//  Chinese EducationTests
//
//  Created by J Ko on 4/2/2025.
//

import XCTest
@testable import Chinese_Education

final class Chinese_EducationTests: XCTestCase {

    func testPIRLSClassifierRetrieving() {
        let passage = "文章說明春天很溫暖，花會開。"
        let q = "文章中提到，春天有什麼特徵？"
        let answer = "A. 溫暖且花會開"
        let (process, confidence) = PIRLSQuestionClassifier.classifyQuestionEnhanced(q, passageText: passage, answer: answer)
        XCTAssertEqual(process, .retrieving)
        XCTAssertGreaterThan(confidence, 0.2)
    }

    func testPIRLSClassifierEvaluatingLeansEvaluatingOrInterpreting() {
        let passage = "故事中的小華決定幫助同學。"
        let q = "你認為小華這樣做對嗎？為什麼？"
        let answer = "B. 對，因為能建立友誼"
        let (process, _) = PIRLSQuestionClassifier.classifyQuestionEnhanced(q, passageText: passage, answer: answer)
        XCTAssertTrue([.evaluating, .interpreting].contains(process), "Unexpected process: \(process)")
    }

    func testQuestionBankCoverageReport() {
        let report = QuestionBank.shared.buildCoverageReport()
        XCTAssertEqual(report.totalQuestions, 72)
        XCTAssertEqual(report.passageCount, 18)
        XCTAssertEqual(report.pirlsCounts.values.reduce(0, +), 72)
        for p in PIRLSProcess.allCases {
            XCTAssertGreaterThanOrEqual(report.pirlsCounts[p] ?? 0, 1, "Expected at least one question per PIRLS process: \(p)")
        }
        // Rough balance: each PIRLS process should remain well represented after expansion.
        for p in PIRLSProcess.allCases {
            XCTAssertGreaterThanOrEqual(report.pirlsCounts[p] ?? 0, 12, "Expected thicker coverage for \(p)")
        }
        XCTAssertGreaterThanOrEqual(report.readingPurposeCounts[.literary] ?? 0, 24)
        XCTAssertGreaterThanOrEqual(report.readingPurposeCounts[.informational] ?? 0, 24)
        for level in 1...6 {
            XCTAssertGreaterThanOrEqual(report.difficultyHistogram[level] ?? 0, 1, "Expected questions at difficulty \(level)")
        }
    }

    func testQuestionBankPassageKeysStayCoherent() {
        let keys = QuestionBank.shared.getAllPassageKeys()
        XCTAssertEqual(keys.count, 18)
        for i in 1...18 {
            let key = "passage\(i)"
            XCTAssertTrue(keys.contains(key), "Missing \(key)")
            let set = QuestionBank.shared.getPassageSet(for: key)
            XCTAssertNotNil(set)
            XCTAssertEqual(set?.questionKeys.count, 4)
            for qKey in set!.questionKeys {
                XCTAssertNotNil(QuestionBank.shared.getQuestion(forKey: qKey))
                XCTAssertEqual(QuestionBank.shared.getPassageForQuestion(qKey), set?.passage)
            }
        }
    }

    func testEvaluatingItemsPreferTextSupportedJudgments() {
        let evaluatingKeys = QuestionBank.shared.getAllQuestions()
            .filter { $0.pirlsProcess == .evaluating }
            .map { $0.key }
        XCTAssertGreaterThanOrEqual(evaluatingKeys.count, 12)
        for key in evaluatingKeys {
            guard let q = QuestionBank.shared.getQuestion(forKey: key) else {
                XCTFail("Missing question \(key)")
                continue
            }
            let stem = q.question
            let looksTextSupported =
                stem.contains("根據") ||
                stem.contains("文中") ||
                stem.contains("文章") ||
                stem.contains("故事") ||
                stem.contains("日記")
            XCTAssertTrue(looksTextSupported, "Evaluating item \(key) should cue text-supported judgment, got: \(stem)")
        }
    }

    func testVocabularyMasteryProgression() {
        var word = VocabularyWord(word: "測試")
        word.encounters = 5
        word.correctUses = 4
        word.updateMastery()
        XCTAssertGreaterThanOrEqual(word.masteryLevel, 3)
    }

    func testVocabularyGlossaryMakesWordsPracticeReady() {
        var empty = VocabularyWord(word: "派對")
        XCTAssertFalse(empty.isPracticeReady)
        empty.applyGlossaryIfNeeded()
        XCTAssertTrue(empty.isPracticeReady)
        XCTAssertFalse(empty.meaning.isEmpty)
        XCTAssertFalse(empty.pinyin.isEmpty)

        var rainDiary = VocabularyWord(word: "日記")
        rainDiary.applyGlossaryIfNeeded()
        XCTAssertTrue(rainDiary.isPracticeReady)

        var quake = VocabularyWord(word: "地震")
        quake.applyGlossaryIfNeeded()
        XCTAssertTrue(quake.isPracticeReady)

        let unknown = VocabularyWord(word: "𠀀未收錄詞")
        XCTAssertFalse(unknown.isPracticeReady)
    }

    /// Regression: duplicate dict keys fatalError when extractVocabulary first touches the glossary.
    func testVocabularyGlossaryEntriesLoadWithoutDuplicateKeyCrash() {
        let entries = VocabularyGlossary.entries
        XCTAssertGreaterThanOrEqual(entries.count, 150)
        for word in ["陽光", "冒險", "好奇", "探索", "地球"] {
            XCTAssertNotNil(entries[word], "Expected shared gloss for \(word)")
            XCTAssertFalse(entries[word]!.meaning.isEmpty)
        }
        // Same path ConversationScene hits after adaptive encounter selection.
        if let passage = QuestionBank.shared.getPassageSet(for: "passage1")?.passage {
            let extracted = VocabularyManager.shared.extractVocabulary(from: passage, maxWords: 15)
            XCTAssertFalse(extracted.isEmpty)
        }
    }

    func testPracticeVocabularyExcludesEmptyMeanings() {
        let manager = VocabularyManager.shared
        // Extraction may create empty-gloss bigrams; practice list must only include glossed words.
        if let passage = QuestionBank.shared.getPassageSet(for: "passage1")?.passage {
            _ = manager.extractVocabulary(from: passage, maxWords: 15)
        }
        let practice = manager.getPracticeVocabulary(limit: 20)
        XCTAssertFalse(practice.isEmpty)
        XCTAssertTrue(practice.allSatisfy { $0.isPracticeReady })
        XCTAssertTrue(practice.allSatisfy { !$0.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }

    func testHonestMasteryTrackingDistinguishesCorrectAndIncorrect() {
        let word = "花園"
        let before = VocabularyManager.shared.getVocabularyWord(word)
        let beforeEncounters = before?.encounters ?? 0
        let beforeCorrect = before?.correctUses ?? 0

        VocabularyManager.shared.trackWordEncounter(word, isCorrect: true)
        VocabularyManager.shared.trackWordEncounter(word, isCorrect: false)

        let after = VocabularyManager.shared.getVocabularyWord(word)
        XCTAssertEqual(after?.encounters, beforeEncounters + 2)
        XCTAssertEqual(after?.correctUses, beforeCorrect + 1)
    }

    func testQuestionBankPassageKeyLookup() {
        let p = QuestionBank.shared.getPassageForQuestion("q1") ?? ""
        XCTAssertEqual(QuestionBank.shared.passageKey(matchingPassageText: p), "passage1")
    }

    func testAdaptiveEncounterUsesLocalBankOffline() {
        let encounter = LearningPathManager.shared.selectNextEncounter(
            profile: StudentProfile.shared,
            completedPassageTexts: [],
            questionCount: 4
        )
        XCTAssertNotNil(encounter)
        XCTAssertFalse(encounter!.questions.isEmpty)
        XCTAssertEqual(QuestionBank.shared.getPassageSet(for: encounter!.passageKey)?.passage, encounter!.passageText)
        XCTAssertGreaterThanOrEqual(encounter!.targetDifficulty, 1)
        XCTAssertLessThanOrEqual(encounter!.targetDifficulty, 6)
    }

    func testAdaptiveSelectionBiasesTowardWeakInferring() {
        let profile = StudentProfile.shared
        let savedAssessment = profile.pirlsAssessment
        let savedLevel = profile.currentLevel
        defer {
            profile.pirlsAssessment = savedAssessment
            profile.currentLevel = savedLevel
            profile.saveProfile()
        }

        profile.currentLevel = 3
        for process in PIRLSProcess.allCases {
            var perf = PIRLSProcessPerformance(process: process)
            if process == .inferring {
                perf.totalQuestions = 8
                perf.correctAnswers = 1
                perf.masteryLevel = 0.2
            } else {
                perf.totalQuestions = 8
                perf.correctAnswers = 7
                perf.masteryLevel = 0.85
            }
            profile.pirlsAssessment.processPerformance[process] = perf
        }
        profile.pirlsAssessment.updateOverallScore()

        let weak = LearningPathManager.shared.getWeakProcesses(profile)
        XCTAssertTrue(weak.contains(.inferring))
        XCTAssertFalse(weak.contains(.retrieving))

        let needs = InterventionEngine.shared.identifyStrugglingAreas(profile)
        XCTAssertTrue(needs.contains { $0.type == .process && $0.target == PIRLSProcess.inferring.rawValue })

        let interventionPassages = Set(
            InterventionEngine.shared.getProcessInterventionStrategy(.inferring).passages
        )
        let encounter = LearningPathManager.shared.selectNextEncounter(
            profile: profile,
            completedPassageTexts: [],
            questionCount: 4
        )
        XCTAssertNotNil(encounter)
        XCTAssertTrue(encounter!.focusProcesses.contains(.inferring))
        XCTAssertTrue(
            interventionPassages.contains(encounter!.passageKey),
            "Expected inferring-focused passage among \(interventionPassages), got \(encounter!.passageKey). Reason: \(encounter!.selectionReason)"
        )
        XCTAssertTrue(encounter!.questions.contains { $0.pirlsProcess == .inferring })
    }

    func testAdaptiveSelectionSkipsCompletedPassages() {
        let profile = StudentProfile.shared
        let allSets = QuestionBank.shared.getAllPassageSets()
        XCTAssertGreaterThanOrEqual(allSets.count, 2)

        let completedTexts = allSets.dropLast().map { $0.passage }
        let remainingKey = allSets.last!.passageKey

        let encounter = LearningPathManager.shared.selectNextEncounter(
            profile: profile,
            completedPassageTexts: completedTexts,
            questionCount: 4
        )
        XCTAssertNotNil(encounter)
        XCTAssertEqual(encounter!.passageKey, remainingKey)
    }

    func testColdStartDoesNotFlagAllProcessesAsWeak() {
        let profile = StudentProfile.shared
        let saved = profile.pirlsAssessment
        defer {
            profile.pirlsAssessment = saved
            profile.saveProfile()
        }
        profile.pirlsAssessment = PIRLSAssessment(studentLevel: 1)
        XCTAssertTrue(LearningPathManager.shared.getWeakProcesses(profile).isEmpty)
        let processNeeds = InterventionEngine.shared.identifyStrugglingAreas(profile).filter { $0.type == .process }
        XCTAssertTrue(processNeeds.isEmpty)
    }

    // MARK: - Teacher analytics / AI insight engine

    private func makeAnswerRecord(
        studentID: String,
        name: String,
        passage: String,
        type: String,
        process: PIRLSProcess?,
        correct: Bool,
        time: TimeInterval,
        attempt: Int = 1,
        date: Date = Date()
    ) -> StudentAnswerLogRecord {
        StudentAnswerLogRecord(
            id: UUID().uuidString,
            studentID: studentID,
            studentName: name,
            date: date,
            passageKey: passage,
            questionKey: "q_\(UUID().uuidString.prefix(6))",
            questionType: type,
            questionPreview: "preview",
            studentAnswer: correct ? "A" : "B",
            correctAnswer: "A",
            isCorrect: correct,
            responseTimeSeconds: time,
            attemptNumber: attempt,
            pirlsProcessRaw: process?.rawValue,
            readingPurposeRaw: ReadingPurpose.literary.rawValue
        )
    }

    func testRuleBasedInsightEngineStudentAccuracyAndStreaks() {
        let engine = RuleBasedAnalyticsInsightEngine()
        engine.skillSampleFloor = 2
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var records: [StudentAnswerLogRecord] = []
        // Build a clear retrieving weakness and a streak of 3 at the end.
        for i in 0..<4 {
            records.append(makeAnswerRecord(
                studentID: "s1", name: "小明", passage: "passage1", type: "選擇題",
                process: .retrieving, correct: false, time: 20, date: base.addingTimeInterval(Double(i))
            ))
        }
        for i in 0..<4 {
            records.append(makeAnswerRecord(
                studentID: "s1", name: "小明", passage: "passage3", type: "選擇題",
                process: .inferring, correct: true, time: 8, date: base.addingTimeInterval(Double(10 + i))
            ))
        }
        // Break the run so the trailing streak is exactly 3.
        records.append(makeAnswerRecord(
            studentID: "s1", name: "小明", passage: "passage4", type: "選擇題",
            process: .evaluating, correct: false, time: 15, date: base.addingTimeInterval(19)
        ))
        records.append(makeAnswerRecord(
            studentID: "s1", name: "小明", passage: "passage5", type: "開放題",
            process: .interpreting, correct: true, time: 12, date: base.addingTimeInterval(20)
        ))
        records.append(makeAnswerRecord(
            studentID: "s1", name: "小明", passage: "passage5", type: "開放題",
            process: .interpreting, correct: true, time: 11, date: base.addingTimeInterval(21)
        ))
        records.append(makeAnswerRecord(
            studentID: "s1", name: "小明", passage: "passage5", type: "開放題",
            process: .interpreting, correct: true, time: 10, date: base.addingTimeInterval(22)
        ))

        let snap = engine.analyzeStudent(studentID: "s1", studentName: "小明", records: records)
        XCTAssertEqual(snap.totalAnswers, 12)
        XCTAssertEqual(snap.currentStreak, 3)
        XCTAssertGreaterThanOrEqual(snap.bestStreak, 3)
        XCTAssertTrue(snap.weakestSkills.contains("檢索理解"))
        XCTAssertGreaterThan(snap.accuracyBySkill["推論理解"] ?? 0, 0.7)
        XCTAssertFalse(snap.insights.isEmpty)
        XCTAssertTrue(snap.insights.contains { $0.kind == .weakness || $0.kind == .recommendation })
    }

    func testRuleBasedInsightEngineFlagsAtRiskAndClassView() {
        let engine = RuleBasedAnalyticsInsightEngine()
        engine.atRiskAccuracyThreshold = 0.45
        engine.atRiskMinimumAnswers = 6
        engine.skillSampleFloor = 2

        var records: [StudentAnswerLogRecord] = []
        for i in 0..<8 {
            records.append(makeAnswerRecord(
                studentID: "risk", name: "阿華", passage: "passage2", type: "選擇題",
                process: .evaluating, correct: i < 2, time: 30, date: Date().addingTimeInterval(Double(i))
            ))
        }
        for i in 0..<6 {
            records.append(makeAnswerRecord(
                studentID: "ok", name: "小美", passage: "passage4", type: "選擇題",
                process: .retrieving, correct: true, time: 9, date: Date().addingTimeInterval(Double(20 + i))
            ))
        }

        let classSnap = engine.analyzeClass(
            roster: [(id: "risk", name: "阿華"), (id: "ok", name: "小美")],
            records: records
        )
        XCTAssertEqual(classSnap.studentCount, 2)
        XCTAssertEqual(classSnap.totalAnswers, 14)
        XCTAssertTrue(classSnap.atRiskStudentIDs.contains("risk"))
        XCTAssertFalse(classSnap.atRiskStudentIDs.contains("ok"))
        XCTAssertTrue(classSnap.insights.contains { $0.kind == .atRisk })
    }

    func testAnswerHistoryRecordAttemptDefaultsForLegacyPayload() throws {
        // Simulate a pre-attemptNumber log entry (field absent).
        let json = """
        {"id":"r1","studentID":"s9","date":725000000.0,"passageKey":"passage1","questionKey":"q1","questionType":"選擇題","questionPreview":"Q","studentAnswer":"A","correctAnswer":"A","isCorrect":true,"responseTimeSeconds":5.0}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(StudentAnswerLogRecord.self, from: json)
        XCTAssertEqual(decoded.attemptNumber, 1)
        XCTAssertEqual(decoded.studentID, "s9")
    }

    func testAnalyticsInsightEngineFacadeUsesProvider() {
        let engine = RuleBasedAnalyticsInsightEngine()
        let previous = AnalyticsInsightEngine.provider
        AnalyticsInsightEngine.provider = engine
        defer { AnalyticsInsightEngine.provider = previous }

        let prior = AnswerHistoryStore.shared.allRecords()
        defer { AnswerHistoryStore.shared.replaceAllForTesting(prior) }

        let sample = [
            makeAnswerRecord(
                studentID: "facade", name: "測試", passage: "passage1", type: "選擇題",
                process: .retrieving, correct: true, time: 7, attempt: 2
            ),
            makeAnswerRecord(
                studentID: "facade", name: "測試", passage: "passage1", type: "選擇題",
                process: .retrieving, correct: false, time: 12, attempt: 1
            )
        ]
        AnswerHistoryStore.shared.replaceAllForTesting(sample)
        let snap = AnalyticsInsightEngine.studentSnapshot(studentID: "facade", studentName: "測試")
        XCTAssertEqual(snap.totalAnswers, 2)
        XCTAssertEqual(snap.studentName, "測試")
    }
}
