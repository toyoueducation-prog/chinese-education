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
}
